# BGP Deep Dive - Interview Ready

## 90-Second Answer: What is BGP?

BGP (Border Gateway Protocol) is the **inter-domain routing protocol of the Internet**. It:
1. **Exchanges reachability** - advertises IP prefixes between Autonomous Systems (AS)
2. **Uses policy** - not just shortest path, but business relationships and traffic engineering
3. **Runs over TCP** - port 179, maintains persistent sessions
4. **Scales massively** - handles 900K+ routes on the Internet

Used for: Internet routing, data center fabrics, multi-homing, traffic engineering.

---

## BGP Fundamentals

### Path-Vector Protocol
- Unlike link-state (OSPF) or distance-vector (RIP), BGP is **path-vector**
- Each route includes the full AS path
- Loop prevention: reject routes with your own AS in the path

### eBGP vs iBGP

| Type | eBGP | iBGP |
|------|------|------|
| **Between** | Different AS | Same AS |
| **TTL** | 1 (direct neighbors) | 255 (can be multi-hop) |
| **AS_PATH** | Adds own AS | Doesn't modify AS_PATH |
| **Next-hop** | Changes to self | Preserves (usually) |
| **Use Case** | Internet peering | Internal route distribution |

**Key rule:** iBGP speakers must be fully meshed or use route reflectors.

---

## BGP Message Types

### 1. OPEN
- Establishes BGP session
- Negotiates hold time, BGP version, AS number
- Capabilities exchange

### 2. UPDATE
- Advertises new routes (NLRI + attributes)
- Withdraws routes
- Most important message type

### 3. KEEPALIVE
- Maintains session
- Default: every 60 seconds (hold time = 180s)

### 4. NOTIFICATION
- Error condition or session close
- Terminates session after sending

---

## BGP Attributes (The Policy Knobs)

### Well-Known Mandatory
Must be present in every UPDATE:

1. **ORIGIN**
   - IGP (i): Network statement or redistribution from IGP
   - EGP (e): Learned from EGP (obsolete)
   - INCOMPLETE (?): Redistributed from another source
   - **Preference**: IGP > EGP > INCOMPLETE

2. **AS_PATH**
   - List of ASes the route has traversed
   - **Loop prevention**: Reject if own AS in path
   - **Preference**: Shorter is better
   - **Traffic engineering**: AS_PATH prepending (add your AS multiple times to make path less attractive)

3. **NEXT_HOP**
   - IP address of next hop router
   - Critical for routing to work
   - Often needs to be changed by iBGP or at network boundaries

### Well-Known Discretionary

4. **LOCAL_PREF** (iBGP only)
   - **Local** to AS (not sent to eBGP peers)
   - Higher is better (default = 100)
   - **Use**: Influence outbound traffic (which exit point to use)

### Optional Transitive

5. **COMMUNITY**
   - Tag routes for policy grouping
   - Format: AS:value (e.g., 65001:100)
   - Common: no-export, no-advertise
   - **Use**: Signal policy intentions

### Optional Non-Transitive

6. **MED (Multi-Exit Discriminator)**
   - Suggests to neighbor which entry point to use
   - Lower is better
   - Only compared between routes from **same neighboring AS**
   - **Use**: Influence inbound traffic

---

## BGP Best Path Selection (The Algorithm)

**Critical for interviews:** Know this order by heart.

1. **Highest Weight** (Cisco-only, local to router)
2. **Highest LOCAL_PREF** (default 100)
3. **Locally originated** (network statement or aggregate)
4. **Shortest AS_PATH**
5. **Lowest ORIGIN** (IGP < EGP < INCOMPLETE)
6. **Lowest MED** (if from same neighbor AS)
7. **eBGP over iBGP**
8. **Lowest IGP metric** to NEXT_HOP
9. **Lowest BGP router ID**

**Memory aid:** "We Love Oranges AS Oranges Mean Pure Refreshment"

**Source:** [Cisco BGP Best Path](https://www.cisco.com/c/en/us/support/docs/ip/border-gateway-protocol-bgp/13753-25.html)

---

## BGP Commands (FRRouting)

### Session Status
```bash
# Enter FRR shell
docker exec -it <router-name> vtysh

# BGP summary
show ip bgp summary
# Shows: Neighbor, AS, MsgRcvd, MsgSent, State/PfxRcd

# BGP table
show ip bgp
# Shows: Network, Next Hop, Metric, LocPrf, Weight, Path

# Specific prefix
show ip bgp 10.0.0.0/8

# IPv6
show bgp ipv6 unicast summary
```

### Route Details
```bash
# Best path reasoning
show ip bgp 192.0.2.0/24
# Shows why this path was chosen

# All paths for prefix
show ip bgp 192.0.2.0/24 longer-prefixes

# Routing table (what's installed)
show ip route
show ip route bgp
```

### Configuration
```bash
# View running config
show running-config
show running-config | section bgp

# Static view (from file)
show configuration
```

### Debugging
```bash
# Enable debugging (use sparingly)
debug bgp updates
debug bgp keepalives

# Clear session (force reconnect)
clear ip bgp * soft
clear ip bgp <neighbor-ip>

# Statistics
show ip bgp neighbors <ip>
# Shows: Session state, timers, capabilities, counters
```

---

## BGP Traffic Engineering

### Outbound Traffic (Control What You Send)
Use **LOCAL_PREF** (iBGP):
```
router bgp 65001
  neighbor 10.0.0.1 remote-as 65002
  !
  route-map PREFER_ISP1 permit 10
    set local-preference 200
  !
  neighbor 10.0.0.1 route-map PREFER_ISP1 in
```

Higher LOCAL_PREF = preferred exit.

### Inbound Traffic (Influence What Others Send You)
Use **AS_PATH prepending**:
```
route-map DEPREF_PATH permit 10
  set as-path prepend 65001 65001 65001
!
neighbor 10.0.0.2 route-map DEPREF_PATH out
```

Longer AS_PATH = less attractive to neighbors.

Use **MED** (less reliable, only works with specific neighbor):
```
route-map SET_MED permit 10
  set metric 100
!
neighbor 10.0.0.2 route-map SET_MED out
```

Lower MED = more preferred by neighbor.

---

## Common BGP Issues

### Issue 1: Session Won't Establish
**Symptoms:** State stuck in ACTIVE or CONNECT  
**Causes:**
- TCP 179 blocked (firewall)
- Wrong neighbor IP or AS number
- TTL issue (eBGP neighbors not directly connected, need `ebgp-multihop`)

**Debug:**
```bash
show ip bgp summary              # Check state
show ip bgp neighbors <ip>       # Detailed session info
ping <neighbor-ip>               # Basic reachability
tcpdump -i any tcp port 179      # Packet capture
```

### Issue 2: Routes Not Propagating
**Symptoms:** Neighbor shows prefixes received, but not in routing table  
**Causes:**
- Failed best path selection (another path is better)
- Route policy filtering it
- NEXT_HOP not reachable
- iBGP split-horizon (need route reflector or full mesh)

**Debug:**
```bash
show ip bgp <prefix>             # Check all paths
show ip route <prefix>           # Is it installed?
show ip bgp neighbors <ip> routes  # What did neighbor advertise?
show running-config | section route-map  # Check policies
```

### Issue 3: Flapping Sessions
**Symptoms:** Session up/down repeatedly  
**Causes:**
- Link instability
- Hold timer too aggressive
- CPU overload on router
- BGP dampening kicking in

**Debug:**
```bash
show ip bgp summary              # Check uptime
show ip bgp dampening dampened-paths  # Is dampening active?
show log                         # Check for NOTIFICATION messages
```

### Issue 4: Suboptimal Routing
**Symptoms:** Traffic taking longer path  
**Causes:**
- LOCAL_PREF not set correctly
- AS_PATH artificially lengthened by upstream
- Hot-potato routing (IGP metric to NEXT_HOP)

**Debug:**
```bash
show ip bgp <prefix>             # Check attributes of all paths
show ip bgp regexp <pattern>     # Filter by AS_PATH
traceroute <destination>         # Verify actual path
```

---

## BGP vs OSPF (Interview Comparison)

| Feature | BGP | OSPF |
|---------|-----|------|
| **Type** | Path-vector, EGP | Link-state, IGP |
| **Scope** | Inter-domain | Intra-domain |
| **Metric** | Policy-based (attributes) | Cost (bandwidth-based) |
| **Convergence** | Slow (minutes) | Fast (sub-second to seconds) |
| **Scalability** | Massive (Internet-scale) | Limited (areas needed beyond ~100 routers) |
| **Algorithm** | Best path selection (policy) | Dijkstra (SPF) |
| **Loop Prevention** | AS_PATH | SPF algorithm inherently loop-free |
| **Redistribution** | Manual, policy-heavy | Simpler, metric translation |
| **Use Cases** | ISP, multi-homing, DC fabrics | Enterprise campus, DC underlay |

**Key point:** BGP is about **policy and business relationships**, OSPF is about **shortest path and fast convergence**.

---

## BGP in Data Centers

### Traditional vs Modern

**Traditional:**
- OSPF/IS-IS for underlay
- BGP for overlay (external connectivity)

**Modern (BGP Everywhere / RFC 7938):**
- BGP for underlay AND overlay
- eBGP between every hop (each switch = different AS)
- **Benefits:**
  - Simple, uniform protocol
  - Better traffic engineering
  - Multi-pathing (ECMP) easier
  - Vendor-neutral

**Example AS Numbering:**
- Spine switches: AS 65000-65099
- Leaf switches: AS 65100-65199
- Each leaf gets unique AS for eBGP peering

---

## Meta NPE Interview Questions

### Q1: Explain BGP's role in the Internet
**A:** BGP is the glue of the Internet. Each organization (AS) uses BGP to advertise their IP prefixes to neighbors. BGP exchanges paths (not just metrics), allowing policy-based routing. When you access a website, BGP determines which of the thousands of possible paths your packets take, based on business relationships (customer/provider/peer).

### Q2: How would you influence inbound traffic from peers?
**A:** Three main levers:
1. **AS_PATH prepending** - Make path look longer (works with everyone, but crude)
2. **MED** - Suggest preferred entry point (only works with specific neighbor, often ignored)
3. **Communities** - Signal intentions to cooperative peers (requires agreement)

Most reliable: AS_PATH prepending, but it affects everyone. Best: Negotiate with peer and use communities for fine-grained control.

### Q3: BGP session is established but routes aren't in the routing table. Why?
**A:** Check:
1. **Best path selection** - Another route might be better (check `show ip bgp <prefix>`)
2. **NEXT_HOP unreachable** - IGP must have route to NEXT_HOP
3. **Route policy** - Import filter might be dropping it
4. **iBGP split-horizon** - Routes learned from iBGP not sent to other iBGP peers (need RR)
5. **Admin distance** - BGP AD is 20 (eBGP) or 200 (iBGP); might be overridden

Use `show ip bgp` to see BGP table vs `show ip route` for RIB.

### Q4: Design a dual-ISP setup for high availability and traffic engineering
**A:**
- **Addressing**: Get provider-independent (PI) IP space or use provider-assigned (PA) per ISP
- **AS Number**: Get public AS or use private AS (64512-65535)
- **Outbound control**: Use LOCAL_PREF (higher for preferred ISP)
- **Inbound control**: 
  - Announce full prefix to preferred ISP
  - Prepend AS_PATH to backup ISP (or announce more-specific to preferred, less-specific to backup)
- **Monitoring**: Track reachability to both ISPs, adjust policies dynamically
- **Failover**: Default route tracking + BGP session monitoring

### Q5: What's BGP dampening and when do you use it?
**A:** BGP dampening suppresses flapping routes to improve stability. When a route flaps (withdraw/announce), it accumulates a penalty. Once penalty > suppress threshold, the route is dampened (not advertised). Penalty decays over time.

**Use case**: Protect against misbehaving peers or unstable links causing route instability.

**Warning**: Can cause reachability issues if too aggressive. Many networks disable it for customer routes, only apply to peers/transit.

---

## Lab Exercises

### Exercise 1: Basic eBGP Peering
1. Start peering-lab
2. Examine configs: `show running-config`
3. Verify session: `show ip bgp summary`
4. Check learned routes: `show ip bgp`
5. Trace a packet: `traceroute <destination>`

### Exercise 2: Manipulate Path Selection
1. Check current best path: `show ip bgp <prefix>`
2. Change LOCAL_PREF on one router
3. Verify path changed: `show ip bgp <prefix>`
4. Test with `traceroute`

### Exercise 3: AS_PATH Prepending
1. Configure AS_PATH prepending on outbound route-map
2. Check from neighbor: `show ip bgp <prefix>`
3. Verify AS_PATH is longer
4. Remove prepending, verify return to normal

### Exercise 4: Break and Fix
1. Shut down BGP session: `clear ip bgp <neighbor>`
2. Observe: `show ip bgp summary`
3. Check log: `show log`
4. Bring back up, verify convergence time

---

## Quick Reference Card

```bash
# Session health
show ip bgp summary
show ip bgp neighbors <ip>

# Routing table
show ip bgp
show ip bgp <prefix>
show ip route bgp

# Traffic engineering
show ip bgp neighbors <ip> advertised-routes  # What you send
show ip bgp neighbors <ip> routes             # What you receive

# Debugging
debug bgp updates
debug bgp keepalives
clear ip bgp * soft
show log

# Configuration
show running-config | section bgp
show ip bgp regexp <regex>  # Filter by AS_PATH

# IPv6
show bgp ipv6 unicast summary
show bgp ipv6 unicast
```

---

**Next:** Practice on peering-lab, manipulate attributes, observe path changes, understand why routes are chosen.
