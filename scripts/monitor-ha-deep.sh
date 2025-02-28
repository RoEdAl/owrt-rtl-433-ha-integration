#!/bin/ash -e

sudo -u mosquitto mosquitto_sub --unix /tmp/mosquitto.sock -t rtl_433/ha/# -F '%t\t%p' -R


