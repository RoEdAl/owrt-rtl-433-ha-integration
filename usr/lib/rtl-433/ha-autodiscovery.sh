#!/bin/ash -e

readonly YQ_SCRIPT=/usr/lib/rtl-433/ha-autodiscovery.yq
cd /etc/home-assistant

echoerr() { echo "$@" 1>&2; }
readonly RETAIN=retain

send_autodiscovery_entities() {
    for d in $(find autodiscovery -type d -mindepth 1 -maxdepth 1); do
        COMPONENT=$(basename $d)
	for g in $(find $d -type d -mindepth 1 -maxdepth 1); do
            GROUP_ID=$(basename $g)
            for f in $(find $g -type f -name '*.yml' -maxdepth 1); do
                fwe=${f%.yml}
                OBJECT_ID=$(basename $fwe)
                env COMPONENT=$COMPONENT GROUP_ID=$GROUP_ID OBJECT_ID=$OBJECT_ID yq --from-file=$YQ_SCRIPT -I 0 -o json $f
            done
        done
        for f in $(find $d -type f -name '*.yml' -maxdepth 1); do
            fwe=${f%.yml}
            OBJECT_ID=$(basename $fwe)
            env -u GROUP_ID COMPONENT=$COMPONENT OBJECT_ID=$OBJECT_ID yq --from-file=$YQ_SCRIPT -I 0 -o json $f
        done
    done
}

clear_autodiscovery_entities() {
    for d in $(find autodiscovery -type d -mindepth 1 -maxdepth 1); do
        COMPONENT=$(basename $d)
        for g in $(find $d -type d -mindepth 1 -maxdepth 1); do
            GROUP_ID=$(basename $g)
            for f in $(find $g -type f -name '*.yml' -maxdepth 1); do
                fwe=${f%.yml}
                OBJECT_ID=$(basename $fwe)
                echo -e "$1\thomeassistant/$COMPONENT/rtl_433/$OBJECT_ID/config\t$PAYLOAD"
            done
        done
        for f in $(find $d -type f -name '*.yml' -maxdepth 1); do
            fwe=${f%.yml}
            OBJECT_ID=$(basename $fwe)
            echo -e "$1\thomeassistant/$COMPONENT/rtl_433/$OBJECT_ID/config"
        done
    done
}

process_mqtt_event() {
    case $1 in
        homeassistant/status)
        echoerr '[HA Autodiscovery]' HA Status: $2
        if [ "$2" = 'online' ]; then
            echoerr '[HA Autodiscovery]' Sending autodiscovery entities
            send_autodiscovery_entities $RETAIN
        fi;;

        \$SYS/broker/connection/*/state)
        echoerr '[HA Autodiscovery]' Connection State: $2
        if [ "$2" = '1' ]; then
            echoerr '[HA Autodiscovery]' Sending autodiscovery entities
            send_autodiscovery_entities $RETAIN
        fi;;
    esac
}

case ${1:-service} in
    send)
    echoerr '[HA Autodiscovery]' Sending
    send_autodiscovery_entities $RETAIN;;

    service)
    mosquitto_sub -V 5 --unix /tmp/mosquitto.sock \
        -x 86400 \
	-t 'homeassistant/status' \
        -t '$SYS/broker/connection/+/state' \
	-F '%t\t%p' | while IFS=$'\t' read -r topic payload
    do
        process_mqtt_event $topic $payload
    done;;

    clear)
    echoerr Clearing autodiscovery entities
    clear_autodiscovery_entities $RETAIN;;

   *)
   echoerr Invalid verb: $1
   echoerr Possible verbs: send,clear,service
   exit 1;;
esac
