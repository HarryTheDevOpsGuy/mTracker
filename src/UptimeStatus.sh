# In the original repository we'll just print the result of status checks,
# without committing. This avoids generating several commits that would make
# later upstream merges messy for anyone who forked us.

CODE_BASE_DIR="${CODE_BASE_DIR:-$PWD}"
log_dir="${CODE_BASE_DIR}/logs"
keepLogLines="${2:-1000}"
commit=true
# origin=$(git remote get-url origin)
# if [[ $origin == *statsig-io/statuspage* ]]
# then
#   commit=false
# fi

KEYSARRAY=()
URLSARRAY=()

urlsConfig="${CODE_BASE_DIR}/urls.cfg"
echo "Reading $urlsConfig"
while read -r line
do
  echo "  $line"
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
    echo "  $key=$url"

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
      lastResult=$(tail -1 ${log_dir}/${key}_report.log |cut -d ',' -f2|sed 's/^\s*//')
      if [[ ${lastResult} != ${result} ]]; then
        echo $dateTime, $result, $url, $response, ${respontime} >> "${log_dir}/${key}_report.log"
        # By default we keep 2000 last log entries.  Feel free to modify this to meet your needs.
        echo "$(tail -${keepLogLines} ${log_dir}/${key}_report.log)" > "${log_dir}/${key}_report.log"
      fi
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
