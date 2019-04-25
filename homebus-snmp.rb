#!/usr/bin/env ruby

require 'snmp'
require 'pp'

INTERNAL_INTERFACE='eth0'
WAN_INTERFACE='eth1'


# active count
# snmpbulkwalk -v 2c -c public -Osq 10.0.1.1 .1.3.6.1.2.1.3.1.1.2| wc

SNMP::Manager.open(host: '10.0.1.1') do |manager|
#SNMP::Manager.open(host: '192.168.15.1') do |manager|
    response = manager.get(["sysDescr.0", "sysName.0", "sysUpTime.0"])
    response.each_varbind do |vb|
        puts "#{vb.name.to_s}  #{vb.value.to_s}  #{vb.value.asn1_type}"
    end

    interface_count = 0

    response = manager.get(['ifNumber.0'])
    response.each_varbind do |vb|
        puts "#{vb.name.to_s}  #{vb.value.to_s}  #{vb.value.asn1_type}"
        interface_count = vb.value.to_i
    end

    last_rcv_bytes = 0
    last_xmt_bytes = 0
    loop do

    rcv_bytes = 0
    xmt_bytes = 0
    response = manager.get(['ifInOctets.3', 'ifOutOctets.3'])
    response.each_varbind do |vb|
        puts "#{vb.name.to_s}  #{vb.value.to_s}  #{vb.value.asn1_type}"
        rcv_bytes = vb.value.to_i if vb.name.to_s == 'IF-MIB::ifOutOctets.3'
        xmt_bytes = vb.value.to_i if vb.name.to_s == 'IF-MIB::ifInOctets.3'
    end

    puts "receive #{rcv_bytes - last_rcv_bytes} bytes, #{((rcv_bytes - last_rcv_bytes)/20.0*8/1024).to_i} kbps"
    puts "transmit #{xmt_bytes - last_xmt_bytes} bytes, #{((xmt_bytes - last_xmt_bytes)/20.0*8/1024).to_i} kbps"

    active_hosts = `snmpbulkwalk -v 2c -c public -Osq 10.0.1.1 .1.3.6.1.2.1.3.1.1.2`.split("\n").length

    results = { timestamp: Time.now.to_i,
                receive_bandwidth: ((rcv_bytes - last_rcv_bytes)/20.0*8).to_i,
                transmit_bandwidth: ((xmt_bytes - last_xmt_bytes)/20.0*8).to_i,
                active_hosts: active_hosts }

    pp results

    last_rcv_bytes = rcv_bytes
    last_xmt_bytes = xmt_bytes



    sleep 60

    end
end
