#!/bin/ash -e

echoerr() { echo "$@" 1>&2; }

readonly MQTT_AUTH='--unix /tmp/mosquitto.sock'
readonly JQ_SCRIPT=/usr/lib/rtl-433/mqtt-publisher.jq
readonly PUB_OPTS='-V 5 --property publish message-expiry-interval 3600'

jq --unbuffered -n -r -f $JQ_SCRIPT | while IFS=$'\t' read -r MQTT_TOPIC MQTT_PAYLOAD MQTT_RETAIN
do
    if [ -z "$MQTT_PAYLOAD" ]; then
        if ! mosquitto_pub $PUB_OPTS $MQTT_AUTH -t "$MQTT_TOPIC" -n $MQTT_RETAIN
        then
            echoerr [MQTT Publisher] Fail to send null message: $MQTT_TOPIC
        fi
    else
        if ! mosquitto_pub $PUB_OPTS $MQTT_AUTH -t "$MQTT_TOPIC" -m "$MQTT_PAYLOAD" $MQTT_RETAIN
        then
            echoerr [MQTT Publisher] Fail to send message: $MQTT_TOPIC
        fi
    fi
done
