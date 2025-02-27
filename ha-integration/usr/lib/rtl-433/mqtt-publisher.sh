#!/bin/ash -e

echoerr() { echo "$@" 1>&2; }

MQTT_AUTH='["--unix", "/tmp/mosquitto.sock"]'
PUB_OPTS='["-V", 5, "--property", "publish", "message-expiry-interval", 3600]'
JQ_SCRIPT=/usr/lib/rtl-433/mqtt-publisher.jq

jq --argjson pubopts "$PUB_OPTS" --argjson auth "$MQTT_AUTH" --unbuffered -n -r -f $JQ_SCRIPT | while IFS=$'' read -r PUBCMD
do
    # echoerr [mqtt-pub] $PUBCMD
    if ! eval $PUBCMD
    then
        echoerr [MQTT Publisher] Fail to execute command $PUBCMD
    fi
done
