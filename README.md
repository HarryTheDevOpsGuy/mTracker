**Join Us**: [![Slack](https://img.shields.io/badge/Slack-4A154B?style=for-the-badge&logo=slack&logoColor=white)](https://harrythedevopsguy.slack.com)  [![Telegram](https://img.shields.io/badge/Telegram-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/TheDevOpsProfessionals)  [![WhatsApp](https://img.shields.io/badge/WhatsApp-25D366?style=for-the-badge&logo=whatsapp&logoColor=white)](https://chat.whatsapp.com/Go0FgwQs9GtKp6js2l6RTG)

# mTracker Version
 **Version**        : v0.5.0 <br>
 **Release Date**   : 25-Mar-23 <br>

#### What is mTracker ?
mTracker is small script to track user Activities on linux system. We can monitor all user what commands they are executing on linux system.

#### Features
it will send you Notification for following activity.
 - Track user command activity.
 - Track SSH login Activity
 - Realtime Monitor system CPU,Memory,Disk usage.
 - Get All Notification on your favourite slack channel.

#### Prerequisite
you need slack token to configure mTracker. so first follow below link to create your slack token.
##### [Click to Create slack bot | slack token ](https://slack.com/intl/en-in/help/articles/115005265703-Create-a-bot-for-your-workspace)


#### How To Install/Setup mTrack Script on ubuntu.
We can install this script on any of linux system.

### 1 ->  Install mTracker in Linux.
  ```bash
  # Download mtracker
  sudo curl -sL https://github.com/HarryTheDevOpsGuy/mTracker/raw/master/x86_64/mtracker -o /usr/bin/mtracker
  sudo chmod +x /usr/bin/mtracker && sudo mtracker && mtracker -v

  # To send notification using slack token and slack channel.
  mtracker -c '#mcloud-alerts' -t 'xoxb-slack_token'
  ```

if you want want to pass slack token runtime you can set/export below variables. 

```bash
export SLACK_CHANNEL="#devops"
export SLACK_CLI_TOKEN="xoxb-your-slack-token****"
mtracker
```


### 2 -> How to Track User activity?
it allow you to monitor user activity and notify you on slack channel.

2.1 - To get users command history logs on your slack channel. You need to uncomment below lines and update your slack token and channel in `/etc/profile.d/mTracker.sh` file.  

```bash
export SLACK_CLI_TOKEN='xoxb-your-slack-token'
export SLACK_CHANNEL="#devops"
```

2.2 - Now logout and login again to test. if you configured above configs properly. you will get alert as below.

    ![Alt text](https://github.com/HarryTheDevOpsGuy/mTracker/raw/master/src/Alert-sample.png)

2.3 - Done!! if any user will login and run any linux command it will notify you on slack channel.


### 3 -> How to monitor CPU,Memory and Disk usage?
We can monitor realtime disk,CPU and memory Utilization. it will notify you on slack channel only.
You need to create mwatcher config file and set cron accordingly.

1. Create config file
    vim /etc/watcher.sh
    ```bash
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
* **Connect with us** : Please join above WhatsApp group or Telegram channel
