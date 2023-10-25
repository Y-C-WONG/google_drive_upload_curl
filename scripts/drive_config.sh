#!/bin/bash

CLIENT_ID=""
SCOPE="https://www.googleapis.com/auth/drive"
AUTH_CODE=""
CLIENT_SECRET=""
REFRESH_TOKEN=""
UPLOAD_FILE=""
MIMETYPE=""
DRIVE_FOLDER_ID=""
AUTH_REQ_URL="https://accounts.google.com/o/oauth2/auth?client_id=$CLIENT_ID&redirect_uri=http://localhost&response_type=code&scope=https://www.googleapis.com/auth/drive&access_type=offline"
REFRESH_REQ_DATA="code=$AUTH_CODE&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&grant_type=authorization_code&redirect_uri=http://localhost"
TOKEN_REQ_API_URL="https://oauth2.googleapis.com/token"
