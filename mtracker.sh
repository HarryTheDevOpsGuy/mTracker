#!/usr/bin/env bash
# /etc/profile.d/mtracker.sh
# export SLACK_CLI_TOKEN='xoxb-xxxxxxxxxxx-xxxxxxxxx-xxxxxxxxxxxxxxxxx'
# export SLACK_CHANNEL="#devops"
export HISTTIMEFORMAT="%F %T - "

MTRACKER_BIN="$(command -v mtracker)"
if [[ ! -z ${MTRACKER_BIN} ]]; then
  mtracker
fi
