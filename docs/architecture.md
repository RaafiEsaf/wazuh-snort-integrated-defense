# Lab Architecture

## Components

| Component | Lab role | Address / interface |
|---|---|---|
| Windows host | Endpoint and ICMP target; Wazuh Agent | `192.168.19.1` |
| Ubuntu Server | Wazuh Manager, Snort 3 sensor and inline forwarding point | `192.168.19.131` on `enp0s8`; NAT on `enp0s3` |
| Kali Linux | Traffic-generation / attacker VM and Wazuh Agent | `192.168.19.128` on `eth0`; NAT on `eth1` |

The host-only network is `192.168.19.0/24`. Ubuntu and Kali also had NAT adapters for package access. The host-only network is the isolated lab segment.

## Traffic path for the IPS test

1. Kali sends ICMP echo requests to the Windows host address `192.168.19.1`.
2. A host route on Kali sends that target traffic through Ubuntu `192.168.19.131`.
3. IPv4 forwarding is enabled on Ubuntu.
4. An iptables `FORWARD` rule sends the selected ICMP packets to NFQUEUE queue `0`.
5. Snort 3 runs in inline mode with the NFQUEUE DAQ and evaluates the custom block signature (SID `1000101`).
6. Snort writes its Fast Alert output to `/var/log/snort/alert_fast.txt`.
7. Wazuh Logcollector monitors the Snort log. The custom `snort3-fast` decoder extracts the signature, message, protocol, source and destination addresses.
8. Wazuh custom rule `100204` raises a Level 12 alert, which is visible in the Dashboard.

## Routing notes

The demonstrated lab required a Kali host route for `192.168.19.1/32` via `192.168.19.131`, and a Windows return route for Kali via Ubuntu. The precise route persistence method can vary by operating system and host configuration. These routes should be used only in the isolated lab environment.

## Network isolation

Keep the lab on its dedicated VirtualBox host-only adapter. Do not bridge the deliberately blocked test traffic onto a public, campus, corporate, or other third-party network.
