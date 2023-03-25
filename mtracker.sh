#!/usr/bin/env bash
# /etc/profile.d/mTracker.sh
# export SLACK_CLI_TOKEN='xoxb-xxxxxxxxxxx-xxxxxxxxx-xxxxxxxxxxxxxxxxx'
# export SLACK_CHANNEL="#devops"

export SSH_SESSION_ID="MT-${RANDOM}"
export PROMPT_COMMAND='RETRN_VAL=$?;logger -p local6.debug "$(whoami) [${SSH_SESSION_ID}]: $(history 1 | sed "s/^[ ]*[0-9]\+[ ]*//" ) [$RETRN_VAL]"'

MTRACKER_BIN="$(command -v mtracker)"
if [[ ! -z ${MTRACKER_BIN} ]]; then
  ${MTRACKER_BIN} -m auth
  trap "${MTRACKER_BIN} -m history" 0
fi
