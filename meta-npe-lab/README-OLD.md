# Meta NPE Networking Labs - Complete Guide

## START HERE

### Step 1: Start the Lab (One Command)

```bash
cd /Users/landigf/Desktop/Code/LANdi-container/Meta-prep && docker-compose up -d
```

### Step 2: Connect to a Container

```bash
docker exec -it clab-frr01-PC1 sh
```

### Step 3: Run These Commands (Inside Container)

```bash
ip a
ip r
ping -c 2 10.0.0.11
ip neigh
exit
```

### Step 4: Stop the Lab When Done

```bash
bash ~/Desktop/Code/LANdi-container/Meta-prep/scripts/stop-lab.sh
```

---

## That's It!

You now have real networking experience. 

**Next:** Read the notes below to understand what you just did.

---

## Learning Path

1. ✅ Run the lab (you just did this)
2. 📖 Read: [notes/tcp-deep-dive.md](notes/tcp-deep-dive.md)
3. 📖 Read: [notes/bgp-deep-dive.md](notes/bgp-deep-dive.md)
4. 📖 Read: [notes/protocol-comparisons.md](notes/protocol-comparisons.md)
5. 📖 Read: [notes/hypothesis-trees.md](notes/hypothesis-trees.md)

---

## Troubleshooting

**Lab won't start?**
```bash
# Clean everything
docker rm -f $(docker ps -aq)
docker network prune -f
# Try again
bash ~/Desktop/Code/LANdi-container/Meta-prep/scripts/start-lab-fixed.sh
```

**Docker not running?**
```bash
open -a Docker
# Wait 30 seconds, then try again
```

---

**This is your complete guide. Everything you need is here.**

### Basic Network State
```bash
ip a                    # Show interfaces and IPs
ip r                    # Show routing table
ip neigh                # Show ARP cache
ss -tuna                # Show all sockets
ping -c 2 <ip>          # Test connectivity
traceroute <ip>         # Show path to destination
```

### DNS
```bash
dig example.com         # DNS lookup
getent hosts <name>     # System resolver
```

### Packet Capture
```bash
tcpdump -i any host <ip>              # Capture traffic
tcpdump -i any tcp and port 80        # HTTP traffic
```

### BGP (Inside Router Containers)
```bash
docker exec -it clab-frr01-R1 vtysh   # Connect to router
show ip bgp summary                    # BGP peers
show ip bgp                            # BGP routes
show ip route                          # Routing table
```

---

## Interview Prep - 90-Second Answers

### Packet Flow
1. DNS resolves name to IP
2. Host checks route table (local or gateway)
3. ARP resolves next-hop MAC
4. Switch forwards by MAC, router by IP (TTL decremented)
5. Return path may differ

### TCP vs UDP
- **TCP**: Connection-oriented, reliable, ordered, flow/congestion control. Use for: HTTP, SSH, databases
- **UDP**: Connectionless, best-effort, no guarantees. Use for: DNS, streaming, gaming, QUIC

### BGP vs OSPF
- **BGP**: Inter-domain, policy-based, slow convergence, Internet-scale
- **OSPF**: Intra-domain, shortest path, fast convergence, link-state

### TCP Performance Issues
- Check `ss -ti` for retransmissions, cwnd, RTT
- Use `mtr` to find packet loss
- Packet loss → retransmits → cwnd drops → throughput tanks

---

## Notes Directory

- [tcp-deep-dive.md](notes/tcp-deep-dive.md) - TCP internals and troubleshooting
- [bgp-deep-dive.md](notes/bgp-deep-dive.md) - BGP path selection and commands  
- [protocol-comparisons.md](notes/protocol-comparisons.md) - TCP/UDP, BGP/OSPF, IPv4/IPv6
- [hypothesis-trees.md](notes/hypothesis-trees.md) - Systematic debugging framework
- [command-cheatsheet.md](notes/command-cheatsheet.md) - Quick command reference

---

## Success Criteria (After 1 Day)

- ✅ Explain packet flow from application to wire
- ✅ Run 5-command network triage in 60 seconds
- ✅ Explain TCP handshake and congestion control
- ✅ Debug slow connections with ss, mtr, tcpdump
- ✅ Explain BGP path selection (top 4 criteria)
- ✅ Compare protocols fluently (TCP/UDP, BGP/OSPF)
- ✅ Diagnose "can't reach service" systematically
- ✅ Have screenshots/outputs as portfolio evidence

---

### Block A (30 min): Bring Up Two Labs

**Lab 1: FRR OSPF Ring**
```bash
cd ../containerlab/lab-examples/frr01
bash run.sh
```

**Lab 2: BGP Peering Lab**
```bash
cd ../peering-lab
# Follow that lab's instructions
containerlab deploy -t peering.clab.yml
```

**Why these labs:**
- `frr01`: 3 FRR routers in a ring + PC per router ([FRR Lab](https://containerlab.dev/lab-examples/frr01/))
- `peering-lab`: Basic BGP configuration with mounted configs ([Peering Lab](https://containerlab.dev/lab-examples/peering-lab/))

---

### Block B (60 min): Packet Flow + ARP + Subnetting

**Your Default Story Commands:**
```bash
# Get into a PC node from frr01 lab
docker exec -it <pc-container-name> bash

# Core commands
ip a              # What interfaces and IPs do I have?
ip r              # What's my routing table?
ping -c 2 <peer-ip>   # Can I reach the peer?
ip neigh          # What's in my ARP cache?
traceroute <remote-ip>  # What path does traffic take?
```

**90-Second Interview Answer (Packet Flow):**
1. **DNS** resolves name to IP (if using a name)
2. **Host checks route table** → local subnet or via gateway?
3. **ARP/ND** resolves next-hop MAC
4. **Switch** forwards by MAC, **router** forwards by IP, TTL decremented
5. **Return path may differ** (routing is per-direction)

**What to internalize:**
- Local vs remote decision: `ip r` shows default gateway
- ARP is for next-hop MAC: `ip neigh` fills when you talk to a next hop
- Router rewrites L2 each hop: traceroute increments TTL; routers decrement

---

### Block C (45 min): TCP Fundamentals + Troubleshooting

**TCP Deep Dive Commands:**
```bash
# From any PC, test HTTP connection
curl -v http://example.com

# Socket state
ss -tuna          # All TCP/UDP sockets
ss -ti            # TCP info (cwnd, RTT, retrans)

# Packet capture
sudo tcpdump -i any tcp and host example.com
```

**What you must know:**
- **Handshake**: SYN → SYN-ACK → ACK
- **Flow control** (rwnd) vs **congestion control** (cwnd)
- **Loss** → retransmits → cwnd drops → throughput collapses

**Meta-Style "Under Time Pressure" Triage:**
1. Name resolution? `dig`, `getent hosts`
2. Routing? `ip r`, `traceroute/mtr`
3. Port open? `nc -vz host 443`
4. TCP symptoms? `ss -ti`
5. Truth? `tcpdump`

---

### Block D (45 min): Inject Packet Loss and Watch TCP Behavior

**Chaos Engineering for TCP:**
```bash
# Find interface name
ip link

# Add 3% loss + 50ms delay
sudo tc qdisc add dev eth1 root netem loss 3% delay 50ms

# Run download / repeated curl
curl -o /dev/null -s -w "%{time_total}\n" http://example.com

# Observe retrans/RTT/cwnd
ss -ti

# Remove impairment
sudo tc qdisc del dev eth1 root
```

**Interview Point:**
> "Even small loss can destroy throughput because TCP treats loss as congestion; you'll see retransmits and rising tail latency."

---

### Block E (60-90 min): BGP In Depth

**BGP Commands (from peering-lab FRR containers):**
```bash
docker exec -it <bgp-router-name> vtysh

# Inside vtysh
show ip bgp summary    # Peer status, prefixes received
show ip bgp            # BGP table with paths and attributes
show ip route          # What's actually installed in RIB?
show running-config    # BGP configuration
```

**90-Second BGP Answer:**
> "BGP is inter-domain routing. Routers form TCP sessions, exchange reachability for prefixes, attach attributes (LOCAL_PREF, AS_PATH, MED, etc.), and choose a best path based on policy. That's how large networks scale and do traffic engineering."

**BGP Best Path Selection** (Cisco's canonical order):
1. Highest LOCAL_PREF
2. Shortest AS_PATH
3. Lowest ORIGIN (IGP < EGP < INCOMPLETE)
4. Lowest MED (if same neighbor AS)
5. eBGP over iBGP
6. Lowest IGP metric to next hop
7. Lowest router ID

**Protocol Comparisons You'll Be Asked:**

**BGP vs OSPF:**
| Aspect | OSPF | BGP |
|--------|------|-----|
| **Scope** | Internal (IGP) | External/Policy (EGP) |
| **Algorithm** | Link-state, Dijkstra | Path-vector, policy-based |
| **Convergence** | Fast (seconds) | Slower (minutes) |
| **Metric** | Cost (bandwidth-based) | Policy attributes |
| **Use Case** | Intra-domain routing | Inter-domain, traffic engineering |

**TCP vs UDP:**
| Aspect | TCP | UDP |
|--------|-----|-----|
| **Reliability** | Guaranteed delivery, ordering | Best-effort, no guarantees |
| **Connection** | Connection-oriented | Connectionless |
| **Overhead** | Higher (ack, retrans, flow/congestion control) | Lower (minimal header) |
| **Use Cases** | HTTP, SSH, databases | DNS, streaming, gaming, QUIC |

---

### Block F (30 min): Linux Host Troubleshooting Under Time Pressure

**Commands You Need Cold:**

**State:**
```bash
ip a              # Interfaces and addresses
ip r              # Routing table
ip neigh          # ARP/ND cache
ss -tuna          # Socket state
```

**Name Resolution:**
```bash
dig <name>                  # Query DNS
getent hosts <name>         # Use system resolver
cat /etc/hosts              # Local overrides
cat /etc/resolv.conf        # DNS servers
```

**Path:**
```bash
ping -c 2 <ip>              # Basic reachability
traceroute <ip>             # Path trace
mtr -rw <ip>                # Better traceroute
```

**Packets:**
```bash
sudo tcpdump -i any host <ip>  # Packet capture
```

**Resource Triage:**
```bash
top                         # CPU/memory
free -h                     # Memory usage
df -h                       # Disk space
dmesg | tail                # Kernel messages
journalctl -xe --no-pager | tail  # System logs
```

---

## 🔬 Bonus: DHCP, NAT, IPv6 (Micro-Drills)

### DHCP/DHCPv6 (Quick Lab)
```bash
# Use dnsmasq container for DHCP lab
docker run -d --name dhcp-server netgab/dnsmasq-dhcp
```

**Talk Track:**
- **DHCP DORA**: Discover/Offer/Request/Ack
- **Broadcast domain limitation**: relay needed across routers
- **Hands out**: IP, subnet mask, default gateway, DNS

### NAT (Conceptual)
**Types:**
- **SNAT/Masquerade**: Many private IPs → one public IP (outbound)
- **DNAT/Port-forward**: Public IP:port → private IP:port (inbound)

**Failure Modes:**
- State table exhaustion
- Timeout issues
- Asymmetric routing breaks stateful NAT

### IPv4 vs IPv6
**Key Differences:**
- IPv4: 32-bit, NAT required for scaling, ARP for neighbor discovery
- IPv6: 128-bit, eliminates NAT need, uses Neighbor Discovery (ICMPv6)
- **Transition**: Dual-stack (not a flag day)
- **Security note**: Don't blindly block ICMPv6 (breaks ND)

---

## 🎓 Interview Question Templates

### Packet Flow Question
**Q:** "User reports they can't reach service X. Walk me through your debugging."

**A (90 sec):**
1. Check local connectivity: `ip a`, `ip r`
2. Name resolution: `dig service.example.com`
3. Reachability: `ping`, `traceroute`
4. Port/service: `nc -vz <ip> <port>`
5. TCP state: `ss -ti`
6. Packet truth: `tcpdump`

### TCP Performance Question
**Q:** "Downloads are slow but ping times are fine. What could it be?"

**A (90 sec):**
- Packet loss triggers TCP retransmissions → cwnd drops → throughput tanks
- Check: `ss -ti` for retrans count, RTT variance
- Capture with `tcpdump` to see duplicate ACKs
- Could be: link loss, MTU issues, buffer bloat, congestion

### BGP Question
**Q:** "Two ISP links, but all traffic goes through one. Why?"

**A (90 sec):**
- BGP best path selection based on attributes
- Check `show ip bgp` for:
  - LOCAL_PREF (higher wins)
  - AS_PATH length (shorter wins)
  - MED values
- Solution: Adjust LOCAL_PREF or AS_PATH prepending for traffic engineering

---

## 📁 Repo Structure

```
meta-npe-network-labs/
├── README.md              # This file
├── labs/                  # Lab topologies and configs
│   ├── frr01/            # OSPF ring lab
│   └── peering-lab/      # BGP peering lab
├── notes/                 # Your distilled explanations
│   ├── tcp-deep-dive.md
│   ├── bgp-deep-dive.md
│   ├── protocol-comparisons.md
│   └── hypothesis-trees.md
├── screenshots/           # Evidence of hands-on work
│   ├── bgp-summary.png
│   ├── ip-neigh.png
│   └── tcpdump-capture.png
└── scripts/               # Helper scripts
    └── setup-env.sh       # Environment verification
```

---

## 🚀 Your Next Action (No Ambiguity)

1. **Start the FRR01 lab:**
```bash
cd ../containerlab/lab-examples/frr01
bash run.sh
```

2. **Get into a PC container:**
```bash
docker ps  # Find PC container names
docker exec -it <pc-container-name> bash
```

3. **Run these 5 commands:**
```bash
ip a
ip r
ping -c 2 <gateway-ip>
ip neigh
traceroute <remote-ip>
```

4. **Paste outputs here** (or take screenshots)

I'll:
- Explain what each line means (Meta-style)
- Ask you 5 interview questions based on YOUR output
- Force you into 90-second answers, then tighten them

---

## 📚 Resources

- [Containerlab](https://containerlab.dev/)
- [BGP Labs](https://bgplabs.net/1-setup/)
- [FRRouting Docs](https://docs.frrouting.org/en/latest/bgp.html)
- [Cisco BGP Best Path](https://www.cisco.com/c/en/us/support/docs/ip/border-gateway-protocol-bgp/13753-25.html)

---

## 🎯 Success Criteria

After 1 day, you should be able to:
- ✅ Explain packet flow from application to wire
- ✅ Diagnose TCP performance issues with 3-4 commands
- ✅ Explain BGP path selection and traffic engineering
- ✅ Compare TCP/UDP and BGP/OSPF fluently
- ✅ Triage a Linux host network issue under time pressure

**This is your portfolio artifact: labs + debugging + operational reasoning.**
