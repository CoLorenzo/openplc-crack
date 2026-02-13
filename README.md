# OpenPLC Brute Force Tool

This tool is a bash script designed to perform a dictionary attack (brute force and password spraying) against an OpenPLC web server's login page. It iterates through provided lists of usernames and passwords, handling CSRF tokens and session cookies to attempt authentication.

## Files

- **run.sh**: The main executable script.
- **usernames.txt**: A newline-separated list of usernames to test.
- **passwords.txt**: A newline-separated list of passwords to test.

## Prerequisites

Ensure you have the following tools installed on your system:
- `bash`
- `curl`
- `grep`
- `awk`

## Usage

1. modify passwords.txt and usernames.txt to your needs
2. run the script

```bash
./run.sh <dummy_username> <dummy_password> <target_url>
```

for example

```bash
./run.sh openplc openplc http://192.168.1.50:8080
```


## Disclaimer

This tool is for educational and authorized testing purposes only. Ensure you have permission to audit the target system.
