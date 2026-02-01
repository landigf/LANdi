# Troubleshooting Hypothesis Trees

Framework for systematic network debugging under time pressure (Meta NPE style).

---

## The Meta Debugging Framework

### Core Principle
**Start broad → narrow systematically → verify with commands → state hypothesis clearly**

Every issue follows this pattern:
1. **Symptom** (what's broken?)
2. **Hypothesis tree** (what could cause this?)
3. **Commands** (2-3 commands to test each hypothesis)
4. **Interpretation** (what does output tell us?)
5. **Action** (fix or next hypothesis)

---

## Issue 1: "Can't Reach Service"

### Hypothesis Tree

```
Can't Reach Service
│
├─ DNS Resolution Failure
│  ├─ DNS server unreachable
│  ├─ Name doesn't exist
│  └─ DNS timeout
│
├─ Network Unreachable
│  ├─ No route to destination
│  ├─ Interface down
│  ├─ Wrong subnet/netmask
│  └─ ARP/ND failure
│
├─ Routing Issue
│  ├─ Missing default gateway
│  ├─ Asymmetric routing
│  ├─ Route flapping
│  └─ Next-hop unreachable
│
├─ Firewall/ACL Block
│  ├─ Host firewall
│  ├─ Network firewall
│  └─ Security group (cloud)
│
├─ Service Not Listening
│  ├─ Service down
│  ├─ Wrong port
│  └─ Binding to localhost only
│
└─ Application Layer Issue
   ├─ TLS/SSL error
   ├─ Authentication failure
   └─ HTTP 500/503
```

### Diagnostic Commands

#### Layer 1: DNS
```bash
# Does name resolve?
dig service.example.com
getent hosts service.example.com

# What DNS servers am I using?
cat /etc/resolv.conf

# Can I reach DNS server?
ping -c 2 8.8.8.8
dig @8.8.8.8 service.example.com
```

**Expected:** IP address returned. If fails → DNS issue.

#### Layer 2: Network Layer
```bash
# Do I have an IP and interface up?
ip a

# Do I have a route to destination?
ip r get <destination-ip>

# Is my default gateway correct?
ip r | grep default

# Can I reach next hop?
ping -c 2 <gateway-ip>
```

**Expected:** Interface UP, route exists, gateway reachable.

#### Layer 3: Path
```bash
# Can I reach destination IP?
ping -c 2 <destination-ip>

# What path does traffic take?
traceroute <destination-ip>
mtr -rw <destination-ip>

# Is there packet loss?
mtr -rwc 20 <destination-ip>
```

**Expected:** Packets reach destination, <100ms latency, 0% loss.

#### Layer 4: Transport
```bash
# Is port open?
nc -vz <ip> <port>
timeout 5 bash -c "</dev/tcp/<ip>/<port>" && echo "Open"

# TCP connection state?
ss -tuna | grep <ip>

# Firewall blocking?
sudo iptables -L -n -v  # Linux
pfctl -sr               # macOS
```

**Expected:** Port open, connection established.

#### Layer 7: Application
```bash
# Full connection test with TLS
curl -v https://service.example.com

# Service listening?
ss -tlnp | grep <port>
netstat -tlnp | grep <port>

# Check service logs
journalctl -u <service> --no-pager | tail
tail -f /var/log/<service>.log
```

**Expected:** HTTP 200, service running on port.

### 90-Second Answer Template

> "I'd start with DNS: `dig <name>` to verify resolution. Then network layer: `ip a` and `ip r` to confirm I have an IP and route. Next, reachability: `ping` and `traceroute` to find where packets stop. Then transport layer: `nc -vz <ip> <port>` to check if port is open. Finally application: `curl -v` for full test and `ss -tlnp` to verify service is listening. Based on where it fails, I'd drill into that layer—DNS, routing, firewall, or service config."

---

## Issue 2: "Slow Connection / High Latency"

### Hypothesis Tree

```
Slow Connection
│
├─ High RTT (Physical/Routing)
│  ├─ Long physical path
│  ├─ Suboptimal routing
│  └─ Congested links
│
├─ Packet Loss
│  ├─ Link errors
│  ├─ Buffer overflow
│  └─ Rate limiting
│
├─ TCP-Specific
│  ├─ Small congestion window
│  ├─ Frequent retransmissions
│  ├─ Small receiver window
│  └─ Slow start every connection
│
├─ Application Layer
│  ├─ Slow backend processing
│  ├─ Database query timeout
│  └─ Large payload
│
└─ DNS Delay
   └─ Slow DNS resolution
```

### Diagnostic Commands

#### Baseline: Is it really slow?
```bash
# Baseline latency
ping -c 10 <destination>

# Better path analysis
mtr -rwc 50 <destination>

# Time a request
time curl -o /dev/null -s https://example.com
curl -o /dev/null -s -w "DNS:%{time_namelookup}s Connect:%{time_connect}s Transfer:%{time_starttransfer}s Total:%{time_total}s\n" https://example.com
```

**Expected:** Consistent RTT, <1% loss, transfer time reasonable.

#### TCP Health
```bash
# TCP connection stats
ss -ti dst <ip>

# Look for:
# - High 'rtt' value
# - Non-zero 'retrans'
# - Small 'cwnd'
# - High 'rto' (retransmission timeout)

# Packet capture to see retransmissions
sudo tcpdump -i any -nn 'host <ip> and tcp[tcpflags] & (tcp-syn) != 0 or tcp[tcpflags] & (tcp-rst) != 0'
```

**Expected:** Low RTT, zero retrans, cwnd >10.

#### Find Lossy Hop
```bash
# Detailed path with loss stats
mtr -rwzbc 50 <destination>

# Shows: hop-by-hop loss percentage
```

**Expected:** 0% loss on all hops. If specific hop shows loss, that's your culprit.

#### DNS Performance
```bash
# How long does DNS take?
time dig example.com

# Try different DNS servers
dig @8.8.8.8 example.com
dig @1.1.1.1 example.com

# Check local cache
cat /etc/hosts
```

**Expected:** DNS resolution <50ms.

### 90-Second Answer Template

> "First, baseline with `ping` and `mtr` to see if latency is routing/path related or packet loss. Then `ss -ti` to check TCP health—high `retrans` means loss, small `cwnd` means TCP throttling itself. If loss, `mtr` shows which hop. If TCP issues but no loss, check if it's application-layer with `curl -w` timing breakdown. Common causes: packet loss causing TCP to back off, long physical path (can't fix physics), or slow DNS every request (needs caching)."

---

## Issue 3: "BGP Routes Not Propagating"

### Hypothesis Tree

```
Routes Not Propagating
│
├─ Session Not Established
│  ├─ TCP 179 blocked
│  ├─ Wrong neighbor config
│  └─ TTL issue (eBGP multihop)
│
├─ Route Policy Filtering
│  ├─ Inbound route-map denying
│  ├─ Outbound route-map not permitting
│  ├─ Prefix-list blocking
│  └─ AS-path filter
│
├─ Best Path Selection Loss
│  ├─ Better path exists
│  ├─ Lower LOCAL_PREF
│  └─ Longer AS_PATH
│
├─ NEXT_HOP Unreachable
│  ├─ No IGP route to NEXT_HOP
│  ├─ Next-hop not changed for iBGP
│  └─ Interface down
│
└─ iBGP Split-Horizon
   ├─ Route from iBGP peer
   ├─ Not sent to other iBGP peers
   └─ Need route reflector or full mesh
```

### Diagnostic Commands

#### Session Health
```bash
# Are sessions up?
show ip bgp summary

# Expected: State shows established, PfxRcd > 0

# Detailed session info
show ip bgp neighbors <ip>

# Look for:
# - State/PfxRcd: Should be a number, not "Active" or "Idle"
# - Last reset: Should be long ago
# - Opens/Updates/Keepalives: Should be incrementing
```

#### Route Visibility
```bash
# Do I see the route in BGP table?
show ip bgp <prefix>

# Expected: Route appears with all paths

# Is it installed in RIB?
show ip route <prefix>

# Expected: Route appears with 'B' flag (BGP)

# What did neighbor send me?
show ip bgp neighbors <ip> routes

# What am I sending to neighbor?
show ip bgp neighbors <ip> advertised-routes
```

#### Policy Check
```bash
# What route-maps are applied?
show running-config | section route-map

# Test specific route against policy
show ip bgp regexp <as-path-regex>

# Check prefix-lists
show ip prefix-list
```

#### NEXT_HOP Reachability
```bash
# Can I reach NEXT_HOP?
show ip bgp <prefix>  # Note NEXT_HOP
show ip route <next-hop-ip>

# Expected: IGP route to NEXT_HOP exists

# Verify next-hop in correct VRF (if using VRFs)
```

### 90-Second Answer Template

> "Start with `show ip bgp summary` to verify session is established. If not, check connectivity and TCP 179. If up, check `show ip bgp <prefix>` to see if route is in BGP table. If missing, neighbor isn't advertising it or policy is filtering. If present but not in `show ip route`, check best path selection (might be losing to another route) or NEXT_HOP reachability (IGP must have route to NEXT_HOP). For iBGP, check for split-horizon—routes from iBGP aren't sent to other iBGP peers without route reflector."

---

## Issue 4: "Intermittent Connectivity"

### Hypothesis Tree

```
Intermittent Connectivity
│
├─ Link Flapping
│  ├─ Physical cable issue
│  ├─ Duplex mismatch
│  └─ Bad optic/transceiver
│
├─ Route Flapping
│  ├─ BGP session bouncing
│  ├─ Route dampening
│  └─ Routing loop
│
├─ ARP/MAC Flapping
│  ├─ Duplicate IP
│  ├─ Spanning tree reconvergence
│  └─ VRRP/HSRP failover
│
├─ DNS Issues
│  ├─ Inconsistent DNS responses
│  └─ Negative caching
│
└─ Load Balancing
   ├─ Unhealthy backend in pool
   └─ Session persistence broken
```

### Diagnostic Commands

#### Pattern Detection
```bash
# How often does it fail?
# Run continuous ping and log failures
ping <destination> | while read line; do echo "$(date): $line"; done | tee ping.log

# Continuous reachability test
while true; do nc -vz <ip> <port>; sleep 5; done

# Monitor interface status
watch -n 1 'ip link show <interface>'
```

#### Interface Health
```bash
# Check for errors/drops
ip -s link show <interface>

# Expected: Low/zero errors, drops, overruns

# Check link status over time
ethtool <interface>

# Duplex mismatch?
ethtool <interface> | grep -i duplex
```

#### Routing Stability
```bash
# BGP session history
show ip bgp summary
# Check "Up/Down" time - should be stable

# Route changes over time
show ip bgp | grep <prefix>
# Run periodically, check if NEXT_HOP changes

# Logging
show log | grep BGP
# Look for "session down" messages
```

#### ARP Stability
```bash
# Monitor ARP cache
watch -n 1 'ip neigh show <gateway-ip>'

# Look for MAC address changing (bad!)

# Check for duplicate IPs
arping -D -I <interface> <ip>
```

### 90-Second Answer Template

> "Intermittent issues need pattern detection first. I'd run continuous ping with timestamps to see if failures are periodic (load-related) or random (flapping). Check interface with `ip -s link` for errors/drops. Check routing stability with `show ip bgp summary` uptime and logs for session bouncing. Check ARP cache with `watch ip neigh` to see if gateway MAC is flapping (duplicate IP or L2 issue). For services, test health check endpoints to see if backend is intermittently failing. Pattern tells you where to look."

---

## Issue 5: "Service Works from Some Hosts, Not Others"

### Hypothesis Tree

```
Works from Some, Not Others
│
├─ Routing Asymmetry
│  ├─ Different paths inbound/outbound
│  └─ Stateful firewall/NAT on only one path
│
├─ Firewall Rule Per-Source
│  ├─ Source IP-based ACL
│  ├─ Security group rules
│  └─ GeoIP blocking
│
├─ MTU/MSS Issue
│  ├─ PMTU discovery broken
│  └─ Different paths have different MTU
│
├─ Load Balancer
│  ├─ Source IP hashing
│  ├─ Some backends healthy, others not
│  └─ Session persistence to dead backend
│
└─ DNS Split-Brain
   ├─ Internal vs external DNS
   └─ Different A records per resolver
```

### Diagnostic Commands

#### Path Comparison
```bash
# From working host
traceroute <service-ip>
ip r get <service-ip>

# From failing host
traceroute <service-ip>
ip r get <service-ip>

# Compare: Are paths different?
```

#### MTU Discovery
```bash
# Test different packet sizes (DF=Don't Fragment)
# Working host:
ping -c 2 -M do -s 1472 <service-ip>  # 1472 + 28 = 1500 MTU

# Failing host:
ping -c 2 -M do -s 1472 <service-ip>

# If fails, try smaller:
ping -c 2 -M do -s 1400 <service-ip>

# Find exact PMTU
tracepath <service-ip>
```

#### Source IP Matters?
```bash
# From failing host, capture traffic
sudo tcpdump -i any host <service-ip> -nn

# Look for:
# - RST after SYN (firewall rejecting)
# - No response after SYN (firewall dropping)
# - Asymmetric path (reply from different IP)

# Test from different source IPs if available
curl --interface <alt-interface> https://service.example.com
```

#### DNS Consistency
```bash
# From working host
dig service.example.com

# From failing host
dig service.example.com

# Are A records the same? Different DNS servers?
```

### 90-Second Answer Template

> "This screams routing asymmetry or source-based policy. I'd compare `traceroute` from both hosts—different paths could mean stateful firewall on one path only. Check DNS with `dig` from both—might be split-horizon returning different IPs. Test MTU with `ping -M do -s 1472`—PMTU black hole would break some hosts but not others. Capture with `tcpdump` from failing host to see if packets even reach service. If service-side, check firewall rules for source IP restrictions or load balancer session persistence pinning to dead backend."

---

## Quick Decision Tree

```
Problem?
│
├─ Can't resolve name? → DNS (dig, getent hosts)
├─ Can't reach IP? → Routing/L3 (ping, traceroute, ip r)
├─ Port closed? → Firewall/Service (nc, ss -tlnp, iptables)
├─ Slow? → TCP/Loss (ss -ti, mtr, tcpdump)
├─ Intermittent? → Flapping (watch, logs, continuous tests)
└─ Works sometimes/somewhere? → Asymmetry/Policy (compare paths, tcpdump)
```

---

## The 5-Command Triage (First 60 Seconds)

```bash
1. ip a                    # Do I have an IP? Interfaces up?
2. ip r                    # Do I have routes? Default gateway?
3. ping -c 2 <gateway>     # Can I reach my gateway?
4. ping -c 2 8.8.8.8       # Can I reach Internet?
5. dig example.com         # Does DNS work?
```

These 5 commands tell you:
- Network config correct? (1-2)
- Local network works? (3)
- External routing works? (4)
- DNS works? (5)

**From there, you know which hypothesis tree to use.**

---

**Next:** Practice running through these trees on live problems. Time yourself. Aim for 90-second verbal explanation + 2-3 commands to prove/disprove hypothesis.
