require 'homebus'
require 'snmp'
require 'json'
require 'dotenv/load'

class NetworkActivityHomebusApp < Homebus::App
  DDC_BANDWIDTH = 'org.homebus.experimental.network-bandwidth'
  DDC_ACTIVE_HOSTS = 'org.homebus.experimental.network-active-hosts'

  def initialize(options)
    @options = options

    @first_pass =  true

    @last_rcv_bytes = 0
    @last_xmt_bytes = 0

    @agent = @options[:agent] || ENV['SNMP_AGENT']
    @community_string = @options[:community_string] || ENV['SNMP_COMMUNITY_STRING']
    @ifnumber = @options[:ifnumber]

    super
  end

  def find_interface_by_ip(ip_address)
    response = @manager.get(["IP-MIB::ipAdEntIfIndex.#{ip_address}"])
    response.each_varbind do |vb|
      if options[:verbose]
        puts "#{vb.name.to_s}  #{vb.value.to_s}  #{vb.value.asn1_type}"
      end
    end
  end

  def setup!
    @manager = SNMP::Manager.new(host: @agent, community: @community_string)

    response = @manager.get(['sysDescr.0', 'sysName.0', 'sysLocation.0', 'sysUpTime.0'])
    response.each_varbind do |vb|
      @sysName = vb.value.to_s if  vb.name.to_s == 'SNMPv2-MIB::sysName.0'
      @sysDescr = vb.value.to_s if  vb.name.to_s == 'SNMPv2-MIB::sysDescr.0'
      @sysLocation = vb.value.to_s if  vb.name.to_s == 'SNMPv2-MIB::sysLocation.0'
    end

    interface_count = 0

    unless @ifnumber
      response = @manager.get(['ifNumber.0'])
      response.each_varbind do |vb|
        interface_count = vb.value.to_i
      end

      response = @manager.get(Range.new(1, interface_count).map { |i| "ifName.#{i}" })
      response.each_varbind do |vb|
        puts "#{vb.name.to_s}  #{vb.value.to_s}  #{vb.value.asn1_type}"
        if vb.value.to_s == @options[:ifname]
          puts "gotta match #{vb.value.to_s}"
          m = vb.name.to_s.match /ifName\.(\d+)/
          pp m
          @ifnumber = m[1]
        end
      end
    end


    @device = Homebus::Device.new name: "Network activity for #{@agent}",
                                  manufacturer: "Homebus",
                                  model: @sysDescr,
                                  serial_number: @agent
  end

  def arp_table_count
    begin
      count = 0
      response = @manager.walk( [ '1.3.6.1.2.1.4.22.1.2' ] ) do |row|
        count += 1
      end

      count
    rescue
      nil
    end
  end

  def _bandwidth
    rcv_bytes = 0
    xmt_bytes = 0

#    puts "ifnumber #{@ifnumber}"

    response = @manager.get(["ifInOctets.#{@ifnumber}", "ifOutOctets.#{@ifnumber}"])
    response.each_varbind do |vb|
#      puts vb.name.to_s
#      puts vb

      xmt_bytes = vb.value.to_i if vb.name.to_s == "IF-MIB::ifOutOctets.#{@ifnumber}"
      rcv_bytes = vb.value.to_i if vb.name.to_s == "IF-MIB::ifInOctets.#{@ifnumber}"
    end

    return rcv_bytes, xmt_bytes
  end

  def work!
    rcv_bytes, xmt_bytes = _bandwidth

    unless @first_pass
      if @options[:verbose]
        puts "receive #{rcv_bytes - @last_rcv_bytes} bytes, #{((rcv_bytes - @last_rcv_bytes)/update_interval*8/1024).to_i} kbps"
        puts "transmit #{xmt_bytes - @last_xmt_bytes} bytes, #{((xmt_bytes - @last_xmt_bytes)/update_interval*8/1024).to_i} kbps"
      end

      rx_bps = ((rcv_bytes - @last_rcv_bytes)/update_interval()*8).to_i
      tx_bps = ((xmt_bytes - @last_xmt_bytes)/update_interval()*8).to_i

      if rx_bps >= 0 || tx_bps >= 0
        results = {
          rx_bps: rx_bps >= 0 ? rx_bps : nil,
          tx_bps: tx_bps >= 0 ? tx_bps : nil
        }

#        @device.publish! DDC_BANDWIDTH, results

        if @options[:verbose]
          pp results
        end
      end
    else
      @first_pass = false
    end

    arp_table_length = arp_table_count

    if arp_table_length
      results = {
        arp_table_length: arp_table_length
      }

#      @device.publish! DDC_ACTIVE_HOSTS, results

      if @options[:verbose]
        pp results
      end
    end

    @last_rcv_bytes = rcv_bytes
    @last_xmt_bytes = xmt_bytes

    sleep update_interval
  end

  def update_interval
    60
  end

  def name
    'Homebus Network Activity Publisher'
  end

  def devices
    [ @device ]
  end

  def publishes
    [ DDC_BANDWIDTH, DDC_ACTIVE_HOSTS ]
  end
end
