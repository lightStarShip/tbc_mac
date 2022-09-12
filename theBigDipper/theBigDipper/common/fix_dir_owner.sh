#!/bin/sh

#  fix_dir_owner.sh


LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
sudo chown $@ "$HOME/Library/LaunchAgents"

