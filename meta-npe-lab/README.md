# 🚀 Meta NPE Networking Lab Kit

> **Hands-on crash course for mastering Linux networking, TCP/IP, BGP, and troubleshooting for Meta (Facebook) Network Production Engineering interviews and real-world scenarios.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Required-blue.svg)](https://www.docker.com/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

## 📖 What Is This?

This is a **complete, working networking lab** that runs on your laptop using Docker containers. No cloud resources needed, no complex setup - just Docker and this repository.

**Perfect for:**
- 🎯 Preparing for Meta/Facebook NPE interviews
- 📚 Learning real Linux networking (not just theory)
- 🔧 Practicing systematic troubleshooting
- 💼 Understanding BGP routing in production
- 🎤 Building strong interview talk-tracks

## ✨ What Makes This Special?

- **Zero coding required** - Everything is pre-configured and working
- **Interactive HTML guide** - Visual, step-by-step instructions with one-click copy buttons
- **Real network tools** - FRRouting, tcpdump, ss, ip commands in actual Linux containers
- **Interview-focused** - Each exercise includes "90-second answer" talk-tracks
- **Systematic methodology** - Hypothesis trees for troubleshooting like a pro

## 🏗️ Architecture

```
Network Topology (10.0.0.0/16):

    PC1 (10.0.1.10)
      |
      |--- R1 (10.0.0.11) --- R2 (10.0.0.2) --- R3 (10.0.0.3)
      |                                             |
    PC2 (10.0.2.10)                            PC3 (10.0.3.10)

Components:
• 3 x FRRouting routers (BGP/OSPF capable)
• 3 x Alpine Linux PCs (full networking tools)
• Docker Compose orchestration
• Persistent network topology
```

## 🚀 Quick Start

### Prerequisites

- **Docker Desktop** (Mac, Windows, Linux)
- **5 minutes** of your time

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/meta-npe-networking-lab.git
cd meta-npe-networking-lab

# 2. Start the lab (one command!)
docker-compose up -d

# 3. Verify all 6 containers are running
docker ps

# 4. Open the interactive guide
open lab-guide.html    # macOS
start lab-guide.html   # Windows
xdg-open lab-guide.html # Linux
```

That's it! Your lab is running. 🎉

## 📚 What's Included

### 📁 Project Structure

```
meta-npe-networking-lab/
├── lab-guide.html              # 🌟 Interactive web guide (START HERE)
├── docker-compose.yml          # Container orchestration
├── README.md                   # This file
│
├── notes/                      # Deep-dive technical notes
│   ├── tcp-deep-dive.md       # TCP internals, flow control, troubleshooting
│   ├── bgp-deep-dive.md       # BGP path selection, configuration
│   ├── protocol-comparisons.md # TCP vs UDP, BGP vs OSPF, IPv4 vs IPv6
│   ├── hypothesis-trees.md    # Systematic troubleshooting frameworks
│   └── command-cheatsheet.md  # Quick reference for all commands
│
├── scripts/                    # Automation scripts
│   ├── setup-env.sh           # Environment checker
│   ├── start-lab-fixed.sh     # Lab startup helper
│   └── stop-lab.sh            # Clean shutdown
│
└── screenshots/                # Add your learning screenshots here
```

## 🎯 Learning Scenarios

The interactive guide walks you through **5 hands-on scenarios**:

### 1️⃣ **Network Basics**
- Network interface inspection (`ip a`)
- Routing table analysis (`ip r`)
- Connectivity testing (`ping`)
- ARP cache examination (`ip neigh`)

### 2️⃣ **TCP Connection Analysis**
- Set up HTTP server
- Examine socket states (`ss -tan`)
- Understand TCP handshake
- Monitor established connections

### 3️⃣ **Packet Capture**
- Use `tcpdump` to capture traffic
- Filter by protocol/port
- Analyze packet headers
- Read PCAP files

### 4️⃣ **BGP Routing**
- Access FRRouting (`vtysh`)
- Configure BGP neighbors
- Understand path selection
- Examine routing tables

### 5️⃣ **Troubleshooting**
- Systematic hypothesis trees
- Layer-by-layer debugging (OSI model)
- Common failure patterns
- Production-ready methodologies

## 💡 How to Use This Lab

### Option 1: Follow the Interactive Guide (Recommended)

1. Open `lab-guide.html` in your browser
2. Keep it side-by-side with your terminal
3. Click "Copy" buttons to run commands
4. Learn what each output means
5. Practice interview talk-tracks

### Option 2: Self-Directed Exploration

```bash
# Connect to any container
docker exec -it clab-frr01-PC1 sh    # Alpine PC
docker exec -it clab-frr01-R1 bash   # FRRouting router

# Run commands inside
ip a              # Show interfaces
ip r              # Show routes
ping 10.0.0.11    # Test connectivity
ss -tuln          # Show listening sockets
tcpdump -i eth0   # Capture packets

# Access router config
docker exec -it clab-frr01-R1 vtysh
show ip bgp summary
show ip route
```

### Option 3: Interview Prep Focus

1. Read the deep-dive notes in `notes/`
2. Practice 90-second answers out loud
3. Run commands to verify concepts
4. Build your own troubleshooting playbook

## 🎤 Interview Talk-Tracks

Each scenario includes **production-ready answers** for common interview questions:

- ✅ "Explain the TCP 3-way handshake"
- ✅ "How does BGP path selection work?"
- ✅ "Troubleshoot: Users can't reach the web server"
- ✅ "What's the difference between TCP and UDP?"
- ✅ "How do you debug high latency issues?"

## 🛠️ Commands You'll Master

| Category | Commands | Use Case |
|----------|----------|----------|
| **Interfaces** | `ip a`, `ip link`, `ip -s link` | Check network cards, MAC addresses, stats |
| **Routing** | `ip r`, `ip route get`, `traceroute` | Find paths, debug routing issues |
| **ARP/Neighbors** | `ip neigh`, `arp -n` | Layer 2 debugging, MAC resolution |
| **Sockets** | `ss -tuln`, `ss -tan`, `ss -ti` | TCP connections, listening ports |
| **DNS** | `dig`, `dig +trace`, `nslookup` | Name resolution debugging |
| **Packets** | `tcpdump -i eth0`, `tcpdump port 80` | Capture and analyze traffic |
| **BGP** | `show ip bgp`, `show ip bgp summary` | Routing protocol analysis |

## 🔧 Troubleshooting

### Lab won't start?

```bash
# Check Docker is running
docker ps

# Clean up and restart
docker-compose down
docker system prune -f
docker-compose up -d
```

### Can't run `ip` or `ss` commands?

These commands only work **inside the Linux containers**, not on macOS/Windows:

```bash
# ❌ Wrong: Running on host
ip a    # Error on macOS/Windows

# ✅ Correct: Running inside container
docker exec -it clab-frr01-PC1 sh
ip a    # Works!
```

### Container fails to start?

```bash
# Check logs
docker logs clab-frr01-R1

# Restart specific container
docker-compose restart R1
```

## 🤝 Contributing

We welcome contributions! Here's how you can help:

- 🐛 **Report bugs** - Open an issue with details
- ✨ **Add scenarios** - Create new learning exercises
- 📝 **Improve docs** - Fix typos, clarify instructions
- 🎨 **Enhance guide** - Improve the HTML interface

```bash
# Fork the repo, create a branch
git checkout -b feature/new-scenario

# Make changes, test them
docker-compose down && docker-compose up -d

# Submit a pull request
```

## 📖 Additional Resources

### Official Documentation
- [FRRouting Documentation](https://docs.frrouting.org/)
- [Linux networking commands](https://man7.org/linux/man-pages/)
- [TCP/IP Illustrated](https://en.wikipedia.org/wiki/TCP/IP_Illustrated)

### Meta NPE Interview Prep
- Focus on systematic troubleshooting (hypothesis trees)
- Practice explaining concepts in 60-90 seconds
- Understand *why* protocols work the way they do
- Be ready to demonstrate commands live

## 📜 License

MIT License - feel free to use this for learning, teaching, or interview prep!

## 🙏 Acknowledgments

- **FRRouting** - Amazing open-source routing suite
- **Docker** - Making complex topologies simple
- **Alpine Linux** - Lightweight containers
- **Meta/Facebook** - For inspiring systematic network engineering

## ⭐ Star This Repo!

If this lab helped you land an interview or understand networking better, give it a star! ⭐

---

**Built with ❤️ for aspiring Network Engineers**

Questions? Open an issue or submit a PR!
