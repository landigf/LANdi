# Protocol Comparisons - Interview Ready

Quick-reference guide for comparing networking protocols commonly asked in Meta NPE interviews.

---

## TCP vs UDP

### Core Differences

| Feature | TCP | UDP |
|---------|-----|-----|
| **Connection Model** | Connection-oriented (handshake required) | Connectionless (fire and forget) |
| **Reliability** | Guaranteed delivery via ACKs + retransmission | Best-effort, no guarantees |
| **Ordering** | In-order delivery enforced | Unordered (app must handle) |
| **Flow Control** | Yes (receiver window - rwnd) | No |
| **Congestion Control** | Yes (congestion window - cwnd) | No |
| **Header Size** | 20-60 bytes (variable) | 8 bytes (fixed) |
| **Error Checking** | Checksum + sequence numbers | Checksum only |
| **Speed** | Slower (overhead from reliability) | Faster (minimal overhead) |
| **Broadcast/Multicast** | No | Yes |

### When to Use What

**Use TCP when:**
- Reliability is critical (file transfer, databases, web pages)
- Order matters (chat messages, API calls)
- Connection state is useful (authentication, sessions)
- Examples: HTTP/HTTPS, SSH, FTP, SMTP, database connections

**Use UDP when:**
- Speed > reliability (real-time applications)
- Low latency critical (gaming, VoIP)
- Loss tolerance is acceptable (video streaming)
- Broadcast/multicast needed (DHCP, mDNS)
- Custom reliability layer (QUIC, WebRTC)
- Examples: DNS, DHCP, VoIP, online gaming, video conferencing, QUIC

### Interview Talking Points

**Q: Why does video streaming use UDP?**  
**A:** Slight packet loss (pixelation) is better than retransmission delay (buffering). Real-time video needs low latency more than perfect reliability. Apps use buffering and forward error correction to smooth out loss.

**Q: Why does DNS use UDP?**  
**A:** Most DNS queries/responses fit in one packet. UDP avoids 3-way handshake overhead. If response is too large (>512 bytes traditionally, now EDNS allows larger), falls back to TCP.

**Q: What is QUIC?**  
**A:** Modern protocol built on UDP. Implements TCP-like reliability + TLS encryption + HTTP/2 multiplexing at transport layer. Benefits: faster connection setup (0-RTT), better loss handling (per-stream, not per-connection), and works better with NAT/firewalls. HTTP/3 uses QUIC.

---

## BGP vs OSPF

### Core Differences

| Feature | BGP | OSPF |
|---------|-----|------|
| **Type** | Path-vector, Exterior Gateway Protocol (EGP) | Link-state, Interior Gateway Protocol (IGP) |
| **Scope** | Inter-domain (between organizations/AS) | Intra-domain (within an organization) |
| **Protocol Base** | TCP (port 179) | IP protocol 89 (not TCP/UDP) |
| **Routing Decision** | Policy-based (attributes: LOCAL_PREF, AS_PATH, MED) | Shortest path (cost, typically bandwidth-based) |
| **Algorithm** | Best path selection (9+ step process) | Dijkstra's SPF algorithm |
| **Convergence** | Slow (minutes) - by design for stability | Fast (sub-second to seconds) |
| **Scalability** | Internet-scale (900K+ routes) | Limited (hierarchical areas needed >100 routers) |
| **Loop Prevention** | AS_PATH (reject if own AS in path) | SPF calculation (inherently loop-free) |
| **Metric Flexibility** | Highly flexible (policy knobs) | Single metric (cost) |
| **State** | Incremental updates, keeps best path only | Full topology database (LSDB), everyone has same view |
| **Neighbor Discovery** | Manual configuration | Automatic (Hello packets) |
| **Authentication** | MD5 or TCP AO | MD5, SHA, or none |

### When to Use What

**Use BGP when:**
- Routing between different organizations/autonomous systems
- Multi-homing to multiple ISPs
- Policy-based routing needed (traffic engineering)
- Need to influence inbound/outbound traffic paths
- Data center fabrics (modern "BGP everywhere" designs)
- Massive scale (hundreds of thousands of routes)

**Use OSPF when:**
- Routing within your network (campus, data center underlay)
- Fast convergence critical (sub-second failover)
- All routers under your control
- Straightforward shortest-path routing sufficient
- No complex policy needed

### Real-World Architecture

**Typical Enterprise/DC:**
```
Internet
   |
   | (eBGP - policy routing, multi-homing)
   |
Border Routers
   |
   | (OSPF - fast convergence, shortest path)
   |
Core/Distribution/Access
```

**Modern DC (BGP Everywhere):**
```
Spine Layer (AS 65000-65099)
   |  eBGP
   |
Leaf Layer (AS 65100-65199)
   |  eBGP
   |
Servers/ToRs
```

### Interview Talking Points

**Q: Why does the Internet use BGP, not OSPF?**  
**A:** Three reasons:
1. **Policy**: ISPs need business-driven routing (peering vs transit vs customer), not just shortest path
2. **Scale**: OSPF doesn't scale to millions of routes; link-state updates would overwhelm routers
3. **Administrative boundaries**: OSPF requires trust (shared topology database); BGP allows independent administration

**Q: Why would a data center use BGP instead of OSPF?**  
**A:** Modern DC uses "BGP everywhere" (RFC 7938):
- Simplicity: One protocol for everything
- Traffic engineering: Better ECMP and policy control
- Vendor-neutral: Works with any vendor
- Scalability: Handles large route tables better
- Isolation: Each hop is separate AS, failures don't flood

**Q: Can you run both BGP and OSPF together?**  
**A:** Yes, commonly done:
- OSPF for internal routing (underlay)
- BGP for external connectivity (eBGP to Internet)
- Or iBGP for overlay (VPNs, EVPN)
- Redistribution between them (with careful filtering)

---

## IPv4 vs IPv6

### Core Differences

| Feature | IPv4 | IPv6 |
|---------|------|------|
| **Address Size** | 32-bit (4.3 billion addresses) | 128-bit (340 undecillion addresses) |
| **Notation** | Dotted decimal (192.0.2.1) | Colon hex (2001:db8::1) |
| **Header Size** | 20-60 bytes (variable, with options) | 40 bytes (fixed, extensions separate) |
| **Fragmentation** | Routers can fragment | Only source can fragment (PMTU discovery required) |
| **Checksum** | Header checksum | No checksum (relies on link/transport layer) |
| **Address Config** | DHCP or manual | SLAAC, DHCPv6, or manual |
| **Neighbor Discovery** | ARP (broadcast) | NDP via ICMPv6 (multicast) |
| **Broadcast** | Yes | No (uses multicast) |
| **NAT** | Widespread (due to exhaustion) | Unnecessary (but exists) |
| **IPsec** | Optional | Designed-in (but optional in practice) |

### Address Notation Examples

**IPv4:**
```
10.0.0.1
192.168.1.0/24
172.16.0.0/12
```

**IPv6:**
```
2001:db8:85a3::8a2e:370:7334        # Full
2001:db8:85a3:0:0:8a2e:370:7334     # Expanded
2001:db8:85a3::8a2e:370:7334        # Compressed (:: once per address)
::1                                  # Loopback
fe80::1                              # Link-local
```

### IPv6 Address Types

| Type | Prefix | Scope |
|------|--------|-------|
| **Global Unicast** | 2000::/3 | Internet-routable |
| **Link-Local** | fe80::/10 | Single link (not routed) |
| **Unique Local** | fc00::/7 | Private (like RFC 1918) |
| **Multicast** | ff00::/8 | Group communication |
| **Loopback** | ::1/128 | Local host |

### Transition Mechanisms

1. **Dual Stack** (most common)
   - Run IPv4 and IPv6 simultaneously
   - Applications choose based on DNS response
   - Happy Eyeballs: Try IPv6 first, fallback to IPv4

2. **Tunneling**
   - 6in4: IPv6 over IPv4 tunnel
   - 6to4: Automatic tunneling
   - Teredo: NAT traversal for IPv6

3. **Translation**
   - NAT64: IPv6-only to IPv4-only communication
   - 464XLAT: IPv4 apps on IPv6-only networks

### Interview Talking Points

**Q: Why hasn't IPv6 fully replaced IPv4?**  
**A:** 
- **Chicken-and-egg**: Need content on IPv6 to motivate users, need users to motivate content
- **NAT workaround**: NAT "solved" address exhaustion (poorly, but good enough for many)
- **Legacy**: Billions of devices, networks, and configs designed for IPv4
- **Cost**: Migration requires hardware upgrades, testing, training
- **Progress**: ~40% of Internet traffic is IPv6 (Google stats), growing steadily

**Q: What's broken if you block ICMPv6?**  
**A:** Critical functions break:
- **Neighbor Discovery** (replaces ARP): Can't resolve link-layer addresses
- **Router Advertisements**: Hosts can't autoconfigure addresses (SLAAC)
- **Path MTU Discovery**: Can't determine max packet size, fragmentation fails
- **Unreachable/TooBig messages**: Black holes form

**Never blindly block ICMPv6.** Use rate limiting instead.

**Q: Is IPv6 more secure than IPv4?**  
**A:** Not inherently:
- IPsec designed-in, but optional (and available for IPv4 too)
- Larger address space makes scanning harder (but not impossible)
- NDP has security issues (like ARP spoofing) unless SEND/SeND used
- Same application-layer vulnerabilities
- **Real security**: Defense-in-depth (firewalls, IDS, encryption) regardless of IP version

---

## DHCP vs Static IP

### Core Differences

| Feature | DHCP | Static IP |
|---------|------|-----------|
| **Assignment** | Automatic | Manual |
| **Scalability** | High (centralized) | Low (per-device config) |
| **Flexibility** | Easy changes (update server) | Requires touching each device |
| **Conflict Risk** | Low (server tracks) | High (human error) |
| **Boot Time** | Slightly slower (DORA process) | Instant |
| **Mobility** | Seamless (new lease) | Requires reconfiguration |
| **Dependencies** | DHCP server availability | None |
| **Use Cases** | Workstations, BYOD, IoT | Servers, network devices, printers |

### DHCP Process (DORA)

1. **Discover**: Client broadcasts "I need an IP"
2. **Offer**: DHCP server(s) respond with offers
3. **Request**: Client chooses one, broadcasts acceptance
4. **Acknowledge**: Chosen server confirms, sends lease

**Parameters provided:**
- IP address
- Subnet mask
- Default gateway
- DNS servers
- Lease time
- (Optional) NTP, domain name, TFTP server, etc.

### Interview Talking Points

**Q: When should you use static vs DHCP?**  
**A:**
- **Static**: Servers (people/configs point to them), network devices (routers, switches), printers, security cameras - anything that needs predictable addressing
- **DHCP**: Workstations, laptops, phones, guest devices, IoT - anything that moves or changes frequently
- **Hybrid**: DHCP reservations - DHCP convenience with static-like predictability

**Q: How does DHCP work across subnets?**  
**A:** DHCP uses broadcast (destination 255.255.255.255), which doesn't cross routers. Solutions:
- **DHCP relay/helper**: Router listens for DHCP broadcasts, unicasts them to DHCP server
- **DHCP server per subnet**: Wasteful, hard to manage
- **Most common**: Relay/helper on layer 3 device

---

## NAT Types

### SNAT (Source NAT) / Masquerade

**Purpose**: Hide internal IPs behind single public IP (outbound)

```
Internal: 192.168.1.10:12345 → 8.8.8.8:53
          ↓ (NAT)
External: 203.0.113.1:54321 → 8.8.8.8:53

Response: 8.8.8.8:53 → 203.0.113.1:54321
          ↓ (NAT)
Internal: 8.8.8.8:53 → 192.168.1.10:12345
```

**Use case**: Home routers, enterprise Internet gateways

### DNAT (Destination NAT) / Port Forwarding

**Purpose**: Expose internal service to Internet (inbound)

```
Internet: 203.0.113.1:80 → <hits public IP>
          ↓ (DNAT)
Internal: 192.168.1.10:8080 ← <forwarded>
```

**Use case**: Hosting web server behind NAT, gaming

### Issues with NAT

1. **Breaks end-to-end principle**: Devices can't directly connect
2. **State table exhaustion**: Limited number of concurrent connections
3. **Timeouts**: Idle connections dropped (especially problematic for long-lived TCP)
4. **Asymmetric routing**: Traffic must return through same NAT
5. **Protocol breaks**: Some protocols embed IPs in payload (FTP, SIP, H.323)
6. **P2P difficulty**: Requires STUN/TURN/ICE for NAT traversal

### Interview Talking Points

**Q: Why does IPv6 reduce the need for NAT?**  
**A:** Address abundance. NAT was primarily an address exhaustion workaround, not a security feature. With IPv6, every device can have a global address. Security comes from stateful firewalls, not NAT obscurity.

**Q: How do applications work through NAT?**  
**A:** Techniques:
- **UPnP/NAT-PMP**: Automatic port mapping (gaming consoles, IoT)
- **STUN**: Discover public IP and port (VoIP, WebRTC)
- **TURN**: Relay server when direct P2P fails
- **ICE**: Framework combining STUN/TURN (WebRTC standard)
- **ALG (Application Layer Gateway)**: NAT device inspects payload and rewrites embedded IPs (FTP, SIP)

---

## Quick Comparison Matrix

### By Use Case

| Scenario | Protocol Choice |
|----------|----------------|
| **Web browsing** | TCP (HTTP/1.1, HTTP/2), QUIC/UDP (HTTP/3) |
| **File transfer** | TCP (FTP, SCP, SMB) |
| **Email** | TCP (SMTP, IMAP, POP3) |
| **DNS lookup** | UDP (primary), TCP (zone transfer, large responses) |
| **Video streaming** | UDP (RTP), QUIC |
| **VoIP** | UDP (RTP for audio), TCP (SIP signaling) |
| **Gaming** | UDP (game state), TCP (chat, matchmaking) |
| **Enterprise internal** | OSPF (IGP), TCP for apps |
| **Multi-ISP connectivity** | BGP (EGP) |
| **Modern data center** | BGP everywhere (underlay + overlay) |

---

## Memory Aids

**TCP reliability**: Think "Tracked, Checked, Perfect" - everything tracked, checked, perfect delivery

**UDP speed**: Think "Ultra-fast Datagrams, Please" - speed over reliability

**BGP policy**: Think "Business Gateway Protocol" - business rules, not just tech

**OSPF speed**: Think "Oh So Pretty Fast" - fast convergence

**DORA**: "Don't Offer Requests Anonymously" - DHCP process

---

**Next:** Practice explaining these comparisons in 60-90 seconds. Focus on WHY the trade-offs exist, not just WHAT they are.
