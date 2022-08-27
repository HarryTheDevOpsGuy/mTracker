# In the original repository we'll just print the result of status checks,
# without committing. This avoids generating several commits that would make
# later upstream merges messy for anyone who forked us.

CODE_BASE_DIR="${PWD}/uptime"
log_dir="${CODE_BASE_DIR}/logs"
keepLogLines="${2:-200}"
commit=true
# origin=$(git remote get-url origin)
# if [[ $origin == *statsig-io/statuspage* ]]
# then
#   commit=false
# fi

####  Slack Notification  ####
datediff() {
  #datediff "$(date -d 'now + 70 minutes' +'%F %T')" "$(date -d 'now' +'%F %T')" "minutes"
    d1=$(date -d "$1" +%s)
    d2=$(date -d "$2" +%s)

    case $3 in
      months )
        echo $(( (d1 - d2) / 2629746 )) months
        ;;
      weeks )
        echo $(( (d1 - d2) / 604800 )) weeeks
        ;;
      days )
        echo $(( (d1 - d2) / 86400 )) days
        ;;
      hours )
        echo $(( (d1 - d2) / 3600 )) hours
        ;;
      minutes )
        # echo $(( (d1 - d2) / 60 )) minutes
        echo $(( (d1 - d2) / 60 ))
        ;;
    esac
}


####  Slack Notification  ####







KEYSARRAY=()
URLSARRAY=()

urlsConfig="${CODE_BASE_DIR}/urls.cfg"
echo "Reading $urlsConfig"
while read -r line
do
  #echo "  $line"
  IFS='=' read -ra TOKENS <<< "$line"
  KEYSARRAY+=(${TOKENS[0]})
  URLSARRAY+=(${TOKENS[1]})
done < "$urlsConfig"

echo "***********************"
echo "Starting health checks with ${#KEYSARRAY[@]} configs:"

mkdir -p logs
  for (( index=0; index < ${#KEYSARRAY[@]}; index++))
  do
    key="${KEYSARRAY[index]}"
    url="${URLSARRAY[index]}"
    #echo "  $key=$url"

    for i in 1 2 3 4;
    do
      data=$(curl --connect-timeout 5 -sw '%{http_code}:%{time_total}' -o /dev/null $url)
      response=${data%%:*}
      respontime=$(printf "%.3f" ${data##*:})
      if [ "$response" -eq 200 ] || [ "$response" -eq 202 ] || [ "$response" -eq 301 ] || [ "$response" -eq 302 ] || [ "$response" -eq 307 ]; then
        result="success"
      else
        result="failed"
      fi
      if [ "$result" = "success" ]; then
        break
      fi
      sleep 5
    done
    dateTime=$(date +'%Y-%m-%d %H:%M')
    if [[ $commit == true ]]
    then
        olddate=$(tail -1 ${log_dir}/${key}_report.log |cut -d ',' -f1|sed 's/^\s*//')
        lastResult=$(tail -1 ${log_dir}/${key}_report.log |cut -d ',' -f2|sed 's/^\s*//')
        echo "${key} -> ${result} -> ${response}"
        if [[ ${lastResult} != ${result} ]]; then
            echo $dateTime, $result >> "${log_dir}/${key}_report.log"
            # By default we keep 200 last log entries.  Feel free to modify this to meet your needs.
            echo "$(tail -${keepLogLines} ${log_dir}/${key}_report.log)" > "${log_dir}/${key}_report.log"
        fi
        

        ################# Slack Notification Rules.##############
        minDiff=$(datediff "${dateTime}" "${olddate}" "minutes")
        if [[ ${minDiff} > ${REPEAT_ALERT} || ${lastResult} != ${result} ]]; then
            if [[ ${lastResult} == 'failed' && ${minDiff} > ${REPEAT_ALERT:-180} ]]; then
                SLACK_TITLE="Critical | ${url} is Still Unreachable for ${minDiff} minutes"
                SLACK_MSG="*URL* : \`${url}\` \n *Status* : \`${url} is unreachable\` \n *Response Time* : \`${respontime} Seconds\` \n *Alert Severity* : \`Critical\` \n *Status Code* : \`${response}\`  \n *Down at* : \`${olddate}\`. \n *Down since* :  \`${minDiff}\` minutes."
                COLOR='danger'
                echo mslack chat send --title "${SLACK_TITLE}" --text "${SLACK_MSG}" --channel "${SLACK_CHANNEL}" --color ${COLOR} #> /dev/null 2>&1
            elif [[ ${result} == 'failed' ]]; then
                SLACK_TITLE="Critical | ${url} is Unreachable - ${response}"
                SLACK_MSG="*URL* : \`${url}\` \n *Status* : \`${url} is unreachable\` \n *Response Time* : \`${respontime} Seconds\` \n *Alert Severity* : \`Critical\` \n *Status Code* : \`${response}\`  \n *Down at* : \`${dateTime}\`."
                COLOR='danger'
                echo mslack chat send --title "${SLACK_TITLE}" --text "${SLACK_MSG}" --channel "${SLACK_CHANNEL}" --color ${COLOR} #> /dev/null 2>&1
            elif [[ ${result} == 'success' ]]; then
                SLACK_TITLE="Resolved | ${url} is working now - ${response} | ${respontime} Seconds"
                SLACK_MSG="*URL* : \`${url}\` \n *Status* : \`${url} is up and running\` \n *Response Time* : \`${respontime} Seconds\` \n *Alert Severity* : \`Critical\` \n *Status Code* : \`${response}\`  \n *Down at* : \`${dateTime}\`. \n *Total Downtime* :  \`${minDiff}\` minutes."
                COLOR='good'
                echo mslack chat send --title "${SLACK_TITLE}" --text "${SLACK_MSG}" --channel "${SLACK_CHANNEL}" --color ${COLOR} #> /dev/null 2>&1
            else 
                echo "${url} - Up and running - ${response} | ${respontime} Seconds"
            fi
        fi
        echo "${lastResult}:${result}: ${SLACK_TITLE}"
        ################# Slack Notification Rules.##############

    else
      echo "    $dateTime, $result"
    fi


  done

  if [[ $commit == true ]]
  then
    # Let's make mCloudAutomation the most productive person on GitHub.
    git pull
    git config --global user.name 'mCloud-Platform'
    git config --global user.email 'mCloudAutomation@gmail.com'
    git add -A --force logs/
    git commit -am '[Automated] Update Health Check Logs'
    git push
  fi
