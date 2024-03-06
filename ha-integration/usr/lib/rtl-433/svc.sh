#!/bin/sh

#
# rtl-433 service utilities
#

echoerr() {
  logger -t rtl-433 -s "$@"
}

readonly MQTT_SOCKET=/tmp/mosquitto.sock

start_rtl_433_service() {
	readonly DEVSN=$1
	if [ -z "$DEVSN" ]; then
		echoerr Serial number of RTL-SDR device not specified
		return 1
	fi

	readonly FREQ=$2
	if [ -z "$FREQ" ]; then
		echoerr Frequency not specified
		return 1
	fi
	readonly CONF_FILE=/usr/lib/rtl-433/rtl-$FREQ.conf
	if [ ! -f $CONF_FILE ]; then
		echoerr Configuration file $CONF_FILE not found
		return 1
	fi

	# this file should be created by 50-rtl-sdr USB hotplug script
	readonly DEV_FILE=/tmp/rtl-sdr/$DEVSN/dev
	if [ ! -f $DEV_FILE ]; then
		echoerr Device with serial number $DEVSN not found
		return 1
	fi

	procd_open_instance
	procd_set_param env DEVSN=$DEVSN
	procd_set_param command /usr/bin/socat -U
	procd_append_param command "EXEC:'mosquitto_pub --unix $MQTT_SOCKET -V 5 --property publish message-expiry-interval 300 --property publish payload-format-indicator 1 --property publish content-type application/json -l -t rtl_433/output/$DEVSN',pipes"
	procd_append_param command "EXEC:'rtl_433 -c $CONF_FILE',nofork,pipes"
	procd_set_param stderr 1
	procd_set_param respawn 3600 10 0
	procd_set_param term_timeout 15
	procd_set_param nice -15
	procd_set_param user mosquitto
	procd_set_param group plugdev
	procd_set_param no_new_privs 1
	procd_add_jail rtl-$DEVSN
	procd_add_jail_mount /usr/bin/mosquitto_pub
	procd_add_jail_mount /usr/bin/rtl_433
	procd_add_jail_mount_rw $(cat $DEV_FILE)
	procd_add_jail_mount /tmp
	procd_add_jail_mount_rw $MQTT_SOCKET
	procd_add_jail_mount $CONF_FILE
	procd_add_jail_mount /usr/lib/rtl-433/flex
	procd_close_instance
}
