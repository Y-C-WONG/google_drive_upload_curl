#!/bin/bash

# This script upload file to google drive using google drive API
# Author: Yau Chuen Wobng in October, 2023
# -----------------------------------------
# Before using any google api, please create Oauth2 credentials in the Google API console.
# For more detail, please visit https://developers.google.com/identity/protocols/oauth2.
# If you are the first time using the google drive api, please get the authorization code, 
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
    https://oauth2.googleapis.com/token |  grep -zoP '"access_token":\s*\K[^\s,]*(?=\s*,)')
    echo $ACCESS_TOKEN
}

UPLOAD_FILE=""
MIMETYPE=""
DRIVE_FOLDER_ID=""
KEEP_No_FILES=3

function _uploadToGoogleDrive()
{
    RESPONSE_JSON_UPLOAD=$(curl -X POST -s -S -L -H "Authorization: Bearer $ACCESS_TOKEN" \
    -F "metadata={name : '$UPLOAD_FILE', parents : ['$DRIVE_FOLDER_ID'], description : 'Wordpress Backup Archive File', appProperties:{'WPBAKFILE':'YES'}};type=application/json;charset=UTF-8" \
    -F "file=@$UPLOAD_FILE;type=$MIMETYPE" "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart")
}

function _deleteOnGoogleDrive()
{
    echo "!! File ID = $DEL_FILE_ID is being DELETED !!"
    echo "https://www.googleapis.com/drive/v3/files/$DEL_FILE_ID"
    RESPONSE_JSON_DEL=$(curl -X DELETE -s -S -L -H "Authorization: Bearer $ACCESS_TOKEN" "https://www.googleapis.com/drive/v3/files/$DEL_FILE_ID")
    echo $RESPONSE_JSON_DEL
}

function _getDelFileList()
{
        echo "!! List of the children for folder $DRIVE_FOLDER_ID !!"
RESPONSE_JSON_DEL_FILE=$(curl -G -s -S -L -d "orderBy=createdTime" -d "pageSize=10" -d "q='$DRIVE_FOLDER_ID'%20in%20parents%20and%20trashed%3Dfalse%20and%20mimeType='$MIMETYPE'%20and%20appProperties%20has%20{key='WPBAKFILE'%20and%20value='YES'}" -H "Authorization: Bearer $ACCESS_TOKEN" -H "Accept: application/json" --compressed "https://www.googleapis.com/drive/v3/files")
        echo $RESPONSE_JSON_DEL_FILE

        DRIVE_DEL_FILE_IDs=$(grep -zoP '"id":\s*"\K[^\s,]*(?=\s*,)' <<< $RESPONSE_JSON_DEL_FILE)
        IFS='"' read -r -a DRIVE_DEL_FILE_LIST <<< "$DRIVE_DEL_FILE_IDs"
        printf 'File ID -> %s\n' "${DRIVE_DEL_FILE_LIST[@]}"
        if [ -z $DRIVE_DEL_FILE_IDs ]; then
            echo '!!! Cannot retrived file list or no file can be found !!!'
            echo $RESPONSE_JSON_DEL_FILE > GET_DEL_FILE_LIST_ERROR.log
            exit 1
        else
            DRIVE_DEL_FILE_COUNT=${#DRIVE_DEL_FILE_LIST[*]}
            echo $DRIVE_DEL_FILE_COUNT
            echo $KEEP_No_FILES
            if [ $DRIVE_DEL_FILE_COUNT -gt $KEEP_No_FILES ]; then
                    TTL_DEL_FILE_COUNT="$(($DRIVE_DEL_FILE_COUNT-$KEEP_No_FILES))"
                echo $TTL_DEL_FILE_COUNT
                DEL_FILE_ID_LIST=()
                for (( i=0; i<$TTL_DEL_FILE_COUNT; i++ ));
                    do
                        DEL_FILE_ID_LIST[$i]="${DRIVE_DEL_FILE_LIST[$i]}"
                    done
                printf 'DEL File ID -> %s\n' "${DEL_FILE_ID_LIST[@]}"
            fi
        fi
}

SRC_DIR=$(dirname "$0")"/"

## Get the variable from drive_config.sh 
. $SRC_DIR"drive_config.sh"

_getAccessToken
_uploadToGoogleDrive

echo $RESPONSE_JSON_UPLOAD
ERROR_CODE=$(grep -zoP '".error.code":\s*\K[^\s,]*(?=\s*,)' <<< $RESPONSE_JSON_UPLOAD)
echo $ERROR_CODE
DRIVE_FILE_NAME=$(grep -zoP '"name":\s*"\K[^\s,]*(?=\s*",)' <<< $RESPONSE_JSON_UPLOAD)
echo $DRIVE_FILE_NAME
DRIVE_FILE_ID=$(grep -zoP '"id":\s*"\K[^\s,]*(?=\s*",)' <<< $RESPONSE_JSON_UPLOAD)
echo $DRIVE_FILE_ID

## Check the response if the upload success.  Stop the script if error find. Delete old file if upload successfully.
if [ -z $DRIVE_FILE_ID ]; then
    echo "error"
    echo $ERROR_CODE
    echo $RESPONSE_JSON_UPLOAD > UPLOAD_ERROR.log
    exit 1
else
    echo "no error"
    echo $RESPONSE_JSON_UPLOAD
    _getDelFileList
    echo "--- Start Del Drive File ---"
    for DEL_FILE_ID in "${DEL_FILE_ID_LIST[@]}"
    do
        echo "$DEL_FILE_ID"
        _deleteOnGoogleDrive
    done
fi
exit 0
