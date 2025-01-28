#!/bin/bash

buildType=$1
# SMTP server details
SMTP_SERVER="mail.jiangxia.com.sg"
SMTP_PORT="587"
SMTP_USERNAME="om-bot@jiangxia.com.sg"
SMTP_PASSWORD="Om-bot789!@#"

email="darren@jiangxia.com.sg malick@jiangxia.com.sg changming@jiangxia.com.sg mikko@jiangxia.com.sg skylar@jiangxia.com.sg ester@jiangxia.com.sg belinda@jiangxia.com.sg kokfung@jiangxia.com.sg gina@jiangxia.com.sg barry@jiangxia.com.sg jingmin@jiangxia.com.sg marx@jiangxia.com.sg"
for d in $email
do 
# Replace these variables with appropriate values
    TO_EMAIL=$d         # The recipient's email address
    FROM_EMAIL="om-bot@jiangxia.com.sg"      # Your email address
    SUBJECT="Files Attachment"              # Email subject
    BODY="ANDROID APP BUILD SUCCESSFUL"      # Email body
    IMAGE_FILE=$(find ~/Desktop/$buildType/apk/ -iname "*.png")  # Path to the image file
    APK_FILE=$(find ~/Desktop/$buildType/apk/ -iname "*.apk")     # Path to the APK file
    APK_TXT=$(find ~/Desktop/$buildType/apk -iname "*.txt")
    APK=$(cat $APK_TXT)
    # Check if the image file exists
    if [ ! -f "$IMAGE_FILE" ]; then
        echo "Error: Image file not found at '$IMAGE_FILE'"
        exit 1
    fi

    # Check if the APK file exists
    if [ ! -f "$APK_FILE" ]; then
        echo "Error: APK file not found at '$APK_FILE'"
        exit 1
    fi

    HTML_CONTENT="<html>
            <head>
            <style>
            .container {
            border: 3px solid black;
            padding: 15px;
            }
            h1 { 
            color: black;
            background-color: green;
            padding: 10px  
            }
            </style>
            </head>
            <div class='container'>
            <body>
            <h1>ANDROID APP BUILD SUCCESSFUL</h1>
            <h2>Please check the attachments in this email.</h2>
            <h3>$APK</h3>
            </body>
            </html>"

    # Send the email using swaks with attachments
    /opt/homebrew/bin/swaks --to "$TO_EMAIL" \
        --from "$FROM_EMAIL" \
        --server "$SMTP_SERVER" \
        --port "$SMTP_PORT" \
        --auth-user "$SMTP_USERNAME" \
        --auth-password "$SMTP_PASSWORD" \
        --header "Subject: $SUBJECT" \
        --header "MIME-Version: 1.0" \
        --header "Content-Type: multipart/mixed; boundary=\"BOUNDARY\"" \
        --header "Content-Type: text/html" \
        --body "$HTML_CONTENT" \
        --attach "$IMAGE_FILE"

    if [ $? -eq 0 ]; then
        echo "Email sent successfully!"
    else
        echo "Error sending email. Please check your email configuration."
    fi
done
