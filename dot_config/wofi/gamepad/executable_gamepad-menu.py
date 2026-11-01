#!/usr/bin/env python3
"""Gamepad front end for control-menu.sh, so the desktop is usable from the couch.

  Back + Start (together)   open / close the control menu (from anywhere, even in a game)
  while a wofi menu is open:
    D-pad / left stick      arrow keys (held = repeat)
    A                       Enter
    B                       Esc (back / close)
    LB / RB                 previous / next workspace

Hyprland can't bind gamepad buttons (libinput ignores joysticks), so this reads every
gamepad's /dev/input/eventN directly and types into wofi through a virtual keyboard it
creates with /dev/uinput. It never grabs the pads: games and Steam still see every
press. Outside the menu only the Back+Start chord does anything.

Plain stdlib on purpose (no python-evdev): an input event is a fixed 24-byte struct and
uinput is three ioctls, see the constants below. Started from autostart.lua.
"""
import fcntl
import os
import select
import struct
import subprocess
import time

MENU = os.path.expanduser("~/.config/wofi/control-menu/control-menu.sh")

# struct input_event on 64-bit Linux: struct timeval (two longs), u16 type, u16 code, s32 value
EVENT = struct.Struct("llHHi")
EV_SYN, EV_KEY, EV_ABS = 0, 1, 3

# Gamepad codes (linux/input-event-codes.h)
BTN_A, BTN_B = 304, 305  # BTN_SOUTH, BTN_EAST
BTN_TL, BTN_TR = 310, 311
BTN_SELECT, BTN_START = 314, 315
BTN_DPAD = {544: "up", 545: "down", 546: "left", 547: "right"}  # pads that report the D-pad as buttons
ABS_X, ABS_Y, ABS_HAT0X, ABS_HAT0Y = 0, 1, 16, 17

# Keyboard codes the virtual keyboard can send
KEY = {"esc": 1, "enter": 28, "up": 103, "left": 105, "right": 106, "down": 108}

# ioctl numbers: _IOW(type, nr, size) = 1<<30 | size<<16 | type<<8 | nr, _IOR uses 2<<30
UI_SET_EVBIT = 0x40045564  # _IOW('U', 100, int)
UI_SET_KEYBIT = 0x40045565  # _IOW('U', 101, int)
UI_DEV_SETUP = 0x405C5503  # _IOW('U', 3, struct uinput_setup) — 92 bytes
UI_DEV_CREATE = 0x5501  # _IO('U', 1)


def eviocgabs(axis):  # _IOR('E', 0x40 + axis, struct input_absinfo) — six s32 = 24 bytes
	return 0x80184540 + axis


REPEAT_DELAY, REPEAT_RATE = 0.40, 0.12  # seconds: first repeat, then every
STICK_ON, STICK_OFF = 0.6, 0.4  # fraction of full tilt; the gap stops flicker at the edge
RESCAN = 2.0  # seconds between looks for newly plugged pads


class Keyboard:
	"""A virtual keyboard: Hyprland sees it as one more keyboard."""

	def __init__(self):
		self.fd = os.open("/dev/uinput", os.O_WRONLY | os.O_NONBLOCK)
		fcntl.ioctl(self.fd, UI_SET_EVBIT, EV_KEY)
		for code in KEY.values():
			fcntl.ioctl(self.fd, UI_SET_KEYBIT, code)
		# struct uinput_setup: input_id (bustype, vendor, product, version: 4 x u16), name[80], u32 ff_effects_max
		setup = struct.pack("HHHH80sI", 0x06, 0x1234, 0x5678, 1, b"gamepad-menu keyboard", 0)  # 0x06 = BUS_VIRTUAL
		fcntl.ioctl(self.fd, UI_DEV_SETUP, setup)
		fcntl.ioctl(self.fd, UI_DEV_CREATE)

	def tap(self, name):
		code = KEY[name]
		for value in (1, 0):  # press, release; each followed by a SYN "this moment is complete"
			os.write(self.fd, EVENT.pack(0, 0, EV_KEY, code, value) + EVENT.pack(0, 0, EV_SYN, 0, 0))


def has_button(event, code):
	"""Does the device report key/button `code`? The kernel lists supported keys as a
	bitmap in hex words (highest word first) in /sys/class/input/eventN/device/capabilities/key."""
	try:
		words = open(f"/sys/class/input/{event}/device/capabilities/key").read().split()
	except OSError:
		return False
	bitmap = int("".join(w.zfill(16) for w in words), 16)
	return bool(bitmap >> code & 1)


def find_pads():
	"""eventN of every gamepad: a jsN handler in /proc/bus/input/devices AND an A button.
	The A-button check drops mice and tablets (keyd's virtual pointer, Sunshine's
	"Mouse passthrough"), which also get a js handler because they report absolute axes."""
	pads = {}
	for block in open("/proc/bus/input/devices").read().split("\n\n"):
		name = handlers = ""
		for line in block.splitlines():
			if line.startswith("N: Name="):
				name = line[8:].strip('"')
			elif line.startswith("H: Handlers="):
				handlers = line[12:].split()
		if any(h.startswith("js") for h in handlers):
			for h in handlers:
				if h.startswith("event") and has_button(h, BTN_A):
					pads["/dev/input/" + h] = name
	return pads


class Pad:
	def __init__(self, path, name):
		self.path, self.name = path, name
		self.fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK)
		self.held = set()  # buttons currently down
		self.stick = {"x": None, "y": None}  # direction the left stick is pushed, per axis
		self.range = {}  # axis -> (min, max), to turn raw values into -1..1
		for axis in (ABS_X, ABS_Y):
			try:
				_, lo, hi, *_ = struct.unpack("6i", fcntl.ioctl(self.fd, eviocgabs(axis), bytes(24)))
				self.range[axis] = (lo, hi)
			except OSError:
				pass

	def tilt(self, axis, value):
		lo, hi = self.range.get(axis, (-32768, 32767))
		return (2 * (value - lo) / (hi - lo)) - 1


def menu_open():
	"""True while any wofi runs; the only time buttons become keys."""
	for pid in os.listdir("/proc"):
		if pid.isdigit():
			try:
				if open(f"/proc/{pid}/comm").read().strip() == "wofi":
					return True
			except OSError:
				pass
	return False


def hypr(lua):
	subprocess.run(["hyprctl", "dispatch", lua], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def main():
	kbd = Keyboard()
	pads = {}  # fd -> Pad
	repeat = None  # [direction, next time] while a D-pad direction / stick is held in the menu
	last_scan = 0

	while True:
		now = time.monotonic()
		if now - last_scan > RESCAN:
			last_scan = now
			known = {p.path for p in pads.values()}
			for path, name in find_pads().items():
				if path not in known:
					try:
						pad = Pad(path, name)
						pads[pad.fd] = pad
						print(f"pad added: {name} ({path})", flush=True)
					except OSError as e:
						print(f"can't open {path}: {e}", flush=True)

		timeout = RESCAN
		if repeat:
			timeout = max(0, min(timeout, repeat[1] - now))
		ready, _, _ = select.select(list(pads), [], [], timeout)

		if repeat and time.monotonic() >= repeat[1]:
			if menu_open():
				kbd.tap(repeat[0])
				repeat[1] = time.monotonic() + REPEAT_RATE
			else:
				repeat = None

		for fd in ready:
			pad = pads[fd]
			try:
				data = os.read(fd, EVENT.size * 64)
			except OSError:  # unplugged
				print(f"pad removed: {pad.name}", flush=True)
				os.close(fd)
				del pads[fd]
				continue

			for i in range(0, len(data), EVENT.size):
				_, _, etype, code, value = EVENT.unpack_from(data, i)
				press = direction = None  # what this event means, if anything

				if etype == EV_KEY:
					if value == 1:
						pad.held.add(code)
						if code in (BTN_SELECT, BTN_START) and {BTN_SELECT, BTN_START} <= pad.held:
							subprocess.Popen([MENU], start_new_session=True)
							continue
						press = code
					elif value == 0:
						pad.held.discard(code)
						if code in BTN_DPAD:
							direction = ("stop", BTN_DPAD[code])

				elif etype == EV_ABS and code in (ABS_HAT0X, ABS_HAT0Y):
					# D-pad as a hat: -1 / 0 / 1 on each axis
					names = ("left", "right") if code == ABS_HAT0X else ("up", "down")
					direction = (names[0],) if value < 0 else (names[1],) if value > 0 else ("stop", *names)

				elif etype == EV_ABS and code in (ABS_X, ABS_Y):
					t = pad.tilt(code, value)
					names = ("left", "right") if code == ABS_X else ("up", "down")
					axis = "x" if code == ABS_X else "y"
					now_dir = names[0] if t < -STICK_ON else names[1] if t > STICK_ON else None
					if now_dir is None and abs(t) > STICK_OFF:
						now_dir = pad.stick[axis]  # in the dead band between on/off: keep what it was
					if now_dir != pad.stick[axis]:
						pad.stick[axis] = now_dir
						direction = (now_dir,) if now_dir else ("stop", *names)

				if press in BTN_DPAD:
					direction = (BTN_DPAD[press],)
					press = None

				if direction is None and press is None:
					continue
				if not menu_open():
					repeat = None
					continue

				if direction:
					if direction[0] == "stop":
						if repeat and repeat[0] in direction[1:]:
							repeat = None
					else:
						kbd.tap(direction[0])
						repeat = [direction[0], time.monotonic() + REPEAT_DELAY]
				elif press == BTN_A:
					kbd.tap("enter")
				elif press == BTN_B:
					kbd.tap("esc")
				elif press == BTN_TL:
					hypr('hl.dsp.focus({ workspace = "e-1" })')
				elif press == BTN_TR:
					hypr('hl.dsp.focus({ workspace = "e+1" })')


if __name__ == "__main__":
	main()
