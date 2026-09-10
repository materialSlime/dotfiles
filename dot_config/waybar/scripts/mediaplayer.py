#!/usr/bin/python3 -u
from curses import meta
import gi
gi.require_version("Playerctl", "2.0")
from gi.repository import Playerctl, GLib
from gi.repository.Playerctl import Player
import argparse
import logging
import sys
import json
import os
from typing import List

logger = logging.getLogger(__name__)

class PlayerManager:
    def __init__(self, selected_player=None, excluded_player=[]):
        self.manager = Playerctl.PlayerManager()
        self.selected_player = selected_player
        self.excluded_player = excluded_player.split(',') if excluded_player else []

    def run(self):
        # Get all players
        players = []
        for name in self.manager.props.player_names:
            if name.name in self.excluded_player: continue
            if self.selected_player and self.selected_player != name.name: continue
            try:
                players.append(Playerctl.Player.new_from_name(name))
            except Exception: pass

        # Find the best player to show (Playing > Paused > First)
        target_player = None
        for p in players:
            if p.props.status == "Playing":
                target_player = p
                break
        if not target_player and players:
            target_player = players[0]

        if target_player:
            self.write_output(target_player)
        else:
            sys.stdout.write("\n")

    def write_output(self, player: Player):
        source = player.props.player_name
        metadata = player.props.metadata
        if hasattr(metadata, "unpack"):
            metadata = metadata.unpack()
        artist = player.get_artist()
        title = player.get_title()

        # add currosponding icon to source string
        if source == "spotify":
            source = " {Spotify}"
        elif source == "firefox":
            source = " {Firefox}"
        elif source == "mpv":
            source = "AV"
        elif source == "vlc":
            source = "LM "
        else:
            source = "󰈹 "

        # Determine text and icon
        text = {}
        if source == "spotify" and "mpris:trackid" in metadata.keys() and ":ad:" in metadata["mpris:trackid"]:
            text = {"title": "Advertisement", "artist": artist, "media_icon": ""}
        elif artist is not None and title is not None:
            text = {"title": title, "artist": artist, "media_icon": ""}
        elif artist is not None:
            text = {"title": artist}
        else:
            text = {"title": title}

        if player.props.status == "Playing":
            text['media_icon'] = ""
        else:
            text['media_icon'] = ""

        progress = "<progress-missing>"

        position = player.get_position()
        duration = metadata.get("mpris:length", 0)

        if duration > 0:
            percent = position / duration
            if percent > 1: percent = 1
            if percent < 0: percent = 0
            filled = int(percent * 20)
            bar = "█" * filled + "░" * (20 - filled)
            def fmt(us):
                s = round(us / 1000000)
                return f"{s // 60}:{s % 60:02d}"
            progress = f"{fmt(position)} {bar} {fmt(duration)}"


        try:
          pass
        except Exception:
            print(Exception)

        # Waybar does not support multi-line text in the bar. Using a separator instead.
        artist = text.get('artist', '')
        artist_formatted = f"{artist} - " if artist else ""

        output = {"text": f" {text.get('media_icon', '')} {artist_formatted} {text.get('title', '')}",
                  "tooltip": f"{source}\n{text.get('title', '')}\n{artist}\n{progress}",
                  "class": "custom-" + player.props.player_name,
                  "alt": player.props.player_name}

        sys.stdout.write(json.dumps(output) + "\n")
        sys.stdout.flush()

def parse_arguments():
    parser = argparse.ArgumentParser()

    # Increase verbosity with every occurrence of -v
    parser.add_argument("-v", "--verbose", action="count", default=0)

    parser.add_argument("-x", "--exclude", "- Comma-separated list of excluded player")

    # Define for which player we"re listening
    parser.add_argument("--player")

    parser.add_argument("--enable-logging", action="store_true")

    return parser.parse_args()


def main():
    arguments = parse_arguments()

    # Initialize logging
    if arguments.enable_logging:
        logfile = os.path.join(os.path.dirname(
            os.path.realpath(__file__)), "media-player.log")
        logging.basicConfig(filename=logfile, level=logging.DEBUG,
                            format="%(asctime)s %(name)s %(levelname)s:%(lineno)d %(message)s")

    # Logging is set by default to WARN and higher.
    # With every occurrence of -v it's lowered by one
    logger.setLevel(max((3 - arguments.verbose) * 10, 0))

    logger.info("Creating player manager")
    if arguments.player:
        logger.info(f"Filtering for player: {arguments.player}")
    if arguments.exclude:
        logger.info(f"Exclude player {arguments.exclude}")

    player = PlayerManager(arguments.player, arguments.exclude)
    player.run()


if __name__ == "__main__":
    main()
