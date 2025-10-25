24 oct 2025
pkgs
1. nlohmann-json: event schema in JSON
2. fmt: formatted logs

25 oct 2025
the first goal is to build an event loop that can:
1. simulate time moving forweard
2. handle some fake events (PacketSent, PackerReceived)
3. print or log each event in order

so we need
- Event
    - time
    - type
    - data
- queue
    - makes sense
- simulation loop
    - while queue not empty

simulate a simple REST flow.
Core actors:
- Client
- LB
- Service