# Homebus-Network-Activity

This is a simple HomeBus data source which queries a router using NETWORK-ACTIVITY to track current bandwidth and the number of active hosts.

## Usage

On its first run, `homebus-network-activity` needs to know how to find the HomeBus provisioning server.

```
bundle exec homebus-network-activity -b homebus-server-IP-or-domain-name -P homebus-server-port
```

The port will usually be 80 (its default value).

Once it's provisioned it stores its provisioning information in `.env.provisioning`.

`homebus-network-activity` also needs to know:

- the IP address or name of the router it's monitoring
- the interface name or IP address of the network interface it's monitoring
- the NETWORK-ACTIVITY community string (default: 'public') for the router

```
homebus-network-activity -a router-IP-or-name -c community-string -i interface-ip-address -n inteface-name -N interface-number
```

Only one of `-i`, `-n` and `-N` may be specified.
