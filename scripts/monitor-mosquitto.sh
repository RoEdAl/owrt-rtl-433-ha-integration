#!/bin/ash -e

sudo -u mosquitto mosquitto_sub --unix /tmp/mosquitto.sock -t '$SYS/broker/log/#' -F '%t\t%p'
