# TCP Deep Dive - Interview Ready

## 90-Second Answer: What is TCP?

TCP is a **connection-oriented, reliable transport protocol** that provides:
1. **Ordered delivery** - packets arrive in sequence
2. **Reliability** - retransmits lost packets
3. **Flow control** - receiver's buffer capacity (rwnd)
4. **Congestion control** - network capacity detection (cwnd)

Used for: HTTP, SSH, databases, any app needing guaranteed delivery.

---

## TCP Connection Lifecycle

### Three-Way Handshake (Establishment)
```
Client              Server
  |---SYN---------->|     (Client initiates, ISN = x)
  |<--SYN-ACK-------|     (Server responds, ISN = y, ACK = x+1)
  |---ACK---------->|     (Client confirms, ACK = y+1)
  |                 |     Connection ESTABLISHED
```

### Four-Way Termination
```
Client              Server
  |---FIN---------->|     (Client wants to close)
  |<--ACK-----------|     (Server acknowledges)
  |<--FIN-----------|     (Server ready to close)
  |---ACK---------->|     (Client confirms)
  |                 |     Connection CLOSED
```

---

## Flow Control vs Congestion Control

### Flow Control (Receiver Window - rwnd)
- **Purpose**: Don't overwhelm the receiver's buffer
- **Mechanism**: Receiver advertises available buffer space in TCP header
- **Unit**: Bytes
- **Command**: `ss -ti` shows `rcv_space`

### Congestion Control (Congestion Window - cwnd)
- **Purpose**: Don't overwhelm the network path
- **Mechanism**: Sender estimates network capacity
- **Algorithm**: Slow start → congestion avoidance → fast retransmit/recovery
- **Command**: `ss -ti` shows `cwnd`

**Effective send rate = min(rwnd, cwnd)**

---

## Congestion Control Algorithms

### Slow Start
1. Start with cwnd = 1 MSS
2. Double cwnd every RTT (exponential growth)
3. Continue until:
   - Reach ssthresh (slow start threshold)
   - Packet loss detected

### Congestion Avoidance
- After ssthresh, increase cwnd by 1 MSS per RTT (linear growth)
- Conservative growth to probe for available bandwidth

### Fast Retransmit / Fast Recovery
- 3 duplicate ACKs → assume packet loss (don't wait for timeout)
- Retransmit immediately
- Reduce cwnd (typically to half)

---

## Troubleshooting TCP Performance

### Command Arsenal

```bash
# Socket state and stats
ss -tuna              # All TCP/UDP connections
ss -ti                # TCP info (cwnd, RTT, retrans, rto)
ss -ti dst <ip>       # Filter by destination

# Packet capture
sudo tcpdump -i any tcp and host <ip>
sudo tcpdump -i any -nn 'tcp[tcpflags] & (tcp-syn) != 0'  # SYN packets only

# Connection test
nc -vz <host> <port>  # Quick port check
curl -v <url>         # HTTP with verbose output
telnet <host> <port>  # Manual connection test
```

### Key Metrics from `ss -ti`

```
ESTAB  0  0  10.0.0.1:45678  10.0.0.2:80
     cubic wscale:7,7 rto:204 rtt:3.5/1.2 ato:40 mss:1448 pmtu:1500 
     rcvmss:1448 advmss:1448 cwnd:10 bytes_sent:1234 bytes_acked:1234 
     segs_out:15 segs_in:12 data_segs_out:5 send 32.0Mbps lastsnd:1000 
     lastrcv:1000 lastack:1000 pacing_rate 64.0Mbps retrans:0/0 
     rcv_space:14480 rcv_ssthresh:64088 minrtt:2.5
```

**What to look for:**
- `rtt`: Round-trip time (lower is better)
- `cwnd`: Congestion window (bigger = more data in flight)
- `retrans`: Retransmission count (0/0 is perfect; >0 means loss)
- `send`: Calculated throughput
- `rcv_space`: Receiver window

---

## Common TCP Issues

### Issue 1: High Latency, No Loss
**Symptoms:** `rtt` high, `retrans` = 0  
**Cause:** Physical distance, routing, queuing delay  
**Debug:** `traceroute`, `mtr`  
**Fix:** Can't fix physics; consider caching/CDN

### Issue 2: Packet Loss → Performance Collapse
**Symptoms:** `retrans` > 0, `cwnd` small, throughput low  
**Cause:** Link congestion, errors, buffer drops  
**Debug:** `ss -ti` (watch retrans count), `tcpdump` (duplicate ACKs)  
**Fix:** 
- Find lossy hop: `mtr`
- QoS/traffic shaping
- MTU issues: `tracepath` to find PMTU

### Issue 3: Slow Start Every Time
**Symptoms:** Good peak speed, but every new connection is slow  
**Cause:** No connection reuse, slow start penalty  
**Debug:** `tcpdump` shows SYN for every request  
**Fix:** 
- HTTP/1.1 keep-alive
- HTTP/2 multiplexing
- Connection pooling

### Issue 4: Small Receiver Window
**Symptoms:** Low throughput despite no loss, `rcv_space` small  
**Cause:** Receiver buffer too small  
**Debug:** `ss -ti` shows small `rcv_space`  
**Fix:** 
- Increase socket buffer: `sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216"`
- TCP window scaling (should be automatic)

---

## TCP vs UDP (Interview Comparison)

| Feature | TCP | UDP |
|---------|-----|-----|
| **Connection** | Connection-oriented (handshake) | Connectionless |
| **Reliability** | Guaranteed delivery, retransmits | Best-effort, no guarantees |
| **Ordering** | In-order delivery | Unordered (app handles it) |
| **Flow Control** | Yes (rwnd) | No |
| **Congestion Control** | Yes (cwnd) | No |
| **Header Size** | 20+ bytes | 8 bytes |
| **Speed** | Slower (overhead) | Faster (minimal overhead) |
| **Use Cases** | HTTP, SSH, FTP, email | DNS, VoIP, streaming, gaming, QUIC |

**When to use UDP:**
- Low latency > reliability (gaming, VoIP)
- Broadcast/multicast (DHCP, mDNS)
- Custom reliability layer (QUIC, RTP)

---

## Advanced: Observing TCP Behavior

### Lab Exercise: Inject Packet Loss

```bash
# Add 3% loss and 50ms delay to interface
sudo tc qdisc add dev eth0 root netem loss 3% delay 50ms

# Run a download
curl -o /dev/null -s -w "Time: %{time_total}s\n" http://example.com/largefile

# Watch retransmissions grow
watch -n 1 'ss -ti dst example.com | grep retrans'

# Remove impairment
sudo tc qdisc del dev eth0 root
```

**Expected result:**
- Download time increases dramatically
- `retrans` count grows
- `cwnd` shrinks (congestion response)

### Lab Exercise: Compare TCP Algorithms

```bash
# Check current algorithm
sysctl net.ipv4.tcp_congestion_control

# Try BBR (better for long/fat networks)
sudo sysctl -w net.ipv4.tcp_congestion_control=bbr

# Re-run tests and compare
```

---

## Meta NPE Interview Questions

### Q1: User reports slow downloads, but ping is fine. Why?
**A:** Ping uses ICMP (tiny packets, no congestion control). TCP download performance depends on:
- **Packet loss** → triggers retransmissions and cwnd reduction
- **Buffer bloat** → high RTT under load
- Check with: `ss -ti` for retrans, `mtr` for loss

### Q2: How does TCP detect congestion?
**A:** TCP treats packet loss as a congestion signal. Detection methods:
- **Timeout** (RTO expires)
- **Fast retransmit** (3 duplicate ACKs)
Response: reduce cwnd (usually to half), enter congestion avoidance

### Q3: Why is the first request always slower?
**A:** Slow start. TCP begins with small cwnd (1-10 MSS) and doubles every RTT until reaching ssthresh or detecting loss. Subsequent requests reuse connection (keep-alive) and start with learned cwnd.

### Q4: What's the bandwidth-delay product and why does it matter?
**A:** BDP = bandwidth × RTT. It's the amount of data "in flight" on the network. If `cwnd < BDP`, you can't fill the pipe → underutilized bandwidth. TCP window scaling allows large windows for high-BDP networks.

### Q5: Debug this: `ss -ti` shows `send 100Mbps` but actual throughput is 10Mbps?
**A:** `send` is TCP's calculated rate based on cwnd/RTT, not actual throughput. Possible causes:
- Application-layer bottleneck (slow disk I/O)
- Receiver processing delay
- Middlebox interference
- Need `tcpdump` or application-layer monitoring to find real bottleneck

---

## Quick Reference Card

```bash
# Connection state
ss -tuna                    # All sockets
ss -t state established     # Active connections
netstat -tuna               # Alternative (older)

# TCP details
ss -ti                      # Show cwnd, RTT, retrans
ss -ti dst <ip>             # Filter by destination
ss -tm                      # Memory info

# Packet capture
tcpdump -i any tcp          # All TCP
tcpdump -i any -nn 'tcp[13] & 2 != 0'  # SYN packets
tcpdump -i any -nn 'tcp[13] & 16 != 0' # ACK packets

# Test connectivity
nc -vz <host> <port>        # Quick port check
timeout 5 bash -c "</dev/tcp/<host>/<port>"  # Pure bash

# System tuning (view)
sysctl -a | grep tcp        # All TCP sysctls
cat /proc/sys/net/ipv4/tcp_congestion_control
```

---

**Next:** Practice on live lab, capture packets, break things with `tc netem`, observe TCP's reaction.
