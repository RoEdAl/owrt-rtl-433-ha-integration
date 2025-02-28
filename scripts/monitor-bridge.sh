#!/bin/ash -e

sudo -u mosquitto mosquitto_sub --unix /tmp/mosquitto.sock -t  '$SYS/broker/connection/#' -F '%t\t%p'
