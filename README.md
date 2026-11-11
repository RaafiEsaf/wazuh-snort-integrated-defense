# Wazuh + Snort 3 Integrated Defense Lab

An isolated cybersecurity lab integrating **Wazuh SIEM** with **Snort 3 inline IPS** to detect network activity, block selected traffic, and surface security events in the Wazuh Dashboard.

> **Verified outcome (11 November 2026):** an ICMP packet from the Kali attacker (`192.168.19.128`) to the Windows host (`192.168.19.1`) was blocked by Snort IPS. Wazuh ingested the Snort event and generated a **Level 12 alert** using custom rule **`100204`**. The alert appeared in the Wazuh Dashboard.

## What this lab demonstrates

- Centralised security monitoring with Wazuh.
- Network inspection with Snort 3.
- Snort 3 inline processing through the NFQUEUE DAQ.
- ICMP blocking for a defined source/destination pair.
- Custom Wazuh decoding and alerting for Snort Fast Alert output.
- End-to-end validation from Kali traffic to a Wazuh Dashboard alert.

## Lab topology

| System | Role | Lab address | Notes |
|---|---|---:|---|
| Windows host | Endpoint / target | `192.168.19.1` | Physical Windows machine; Wazuh Agent endpoint |
| Ubuntu Server | Wazuh Manager + Snort 3 sensor / inline gateway | `192.168.19.131` | `enp0s8` is the host-only lab interface; `enp0s3` provides NAT connectivity |
| Kali Linux | Attacker / test generator | `192.168.19.128` | Lab interface `eth0`; NAT interface used for internet access |

Lab subnet: `192.168.19.0/24`  
Virtualisation: Oracle VirtualBox host-only network plus NAT for Ubuntu/Kali internet access.

See [docs/architecture.md](docs/architecture.md) for the traffic path and routing notes.

## Detection flow

```text
Kali Linux
192.168.19.128
     |
     | ICMP test traffic
     v
Ubuntu / Snort 3 Inline IPS
192.168.19.131
     |
     | NFQUEUE + Snort block rule (SID 1000101)
     | Fast Alert log: /var/log/snort/alert_fast.txt
     v
Wazuh Logcollector
     |
     v
Custom decoder: snort3-fast
     |
     v
Custom Wazuh rule: 100204 (Level 12)
     |
     v
Wazuh Dashboard — Threat Hunting / Events
```

## Verified IPS rule

The tested Snort rule blocks ICMP from the Kali lab address to the Windows host:

```snort
block icmp 192.168.19.128 any -> 192.168.19.1 any (msg:"LAB IPS - ICMP blocked from Kali to Windows"; sid:1000101; rev:1;)
```

The rule is provided in [`configs/snort/ips.rules`](configs/snort/ips.rules).

## Verified Wazuh alert

| Field | Verified value |
|---|---|
| Wazuh rule ID | `100204` |
| Severity | `12` |
| Description | `Snort IPS BLOCKED ICMP packet from Kali to Windows.` |
| Source | `192.168.19.128` |
| Destination | `192.168.19.1` |
| Protocol | `ICMP` |
| Decoder | `snort3-fast` |
| Log location | `/var/log/snort/alert_fast.txt` |

The matching decoder and custom rule are in [`configs/wazuh/`](configs/wazuh/).

## Repository layout

```text
wazuh-snort-integrated-defense/
├── README.md
├── LICENSE
├── .gitignore
├── configs/
│   ├── snort/
│   │   └── ips.rules
│   └── wazuh/
│       ├── localfile.conf
│       ├── local_decoder.xml
│       └── local_rules.xml
├── docs/
│   ├── architecture.md
│   ├── installation-and-configuration.md
│   └── testing-and-validation.md
├── reports/
│   └── validation-matrix.md
├── screenshots/
│   ├── 01-lab-topology/
│   ├── 02-wazuh-setup/
│   ├── 03-snort-setup/
│   ├── 04-ids-detection/
│   ├── 05-ips-blocking/
│   └── 06-wazuh-dashboard/
└── scripts/
    └── verify-lab.sh
```

## Quick validation

### 1. Generate test traffic from Kali

Run from the **Kali lab terminal**:

```bash
ping -c 4 192.168.19.1
```

With the tested block rule active, the expected result is that the ping receives no replies.

### 2. Confirm Snort recorded the block

Run on the **Ubuntu Wazuh/Snort server**:

```bash
sudo tail -n 5 /var/log/snort/alert_fast.txt
```

Look for the event containing:

```text
[block] [**] [1:1000101:1] "LAB IPS - ICMP blocked from Kali to Windows"
```

### 3. Confirm Wazuh generated the alert

Run on the **Ubuntu Wazuh/Snort server**:

```bash
sudo grep -aF 'LAB IPS - ICMP blocked from Kali to Windows' /var/ossec/logs/alerts/alerts.json | tail -n 5
```

The verified event contains `rule.id` `100204`, `rule.level` `12`, and decoder `snort3-fast`.

### 4. View it in the Dashboard

Open `https://192.168.19.131`, navigate to **Threat Hunting → Events**, and filter for:

```text
rule.id:100204
```

## Screenshots and evidence

Add your **own genuine screenshots** to the matching folders under `screenshots/`. Suggested captures:

1. VirtualBox network adapters / lab topology.
2. Wazuh services running and Dashboard login page (never include credentials).
3. Snort version and inline startup output.
4. IDS alert output for the Nmap tests, where available.
5. Kali ping result showing the block and the corresponding Snort `[block]` log entry.
6. Wazuh Dashboard event showing rule `100204` and level `12`.

Use descriptive names such as `snort-inline-startup.png`, `kali-icmp-block-test.png`, and `wazuh-rule-100204-dashboard.png`. Do not add fabricated, altered, or credential-bearing screenshots.

## Tested environment

The lab was verified with the following environment details recorded during implementation:

- Ubuntu Server 26.04.1 LTS
- Wazuh 4.14.8
- Snort 3.12.2.0
- DAQ 3.0.27 with NFQUEUE support
- VirtualBox host-only lab network `192.168.19.0/24`

These are the versions and configuration used in this lab run; they are not a statement of universal vendor support or production readiness.

## Safety and scope

This project is for a controlled, isolated lab network and systems you own or are authorised to test. Do not apply the sample blocking rule to a production network without reviewing its impact. The example rule is intentionally specific to the lab IP addresses above.

## Limitations

- The demonstrated IPS rule covers the specific ICMP source/destination pair configured in this lab; it is not a general-purpose firewall policy.
- Nmap IDS detections were tested separately from the ICMP IPS blocking demonstration.
- This repository documents a lab implementation, not a hardened production deployment or a formal security certification.

## License

MIT. See [LICENSE](LICENSE).
