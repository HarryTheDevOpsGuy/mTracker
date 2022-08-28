# In the original repository we'll just print the result of status checks,
# without committing. This avoids generating several commits that would make
# later upstream merges messy for anyone who forked us.

CODE_BASE_DIR="${PWD}/uptime"
log_dir="${CODE_BASE_DIR}/logs"
keepLogLines="${2:-200}"
REPEAT_ALERT="${REPEAT_ALERT:-180}"
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
        echo $(( (d1 - d2) / 2629746 ))
        ;;
      weeks )
        echo $(( (d1 - d2) / 604800 ))
        ;;
      days )
        echo $(( (d1 - d2) / 86400 ))
        ;;
      hours )
        echo $(( (d1 - d2) / 3600 ))
        ;;
      minutes )
        echo $(( (d1 - d2) / 60 ))
        ;;
    esac
}

certExpiry(){
  keyname="${1}"
  scheme="${2%%:*}"
  fqdn=$(echo "${2}" | awk -F[/:] '{print $4}')
  SSLDATA="/tmp/ssldata.log"
  ALERT_DAY=( 40 20 10 5 3 2 1 )
  check_ssl=$(grep -c "$(date +'%F'):${keyname}" /tmp/ssl.log)
if [[ ${check_ssl} -lt 1 ]]; then 
    if [[ ${scheme} == 'https' ]]; then
      curl --cert-status -v https://${fqdn} 2>&1 | awk 'BEGIN { cert=0 } /^\* Server certificate:/ { cert=1 } /^\*/ { if (cert) print }' > ${SSLDATA}
      EXP_DATE=$(grep "expire date:" ${SSLDATA}|awk -F': ' '{print $2}')
      CERT_ISSUER=$(grep "issuer:" ${SSLDATA}|awk -F': ' '{print $2}'|sed -e 's/=/=\`/g; s/;/\`;/g; s/$/\`/g;')
      CERT_CNAME=$(grep "subject:" ${SSLDATA}|awk -F': ' '{print $2}'|sed -e 's/=/=\`/g; s/;/\`;/g; s/$/\`/g;')
      CERT_ALTCNAME=$(grep "subjectAltName:" ${SSLDATA}|awk -F': ' '{print $2}'|sed -e 's/"/\`/g;')
      echo $(date +'%F'):${keyname} >> "/tmp/ssl.log" 
      echo "checking ssl for ${fqdn}"

      ##### Slack Notification for SSL Cert ######
      max_num=$(IFS=$'\n';echo "${ALERT_DAY[*]}" | sort -nr | head -n1)
      today="$(date -d 'now' +'%F %T')"
      remain_days=$(datediff "${EXP_DATE}" "${today}" "days")
      for day in ${ALERT_DAY[@]}; do
        if [[ ${remain_days} -le ${day} ]];then 
          check_alert=$(grep -c "${keyname}:${day}" ${log_dir}/sslcert.log)
          if [[ ${check_alert} -lt 1 ]]; then
            SLACK_TITLE=":large_orange_circle: Warning | SSL Cert is expiring in ${remain_days} days for ${fqdn}."
            SLACK_MSG="*Domain* : \`${keyname} -> ${fqdn}\` \n *Expiring in * : \`${remain_days} days\` \n *Expired on* : \`${EXP_DATE}\` \n *Cert Issuer* : ${CERT_ISSUER} \n *CNAME* : ${CERT_CNAME}  \n *AltName* : ${CERT_ALTCNAME}"
            mslack chat send --title "${SLACK_TITLE}" --text "${SLACK_MSG}" --channel "${SLACK_CHANNEL}" --color danger --filter '.ts + "\n" + .channel'
            echo ${today}, ${keyname}:${day} >> "${log_dir}/sslcert.log"        
            # By default we keep 200 last log entries.  Feel free to modify this to meet your needs.
            echo "$(tail -50 ${log_dir}/sslcert.log)" > "${log_dir}/sslcert.log"
            echo ${today} - ${keyname} - SSL expiring in ${remain_days} days 
          fi 
        fi 
      done

    fi
else 
 echo "Already checked for the $(date +'%F') for ${keyname}. will check tomorrow."
fi 
}


####  Slack Notification  ####







KEYSARRAY=()
URLSARRAY=()

urlsConfig="${CODE_BASE_DIR}/urls.cfg"
#echo "Reading $urlsConfig"
while read -r line
do
  #echo "  $line"
  IFS='=' read -ra TOKENS <<< "$line"
  KEYSARRAY+=(${TOKENS[0]})
  URLSARRAY+=(${TOKENS[1]})
done < "$urlsConfig"

echo "***********************"
echo "Starting health checks with ${#KEYSARRAY[@]} configs:"

mkdir -p ${log_dir}
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
    #dateTime=$(date +'%Y-%m-%d %H:%M')
    dateTime=$(date +'%F %T')
    if [[ $commit == true ]]
    then
        touch ${log_dir}/${key}_report.log ${log_dir}/sslcert.log /tmp/ssl.log
        olddate=$(tail -1 ${log_dir}/${key}_report.log |cut -d ',' -f1|sed 's/^\s*//')
        lastResult=$(tail -1 ${log_dir}/${key}_report.log |cut -d ',' -f2|sed 's/^\s*//')

        ################# Slack Notification Rules.##############
        minDiff=$(datediff "${dateTime}" "${olddate}" "minutes")
        #echo "${key} -> ${result} -> ${response} | Update condition: ${minDiff} -gt ${REPEAT_ALERT} ||:${lastResult} -ne ${result}:"

        if [[ ${minDiff} -ge ${REPEAT_ALERT} || ${lastResult} -ne ${result} ]]; then
            if [[ ! -z ${result} && ! -z ${lastResult} ]]; then
                if [[ ("${result}" == "failed" && "${lastResult}" == "${result}") && (${minDiff} -ge ${REPEAT_ALERT}) ]]; then
                    SLACK_TITLE=":red_circle: Critical | ${url} is Still not accessible for ${minDiff} minutes"
                    SLACK_MSG="*URL* : \`${key} -> ${url}\` \n *Status* : \`${url} is not accessible\` \n *Response Time* : \`${respontime} Seconds\` \n *Alert Severity* : \`Critical\` \n *Status Code* : \`${response}\`  \n *Down at* : \`${olddate}\`. \n *Down since* :  \`${minDiff}\` minutes."
                    COLOR='danger'
                    #echo "CHECK ::: ${result} == failed and ${lastResult} == ${result} and ${minDiff} ge ${REPEAT_ALERT}"
                    echo "RepeatAlert: ${dateTime} - ${key}->${lastResult}->${result}->${response}->${respontime} Seconds  -  [${minDiff} min > ${REPEAT_ALERT} min]"
                    mslack chat send --title "${SLACK_TITLE}" --text "${SLACK_MSG}" --channel "${SLACK_CHANNEL}" --color ${COLOR} --filter '.ts + "\n" + .channel' #> /dev/null 2>&1
                elif [[ ${result} -eq 'failed' && ${lastResult} != ${result} ]]; then
                    SLACK_TITLE=":red_circle: Critical | ${url} is not accessible - ${response}"
                    SLACK_MSG="*URL* : \`${key} -> ${url}\` \n *Status* : \`${url} is not accessible\` \n *Response Time* : \`${respontime} Seconds\` \n *Alert Severity* : \`Critical\` \n *Status Code* : \`${response}\`  \n *Down at* : \`${dateTime}\`."
                    COLOR='danger'
                    echo "alert : ${dateTime} - ${key}->${lastResult}->${result}->${response}->${respontime} Seconds"
                    mslack chat send --title "${SLACK_TITLE}" --text "${SLACK_MSG}" --channel "${SLACK_CHANNEL}" --color ${COLOR} --filter '.ts + "\n" + .channel' #> /dev/null 2>&1
                elif [[ ${result} == 'success' && ${lastResult} != ${result} ]]; then
                    echo "${result} -eq 'success' and ${lastResult} -ne 'success'"
                    SLACK_TITLE=":large_green_circle: Resolved | ${url} is working now - ${response} | ${respontime} Seconds"
                    SLACK_MSG="*URL* : \`${key} -> ${url}\` \n *Status* : \`${url} is up and running\` \n *Response Time* : \`${respontime} Seconds\` \n *Alert Severity* : \`Critical\` \n *Status Code* : \`${response}\`  \n *Down at* : \`${dateTime}\`. \n *Total Downtime* :  \`${minDiff}\` minutes."
                    COLOR='good'
                    echo "ResolvedAlert : ${dateTime} - ${key}->${lastResult}->${result}->${response}->${respontime} Seconds"
                    mslack chat send --title "${SLACK_TITLE}" --text "${SLACK_MSG}" --channel "${SLACK_CHANNEL}" --color ${COLOR} --filter '.ts + "\n" + .channel' #> /dev/null 2>&1

                elif [[ ${result} == 'success' && ${lastResult} == ${result} ]]; then
                    echo "OK : ${dateTime} - ${key}->${lastResult}->${result}->${response}->${respontime} Seconds"
                else 
                    echo "SomeThingIsNotHandled : ${dateTime} - ${key}->${lastResult}->${result}->${response} - [${minDiff}:${REPEAT_ALERT}]"
                fi

              else 
              echo "VariableEmpty: ${dateTime} - ${key}->${lastResult:-lastResultEmpty}->${result:-resultEmpty}->${response}->${respontime} Seconds - [${minDiff}:${REPEAT_ALERT}]"
            fi 
              echo $dateTime, $result >> "${log_dir}/${key}_report.log"        
              # By default we keep 200 last log entries.  Feel free to modify this to meet your needs.
              echo "$(tail -${keepLogLines} ${log_dir}/${key}_report.log)" > "${log_dir}/${key}_report.log"

        elif [[ ${lastResult} == ${result} && ${result} == 'failed' ]];then  
          echo "Next alert in $(( REPEAT_ALERT - minDiff )) minutes: ${dateTime} - ${key}->${lastResult}->${result}->${response}->${respontime} Seconds - [${minDiff}:${REPEAT_ALERT}]"
        fi

        ################# Slack Notification Rules.##############

    else
      echo "    $dateTime, $result"
    fi

    # check certExpiry
    certExpiry "${key}" "${url}"

  done

  if [[ $commit == true ]]
  then
    # Let's make mCloudAutomation the most productive person on GitHub.
    git pull
    git config --global user.name 'mCloud-Platform'
    git config --global user.email 'mCloudAutomation@gmail.com'
    git add -A --force uptime/logs/.
    git commit -am '[Automated] Update Health Check Logs'
    git push
  fi
