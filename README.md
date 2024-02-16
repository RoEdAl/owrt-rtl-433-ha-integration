# Integration of [rtl_433](http://triq.org/rtl_433) with [Home Assistant](http://home-assistant.io) based on [OpenWRT](http://openwrt.org) operating system

## Hardware

* Two cheap **RTL2832U**-based dongles.

  Use `rtl_eeprom` tool to set different serial numbers of your dongles if nessesary.\
  Here `00000100` and `00000101` ones are used.

* [A10-OLinuXino-LIME](http://www.olimex.com/Products/OLinuXino/A10/A10-OLinuXino-LIME-n4GB/open-source-hardware) SBC from *Olimex*.

## Software

## Required packages

* mosquitto-nossl
* mosquitto-client-nossl
* jq
* yq
* socat
* rtl_433

## Services

* [mosquitto-local](etc/init.d/mosquitto-local)

  Local instance of *Mosquitto* broker. Communication via UNIX socket only.

* [mqtt-publisher](etc/init.d/mqtt-publisher)

  Publishing MQTT messages to *Home Assistant*.

* [rtl-433-processor](etc/init.d/rtl-433-processor)

  Processing JSON-formatted output of `rtl_433` services.

* [rtl-433](etc/init.d/rtl-433), [rtl-866](etc/init.d/rtl-866)

  `rtl_433` instances.

* [ha-autodiscovery](etc/init.d/ha-autodiscovery)

  Simple autodiscovery service.
  Configuration taken from [/etc/home-assistant/autodiscovery](etc/home-assistant/autodiscovery/) directory.
