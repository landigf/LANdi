# LANdi - Local Area Network Demo Interface

LANdi is a personal project I’m building to understand how real systems behave.
It’s an educational lab where I can simulate and visualize things like servers,
clients, routers, and load balancers inside a local network.

The idea is to create something that helps me (and hopefully others) learn
system design and networking by actually building and observing small systems.

---
## Projects in This Repository

### 🎯 [Meta NPE Networking Lab](meta-npe-lab/)
**Hands-on crash course for mastering Linux networking, TCP/IP, and BGP**

- Interactive HTML guide with 5 complete scenarios
- Docker Compose lab (6 containers: FRRouting routers + Alpine Linux PCs)
- TCP deep dive, BGP routing, packet capture, troubleshooting
- Interview prep with 90-second talk-tracks
- Zero external dependencies - runs locally with Docker

**Quick start:**
```bash
cd meta-npe-lab
docker-compose up -d
open lab-guide.html
```

### 🔧 LANdi Core (In Progress)
**C++ simulation engine for network behavior**

- Simulate servers, clients, routers, caches, load balancers
- Visualize data flow through TCP/IP layers
- Experiment with distributed system design

---
## Goal
I want to:
- Simulate local systems such as servers, clients, routers, caches, and load balancers.
- Visualize how data moves through the different TCP/IP layers.
- Experiment with distributed design ideas like load balancing, caching, and fault tolerance.
- Learn how to structure software, document it clearly, and reuse components.

---

## Structure
```
landi/
  meta-npe-lab/  -> Hands-on Docker networking lab (TCP, BGP, troubleshooting)
  core/          -> C++ simulation engine (network, events, timing)
  ui/            -> Web-based visualization (requests, latency, graphs)
  scenarios/     -> Example systems (WhatsApp, Google, Spotify, etc.)
  docs/          -> Documentation and development diary
  examples/      -> Small step-by-step demos
  tests/         -> Automated tests
  tools/         -> Utility scripts and helpers
  .github/       -> CI and issue templates
```

---

## Setup

### For Meta NPE Networking Lab:
```bash
cd meta-npe-lab
docker-compose up -d
open lab-guide.html  # macOS
```

### For LANdi Core:
Clone vcpkg inside LANdi/dev-tools/ and run ./bootstrap-vcpkg.sh

---

## Philosophy
I’m not trying to make a big or complex tool.
I just want LANdi to be clear, reusable, and educational.
Every feature will start simple, and I’ll improve it step by step as I learn.

---

## Contributing
If someone wants to help or reuse parts of it, that’s great.
Please keep things simple, well explained, and focused on learning.

---
