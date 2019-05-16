#!/usr/bin/env ruby

require './options'
require './app'

snmp_app_options = SNMPHomeBusAppOptions.new

snmp = SNMPHomeBusApp.new snmp_app_options.options
snmp.run!
