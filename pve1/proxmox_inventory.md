# Proxmox infrastructure context

Generated: 2026-06-30T14:48:35+02:00

## Cluster nodes

- pve1: status=online, CPU=0%, memory=5GiB/15GiB

## Guests

### ubu2 (lxc 100)

- Node: pve1
- Status: stopped
- IP address(es): unknown
- CPU cores: 1
- Memory: 0.5 GiB
- Disk: 8.0 GiB
- Tags: none
- Description/notes: ## - Ubuntu container up-to date with docker installed.  
- Network config: net0=name=eth0,bridge=vmbr0,firewall=1,hwaddr=BC:24:11:89:70:ED,ip=dhcp,type=veth

### db1 (lxc 101)

- Node: pve1
- Status: running
- IP address(es): 10.0.27.239/24,172.17.0.1/16 172.18.0.1/16
- CPU cores: 1
- Memory: 0.5 GiB
- Disk: 7.8 GiB
- Tags: none
- Description/notes: ## `VALHALLA` - Ubuntu container up-to date with docker installed. running db  10.0.27.293  
- Network config: net0=name=eth0,bridge=vmbr0,firewall=1,hwaddr=BC:24:11:6E:34:B0,ip=dhcp,type=veth

### web1 (lxc 102)

- Node: pve1
- Status: running
- IP address(es): 10.0.27.223/24,172.17.0.1/16 172.18.0.1/16
- CPU cores: 1
- Memory: 0.5 GiB
- Disk: 7.8 GiB
- Tags: none
- Description/notes: ## `MIDGARD` - Ubuntu container up-to date with docker installed. running car-part distribution website  10.0.27.223:8000  
- Network config: net0=name=eth0,bridge=vmbr0,firewall=1,hwaddr=BC:24:11:E9:E7:6E,ip=dhcp,type=veth

### proxy (lxc 103)

- Node: pve1
- Status: running
- IP address(es): 10.0.27.228/24,172.18.0.1/16 172.17.0.1/16
- CPU cores: 1
- Memory: 0.5 GiB
- Disk: 7.8 GiB
- Tags: none
- Description/notes: ## `BIFROST` - Ubuntu container up-to date with docker installed. machine to run nginx proxy  10.0.27.228  
- Network config: net0=name=eth0,bridge=vmbr0,firewall=1,hwaddr=BC:24:11:93:B3:C5,ip=dhcp,type=veth

### ubuVM (qemu 104)

- Node: pve1
- Status: stopped
- IP address(es): unknown
- CPU cores: 2
- Memory: 4.0 GiB
- Disk: 32.0 GiB
- Tags: none
- Description/notes: none 
- Network config: net0=virtio=BC:24:11:E2:58:A0,bridge=vmbr0,firewall=1

### n8n (qemu 105)

- Node: pve1
- Status: running
- IP address(es): unknown
- CPU cores: 2
- Memory: 4.0 GiB
- Disk: 32.0 GiB
- Tags: none
- Description/notes: ## `ASGARD` - Ubuntu VM running n8n instance in Docker  10.0.27.10:443  https://n8n/   https://n8n.chestnut-boga.ts.net  user: controller   pass: opencontroller  n8n credentials:   email: tfg@jota.ing   passw: Opencontroller1 
- Network config: net0=virtio=BC:24:11:FF:6F:4C,bridge=vmbr0

### rsyslog (lxc 106)

- Node: pve1
- Status: running
- IP address(es): 10.0.27.162/24,100.68.79.81/32 172.17.0.1/16
- CPU cores: 1
- Memory: 0.5 GiB
- Disk: 7.8 GiB
- Tags: none
- Description/notes: ## - Ubuntu container up-to date with docker installed.  root@10.0.27.162  script at ``sudo python3 /usr/local/bin/log-detector.py``   vector configuration at ``/etc/vector/vector.toml``  
- Network config: net0=name=eth0,bridge=vmbr0,firewall=1,hwaddr=BC:24:11:01:21:AB,ip=dhcp,type=veth

