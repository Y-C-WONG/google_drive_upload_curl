#!/bin/bash

# This script upload file to google drive using google drive API
# Author: Yau Chuen Wobng in October, 2023
# -----------------------------------------
# For first time using google drive api, please get the authorization code, 
# then exchange refresh token with the authorization code by calling the google authorization api.
# The authorization code only need once in most of the time.
# The refresh token, once generated, it will be expired if not been used in six months of time.
# The refresh token uses for exchange the access token which generate by the google authorization api.
# Then access token need to be generated everytime before upload file.
# -----------------------------------------
# STEP 1: Get the authorization Code
# Visit below link  with web browser by provide the client id and scope, then Authorization will return in the URL link 
# https://accounts.google.com/o/oauth2/auth?client_id=[client_id]&redirect_uri=http://localhost&response_type=code&scope=[scope]&access_type=offline
# -----------------------------------------
# STEP 2: Get the refresh token
# run below command to exchange the refresh token with the authorization code, client id, and client secret
# curl --request POST --data "code=[AUTH_CODE]&client_id=[CLIENT_ID]&client_secret=[CLIENT_SECRET]v&redirect_uri=http://localhost&grant_type=authorization_code" https://oauth2.googleapis.com/token
# this api call will return a json response that contains the refresh token
# ------------------------------------------
# STEP 3: Get the access token
# Fill in below information and run the _getAccessToken()
CLIENT_ID=""
SCOPE=""
AUTH_CODE=""
CLIENT_SECRET=""
REFRESH_TOKEN=""
function _getAccessToken() 
{
    ACCESS_TOKEN=$(curl --request POST -s \
    --data "client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&refresh_token=$REFRESH_TOKEN&grant_type=refresh_token" \
    https://oauth2.googleapis.com/token | jq ."access_token")
    echo $ACCESS_TOKEN
}

UPLOAD_FILE=""
MIMETYPE="Application/zip"
DRIVE_FOLDER_ID=""

function _uploadToGoogleDrive()
{
    RESPONSE_JSON=$(curl -X POST -L -H "Authorization: Bearer $ACCESS_TOKEN" \
    -F "metadata={name : '$UPLOAD_FILE', parents : ['$DRIVE_FOLDER_ID']};type=application/json;charset=UTF-8" \
    -F "file=@$UPLOAD_FILE;type=$MIMETYPE" "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart")
}

_getAccessToken
_uploadToGoogleDrive

echo $RESPONSE_JSON
ERROR_CODE=$(jq '.error.code' <<< $RESPONSE_JSON)
echo $ERROR_CODE
DRIVE_FILE_NAME=$(jq '.name' <<< $RESPONSE_JSON)
echo $DRIVE_FILE_NAME
DRIVE_FILE_ID=$(jq '.id' <<< $RESPONSE_JSON)
echo $DRIVE_FILE_ID

if [ $ERROR_CODE != "null" ];
then
    echo "error"
    echo $ERROR_CODE
    exit 1
else
    echo "no error"
    echo $RESPONSE_JSON
    exit 0
fi
