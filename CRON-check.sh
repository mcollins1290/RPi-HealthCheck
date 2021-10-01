#!/bin/bash
cd "$(dirname "$0")";

###### Script to be run by CRON to call the RPi HealthCheck API DB Connection Test method and report issues via email
SEND_EMAIL_IF_OKAY=$1
TO_EMAIL=mcollins1290@gmail.com

response=$(curl -G -s http://raspberrypi2.budd:5000/dbconnectioncheck)
retVal=$?

if [ $retVal -ne 0 ]; then
	echo "No response from RPi HealthCheck API." | mail -s "ALERT - RPi HealthCheck DB Connection Test" $TO_EMAIL
else
	status=$(echo $response | jq -r '.status')
	message=$(echo $response | jq -r '.message')

	if [ $status -ne 0 ]; then
		printf "Status: ${status}\nMessage: ${message}" | mail -s "ALERT - RPi HealthCheck DB Connection Test" $TO_EMAIL
	else
		if [ "$SEND_EMAIL_IF_OKAY" = true ] ; then
			printf "Status: ${status}\nMessage: ${message}" | mail -s "OK - RPi HealthCheck DB Connection Test" $TO_EMAIL
		fi
	fi
fi

exit 0
