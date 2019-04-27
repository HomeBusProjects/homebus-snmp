#!/usr/bin/env ruby

require 'snmp'
require 'mqtt'

require 'homebus'
require 'homebus_app'
require 'homebus_app_options'
require 'json'

require 'pp'

INTERNAL_INTERFACE='eth0'
WAN_INTERFACE='eth1'

class SNMPHomeBusAppOptions < HomeBusAppOptions
  def app_options(op)
    agent_help     = 'the SNMP agent IP address or name'
    community_help = 'the SNMP community string'
    ifnumber_help  = 'the network interface number (ie: 0)'
    ifname_help    = 'the network interface name (ie: eth0)'
    ifip_help      = 'the network interface IP address (ie: 10.0.1.1)'


    op.separator 'SNMP options:'
    op.on('-a', '--agent SNMP_AGENT', agent_help) { |value| options[:agent] = value }
    op.on('-c', '--community SNMP_COMMUNITY_STRING', community_help) { |value| options[:community] = vale }
    op.on('-n', '--ifnumber INTERFACE_NUMBER', ifnumber_help) { |value| options[:ifnumber] = value }
    op.on('-N', '--ifname INTERFACE_NAME', ifname_help) { |value| options[:ifname] = value }
    op.on('-i', '--ifip INTERFACE_IP_ADDRESS', ifip_help) { |value| options[:ifip] = value }
    op.separator ''
  end

  def banner
    'HomeBus SNMP network activity collector'
  end

  def version
    '0.0.1'
  end

  def name
    'homebus-snmp'
  end
end


class SNMPHomeBusApp < HomeBusApp
  def initialize(options)
    @options = options

    @first_pass =  true

    @last_rcv_bytes = 0
    @last_xmt_bytes = 0

    @manager_hostname = @options[:agent]

    super
  end

  def find_interface_by_ip(ip_address)
    response = @manager.get(["IP-MIB::ipAdEntIfIndex.#{ip_address}"])
    response.each_varbind do |vb|
      puts "#{vb.name.to_s}  #{vb.value.to_s}  #{vb.value.asn1_type}"
    end
  end

  def setup!
    @manager = SNMP::Manager.new(host: '10.0.1.1', community: 'public')

    response = @manager.get(['sysDescr.0', 'sysName.0', 'sysLocation.0', 'sysUpTime.0'])
    response.each_varbind do |vb|
      puts "#{vb.name.to_s}  #{vb.value.to_s}  #{vb.value.asn1_type}"
      @sysName = vb.value.to_s if  vb.name.to_s == 'SNMPv2-MIB::sysName.0'
      @sysDescr = vb.value.to_s if  vb.name.to_s == 'SNMPv2-MIB::sysDescr.0'
      @sysLocation = vb.value.to_s if  vb.name.to_s == 'SNMPv2-MIB::sysLocation.0'
    end

    interface_count = 0

    response = @manager.get(['ifNumber.0'])
    response.each_varbind do |vb|
      puts "#{vb.name.to_s}  #{vb.value.to_s}  #{vb.value.asn1_type}"
      interface_count = vb.value.to_i
    end

    response = @manager.get(Range.new(1, interface_count).map { |i| "ifName.#{i}" })
    response.each_varbind do |vb|
      puts "#{vb.name.to_s}  #{vb.value.to_s}  #{vb.value.asn1_type}"
    end
  end

  def work!
    rcv_bytes = 0
    xmt_bytes = 0
    response = @manager.get(['ifInOctets.3', 'ifOutOctets.3'])
    response.each_varbind do |vb|
      puts "#{vb.name.to_s}  #{vb.value.to_s}  #{vb.value.asn1_type}"
      rcv_bytes = vb.value.to_i if vb.name.to_s == 'IF-MIB::ifOutOctets.3'
      xmt_bytes = vb.value.to_i if vb.name.to_s == 'IF-MIB::ifInOctets.3'
    end



#    out = `snmpbulkwalk -v 2c -c public -Osq 10.0.1.1 .1.3.6.1.2.1.3.1.1.2`
#    pp out
#    active_hosts = out.split("\n").length
    active_hosts = 1

    unless @first_pass
      puts "receive #{rcv_bytes - @last_rcv_bytes} bytes, #{((rcv_bytes - @last_rcv_bytes)/20.0*8/1024).to_i} kbps"
      puts "transmit #{xmt_bytes - @last_xmt_bytes} bytes, #{((xmt_bytes - @last_xmt_bytes)/20.0*8/1024).to_i} kbps"

      results = { timestamp: Time.now.to_i,
                  receive_bandwidth: ((rcv_bytes - @last_rcv_bytes)/20.0*8).to_i,
                  transmit_bandwidth: ((xmt_bytes - @last_xmt_bytes)/20.0*8).to_i,
                  active_hosts: active_hosts }

      pp results
    else
      @first_pass = false
    end

    @last_rcv_bytes = rcv_bytes
    @last_xmt_bytes = xmt_bytes

    sleep 60
  end

  def manufacturer
    'HomeBus'
  end

  def model
    @sysDescr
  end

  def friendly_name
    "Network activity for #{@manager_hostname}"
  end

  def friendly_location
    @sysLocation
  end

  def serial_number
    ''
  end

  def pin
    ''
  end

  def devices
    [
      { friendly_name: 'Receive bandwidth',
        friendly_location: '',
        update_frequency: 60,
        index: 0,
        accuracy: 0,
        precision: 0,
        wo_topics: [ 'network/bandwidth' ],
        ro_topics: [],
        rw_topics: []
      },
      { friendly_name: 'Transmit bandwidth',
        friendly_location: '',
        update_frequency: 60,
        accuracy: 0,
        precision: 0,
        index: 1,
        wo_topics: [ 'network/bandwidth' ],
        ro_topics: [],
        rw_topics: []
      },
      { friendly_name: 'Active hosts',
        friendly_location: '',
        update_frequency: 60,
        accuracy: 0,
        precision: 0,
        index: 2,
        wo_topics: [ 'network/active' ],
        ro_topics: [],
        rw_topics: []
      }
    ]
  end
end

snmp_app_options = SNMPHomeBusAppOptions.new

snmp = SNMPHomeBusApp.new snmp_app_options.options
snmp.run!
