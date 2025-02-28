#!/bin/ash -e

sudo -u mosquitto mosquitto_sub --unix /tmp/mosquitto.sock -t rtl_433/output/# -F '%t\t%p'

