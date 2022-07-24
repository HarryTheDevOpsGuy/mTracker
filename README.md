# mTracker Version
 **Version**        : v0.1.9 <br>
 **Release Date**   : 25-Jul-22 <br>

#### What is mTracker ?
mTracker is small script to track user Activities on linux system. We can monitor all user what commands they are executing on linux system.

#### How To Install/Setup mTrack Script on ubuntu.
We can install this script script on any of debian system.

##### Step 1: Install Script.
```bash
# Download mtracker
curl -sL https://github.com/HarryTheDevOpsGuy/mTracker/raw/master/x86_64/mtracker -o /usr/bin/mtracker
chmod +x /usr/bin/mtracker
mtracker -v

# To Monitor User activity run below command
curl -sL https://raw.githubusercontent.com/HarryTheDevOpsGuy/mTracker/master/mtracker.sh -o /etc/profile.d/mTracker.sh

# To send notification using slack token and slack channel.
mtracker -c '#mcloud-alerts' -t 'xoxb-slack_token'
```

    Note : you can also export Following variables.
    export SLACK_CHANNEL="#devops"
    export SLACK_CLI_TOKEN="xoxb-your-slack-token}"
    export HISTTIMEFORMAT="%F %T - "


##### Step 2: Update SLACK_CLI_TOKEN and SLACK_CHANNEL To get notification on Slack Channel Group.

Edit `/etc/profile.d/mTracker.sh` file and update SLACK_CLI_TOKEN and SLACK_CHANNEL variable.

```bash
#sudo vim /etc/profile.d/mTracker.sh
export SLACK_CLI_TOKEN='xoxb-xxxxxxxxxxx-xxxxxxxxx-xxxxxxxxxxxxxxxxx'
export SLACK_CHANNEL="#devops"
export HISTTIMEFORMAT="%F %T - "
mtracker
```
Create Slack Bot for your Applications : https://slack.com/intl/en-in/help/articles/115005265703-Create-a-bot-for-your-workspace


##### Sample alert notification on slack channel
![Alt text](https://github.com/HarryTheDevOpsGuy/mTracker/raw/master/src/Alert-sample.png)
