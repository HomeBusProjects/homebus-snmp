require 'homebus/options'

require 'homebus-network-activity/version'

class HomebusNetworkActivity::Options < Homebus::Options
  def app_options(op)
    agent_help     = 'the SNMP agent IP address or name'
    community_help = 'the SNMP community string'
    ifnumber_help  = 'the network interface number (ie: 0)'
    ifname_help    = 'the network interface name (ie: eth0)'
    ifip_help      = 'the network interface IP address (ie: 10.0.1.1)'


    op.separator 'SNMP options:'
    op.on('-a', '--agent SNMP_AGENT', agent_help) { |value| options[:agent] = value }
    op.on('-c', '--community SNMP_COMMUNITY_STRING', community_help) { |value| options[:community] = value }
    op.on('-n', '--ifnumber INTERFACE_NUMBER', ifnumber_help) { |value| options[:ifnumber] = value }
    op.on('-N', '--ifname INTERFACE_NAME', ifname_help) { |value| options[:ifname] = value }
    op.on('-i', '--ifip INTERFACE_IP_ADDRESS', ifip_help) { |value| options[:ifip] = value }
    op.separator ''
  end

  def banner
    'Homebus network activity publisher'
  end

  def version
    HomebusNetworkActivity::VERSION
  end

  def name
    'homebus-network-activity'
  end
end
