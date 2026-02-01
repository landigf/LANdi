# Command Cheat Sheet - Quick Reference

Emergency reference for Meta NPE interviews and lab work.

---

## The 5-Command Triage (First 60 Seconds)

```bash
ip a                    # Do I have an IP? Interfaces up?
ip r                    # Do I have routes? Default gateway?
ping -c 2 <gateway>     # Can I reach my gateway?
ping -c 2 8.8.8.8       # Can I reach Internet?
dig example.com         # Does DNS work?
```

---

## Network State

### Interfaces
```bash
ip a                    # All interfaces and addresses
ip link                 # Link status
ip link show <if>       # Specific interface
ip -s link              # With statistics (packets, errors, drops)
ethtool <if>            # Physical link details (speed, duplex)
```

### Routing
```bash
ip r                    # Routing table
ip r get <ip>           # Route for specific destination
ip r add <net> via <gw> # Add route
ip r del <net>          # Delete route
```

### ARP/Neighbor Discovery
```bash
ip neigh                # ARP cache (IPv4) and ND cache (IPv6)
ip neigh show <ip>      # Specific neighbor
ip neigh flush dev <if> # Clear ARP cache for interface
arping -I <if> <ip>     # Send ARP request
```

---

## DNS

```bash
dig <name>              # Full DNS query
dig +short <name>       # Just the IP
dig @8.8.8.8 <name>     # Use specific DNS server
dig -x <ip>             # Reverse DNS lookup
dig <name> ANY          # All record types

host <name>             # Simpler lookup
nslookup <name>         # Interactive/legacy

getent hosts <name>     # Use system resolver (respects /etc/hosts)

# Config files
cat /etc/resolv.conf    # DNS servers
cat /etc/hosts          # Local overrides
```

---

## Connectivity Testing

### Basic
```bash
ping -c 2 <ip>          # 2 packets
ping -i 0.2 <ip>        # Fast ping (5/sec)
ping -s 1472 <ip>       # Large packets (test MTU)
ping -M do -s 1472 <ip> # Don't fragment (PMTU discovery)
```

### Path Tracing
```bash
traceroute <ip>         # Trace path
traceroute -n <ip>      # No DNS resolution (faster)
traceroute -I <ip>      # Use ICMP instead of UDP

mtr <ip>                # Interactive traceroute
mtr -rwc 20 <ip>        # Report mode, 20 cycles
mtr -rwzbc 50 <ip>      # With ASN info

tracepath <ip>          # Find PMTU
```

### Port Testing
```bash
nc -vz <host> <port>    # TCP port test
nc -vzu <host> <port>   # UDP port test
nc -l 8080              # Listen on port 8080

timeout 5 bash -c "</dev/tcp/<host>/<port>" && echo "Open"  # Pure bash

telnet <host> <port>    # Manual connection test
```

---

## TCP/UDP State

### Socket State
```bash
ss -tuna                # All TCP/UDP sockets
ss -t                   # TCP only
ss -u                   # UDP only
ss -l                   # Listening sockets
ss -p                   # Show process
ss -n                   # No DNS resolution

ss -ti                  # TCP info (cwnd, RTT, retrans)
ss -ti dst <ip>         # Filter by destination
ss -tm                  # Memory info

# Examples
ss -tlnp | grep 80      # What's listening on port 80?
ss -t state established # Active connections
ss -t '( dport = :22 or sport = :22 )' # SSH connections
```

### Legacy (netstat)
```bash
netstat -tuna           # All sockets
netstat -tlnp           # Listening TCP with process
netstat -s              # Statistics
```

---

## Packet Capture (tcpdump)

### Basic
```bash
tcpdump -i any          # All interfaces
tcpdump -i any -nn      # No DNS/port name resolution
tcpdump -i any -c 10    # Capture 10 packets
tcpdump -i any -w out.pcap  # Write to file
tcpdump -r out.pcap     # Read from file
```

### Filters
```bash
tcpdump -i any host <ip>                    # Traffic to/from host
tcpdump -i any net 10.0.0.0/8               # Network
tcpdump -i any port 80                      # Port
tcpdump -i any tcp                          # Protocol

# Combinations
tcpdump -i any 'tcp and host <ip> and port 443'
tcpdump -i any 'host <ip> and not port 22'

# TCP flags
tcpdump -i any 'tcp[tcpflags] & (tcp-syn) != 0'     # SYN packets
tcpdump -i any 'tcp[tcpflags] & (tcp-rst) != 0'     # RST packets
tcpdump -i any 'tcp[13] & 2 != 0'                   # SYN (flag position 13)
```

### Advanced
```bash
tcpdump -i any -nn -A                       # ASCII payload
tcpdump -i any -nn -X                       # Hex + ASCII
tcpdump -i any -nn -s0                      # Capture full packet
tcpdump -i any -nn -tttt                    # Human-readable timestamps
```

---

## BGP (FRRouting vtysh)

### Enter FRR Shell
```bash
docker exec -it <router-name> vtysh
```

### Session Status
```vtysh
show ip bgp summary              # Peer status
show ip bgp neighbors <ip>       # Detailed neighbor info
show ip bgp                      # BGP table (all routes)
show ip bgp <prefix>             # Specific prefix
show ip bgp regexp <pattern>     # Filter by AS_PATH regex
```

### Route Details
```vtysh
show ip route                    # RIB (installed routes)
show ip route bgp                # Only BGP routes
show ip bgp neighbors <ip> routes           # Received from neighbor
show ip bgp neighbors <ip> advertised-routes # Sent to neighbor
```

### Configuration
```vtysh
show running-config              # Full config
show running-config | section bgp
write memory                     # Save config
```

### Troubleshooting
```vtysh
debug bgp updates                # Enable update debugging
debug bgp keepalives             # Enable keepalive debugging
no debug all                     # Disable all debugging

clear ip bgp *                   # Reset all sessions (hard reset)
clear ip bgp * soft              # Soft reset (no teardown)
clear ip bgp <ip>                # Reset specific session

show log                         # View logs
```

---

## OSPF (FRRouting vtysh)

```vtysh
show ip ospf neighbor            # OSPF neighbors
show ip ospf database            # LSDB
show ip ospf route               # OSPF routes
show ip ospf interface           # OSPF-enabled interfaces
```

---

## Traffic Control (tc) - Simulate Network Issues

### Add Impairments
```bash
# 50ms delay
sudo tc qdisc add dev eth0 root netem delay 50ms

# 3% packet loss
sudo tc qdisc add dev eth0 root netem loss 3%

# Combined: 50ms delay + 3% loss
sudo tc qdisc add dev eth0 root netem delay 50ms loss 3%

# Jitter: 50ms ± 10ms
sudo tc qdisc add dev eth0 root netem delay 50ms 10ms

# Bandwidth limit: 1mbit
sudo tc qdisc add dev eth0 root tbf rate 1mbit burst 32kbit latency 400ms
```

### Remove Impairments
```bash
sudo tc qdisc del dev eth0 root
```

### View Current Rules
```bash
sudo tc qdisc show dev eth0
```

---

## Performance & Resources

### CPU & Memory
```bash
top                     # Interactive monitor
htop                    # Better top (if installed)
free -h                 # Memory usage
vmstat 1                # CPU, memory, I/O stats every second
```

### Disk
```bash
df -h                   # Disk usage
du -sh <dir>            # Directory size
iostat                  # I/O stats
```

### System Logs
```bash
dmesg | tail            # Kernel messages
journalctl -xe --no-pager | tail  # System logs
tail -f /var/log/syslog # Live syslog (Ubuntu)
tail -f /var/log/messages # Live syslog (RHEL)
```

---

## Docker/Containerlab

### Container Management
```bash
docker ps               # Running containers
docker ps -a            # All containers
docker exec -it <name> bash # Shell into container
docker logs <name>      # View logs
docker inspect <name>   # Full container details
docker rm -f <name>     # Force remove container
```

### Lab Management
```bash
sudo containerlab deploy -t <file>.clab.yml     # Deploy lab
sudo containerlab inspect -t <file>.clab.yml    # Show lab topology
sudo containerlab inspect --all                 # All labs
sudo containerlab destroy -t <file>.clab.yml    # Destroy lab
sudo containerlab destroy --all                 # Destroy all labs
sudo containerlab save -t <file>.clab.yml       # Save configs
```

---

## Firewall (iptables)

### View Rules
```bash
sudo iptables -L -n -v          # List rules with stats
sudo iptables -t nat -L -n -v   # NAT table
sudo iptables -S                # Show rules in save format
```

### Basic Rules
```bash
# Allow port
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# Block IP
sudo iptables -A INPUT -s <ip> -j DROP

# Flush all rules
sudo iptables -F
```

---

## HTTP/HTTPS Testing

### cURL
```bash
curl <url>                      # GET request
curl -v <url>                   # Verbose (shows headers, TLS handshake)
curl -I <url>                   # HEAD request (headers only)
curl -X POST -d "data" <url>    # POST with data

# Timing breakdown
curl -o /dev/null -s -w "DNS:%{time_namelookup}s Connect:%{time_connect}s SSL:%{time_appconnect}s Transfer:%{time_starttransfer}s Total:%{time_total}s\n" <url>

# Follow redirects
curl -L <url>

# Save output
curl -o output.html <url>
```

### wget
```bash
wget <url>                      # Download file
wget -O output.html <url>       # Save with custom name
wget -c <url>                   # Continue interrupted download
```

---

## System Configuration (sysctl)

### View TCP Settings
```bash
sysctl -a | grep tcp            # All TCP settings
sysctl net.ipv4.tcp_congestion_control  # Current CC algorithm
```

### Modify (temporary)
```bash
sudo sysctl -w net.ipv4.tcp_congestion_control=bbr
sudo sysctl -w net.ipv4.ip_forward=1  # Enable IP forwarding
```

### Permanent Changes
```bash
# Add to /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p  # Reload
```

---

## Quick Diagnosis Decision Tree

```
Problem Type?
│
├─ Can't resolve name → dig, cat /etc/resolv.conf
├─ Can't reach IP → ping, traceroute, ip r
├─ Port closed → nc -vz, ss -tlnp, iptables -L
├─ Slow → ss -ti, mtr, tcpdump (look for retrans)
├─ Intermittent → watch commands, check logs
└─ Works sometimes → compare paths, tcpdump, check DNS
```

---

## Interview One-Liners

### "Show me your IP and route"
```bash
ip a; ip r
```

### "Test connectivity to Google DNS"
```bash
ping -c 2 8.8.8.8 && echo OK || echo FAIL
```

### "What's listening on port 80?"
```bash
ss -tlnp | grep :80
```

### "Trace path and check for loss"
```bash
mtr -rwc 20 google.com
```

### "Show me active TCP connections with details"
```bash
ss -ti state established
```

### "Capture HTTP traffic for 10 seconds"
```bash
timeout 10 sudo tcpdump -i any -nn 'tcp port 80' -w capture.pcap
```

---

**Print this and keep it handy during labs and interviews!**
