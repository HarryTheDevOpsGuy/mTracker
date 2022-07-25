# mTracker Version
 **Version**        : v0.2.2 <br>
 **Release Date**   : 25-Jul-22 <br>

#### What is mTracker ?
mTracker is small script to track user Activities on linux system. We can monitor all user what commands they are executing on linux system.

#### Features
it will send you Notification for following activity.
 - Track user command activity.
 - Track SSH login Activity
 - Realtime Monitor system CPU,Memory,Disk usage.
 - Get All Notification on your favourite slack channel.

#### Prerequisite
you need to slack token to configure mTracker. so first follow below link to create your slack token.
##### [Click to Create slack bot | slack token ](https://slack.com/intl/en-in/help/articles/115005265703-Create-a-bot-for-your-workspace)


#### How To Install/Setup mTrack Script on ubuntu.
We can install this script on any of linux system.

### Install mTracker in Linux.
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

if you want want to pass slack token runtime you can set/export below variables

```bash
export SLACK_CHANNEL="#devops"
export SLACK_CLI_TOKEN="xoxb-your-slack-token}"
export HISTTIMEFORMAT="%F %T - "
mtracker
```


### How to Track User activity?
it allow you to monitor user activity and notify you on slack channel.

1. Create config file in `/etc/profile.d/mtracker.sh`
    ```
    #sudo vim /etc/profile.d/mtracker.sh
    export SLACK_CLI_TOKEN='xoxb-xxxxxxxxxxx-xxxxxxxxx-xxxxxxxxxxxxxxxxx'
    export SLACK_CHANNEL="#devops"
    export HISTTIMEFORMAT="%F %T - "
    mtracker
    ```
2. Now logout and login again to test. if you configured above configs properly. you will get alert as below.

    ![Alt text](https://github.com/HarryTheDevOpsGuy/mTracker/raw/master/src/Alert-sample.png)

3. Done!! if any user will login and run any linux command it will notify you on slack channel.


### How to configure to monitor CPU,Memory and Disk usage?
We can monitor realtime disk,CPU and memory Utilization. it will notify you on slack channel only.

1. Create config file
    vim /etc/watcher.sh
    ```
    export SLACK_CLI_TOKEN='xoxb-xxxxxxxxxxx-xxxxxxxxx-xxxxxxxxxxxxxxxxx'
    export SLACK_CHANNEL="#devops"
    export REPEAT_ALERTS=120  # 2 hours
    export DATAPOINT_COUNT=5  # 1 datapoint in 2 sec.

    MEMORY_ALARM+=( [WARNING]=10 [CRITICAL]=90 )
    CPU_ALARM+=( [WARNING]=5 [CRITICAL]=90 )
    DISK_ALARM+=( [WARNING]=15 [CRITICAL]=90 )

    ```

2. Configure crontab to run every 5 min internal.
    ```
    # crontab -e
    # run cron to check every 5 min.
    */5 * * * * mtracker -m mwatcher -f /etc/watcher.sh
    ```

3. Once configured properly. you will get alert as below.
    ![Alt text](https://github.com/HarryTheDevOpsGuy/mTracker/raw/master/src/CPU-Mem-Disk-Alert.png)


---
**Note :**  **If you like this tool Please support us and share this with your friends/others.**

#### About us
* **Utility Name** : [mTracker](https://github.com/HarryTheDevOpsGuy/mTracker)
* **Developed by** : [Harry](https://harrythedevopsguy.github.io)
* **Email** : HarryTheDevOpsGuy@gmail.com
