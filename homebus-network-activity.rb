#!/usr/bin/env ruby

require './options'
require './app'

network_activity_app_options = NetworkActivityHomebusAppOptions.new

network_activity = NetworkActivityHomebusApp.new network_activity_app_options.options
network_activity.run!
