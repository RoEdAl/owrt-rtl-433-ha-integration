#!/bin/ash -e

sudo -u mosquitto mosquitto_sub --unix /tmp/mosquitto.sock -t mqtt/publish --pretty

