#!/bin/bash
#
#RC_DIR=$(dirname "$0")"/"
. $SRC_DIR"drive_config.sh"

echo "CLIENT_ID=$CLIENT_ID"
echo "SCOPE=$SCOPE"
echo "AUTH_CODE=$AUTH_CODE"
echo "CLIENT_SECRET=$CLIENT_SECRET"
echo "REFRESH_TOKEN=$REFRESH_TOKEN"
echo "UPLOAD_FILE=$UPLOAD_FILE"
echo "MIMETYPE=$MIMETYPE"
echo "DRIVE_FOLDER_ID=$DRIVE_FOLDER_ID"
echo "AUTH_REQ_URL=$AUTH_REQ_URL"
echo "REFRESH_REQ_DATA=$REFRESH_REQ_DATA"
echo "TOKEN_REQ_API_URL=$TOKEN_REQ_API_URL"

if [[ $AUTH_CODE = "" ]]
then
    printf '%*s\n' "$(tput cols)" '' | tr ' ' =\n
    echo "There is no AUTH_CODE, Please go to this link and get the AUTH_CODE."
    echo $AUTH_REQ_URL
    echo "Please enter the AUTH_CODE or ctrl-C to cancel ........."
    read AUTH_CODE
    REFRESH_REQ_DATA="code=$AUTH_CODE&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&grant_type=authorization_code&redirect_uri=http://localhost"
    echo "curl --request POST -s --data \"$REFRESH_REQ_DATA\" $TOKEN_REQ_API_URL"
    REFRESH_TOKEN=$(curl --request POST -s --data "$REFRESH_REQ_DATA" $TOKEN_REQ_API_URL | grep -zoP '"refresh_token":\s*\K[^\s,]*(?=\s*,)')
    #echo $REFRESH_TOKEN
    printf '%*s\n' "$(tput cols)" '' | tr ' ' =\n
    sed -i -e "s%^\(AUTH_CODE=\).*%\1\"$AUTH_CODE\"%" -e "s%^\(REFRESH_TOKEN=\).*%\1\"$REFRESH_TOKEN\"%" drive_config.sh    echo !! AUTH_CODE and REFRESH_TOKEN SAVED !!
    . $SRC_DIR"drive_config.sh"
fi
echo "Refresh token found in the config file."
echo $REFRESH_TOKEN
