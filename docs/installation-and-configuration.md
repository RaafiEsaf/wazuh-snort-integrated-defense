# Installation and Configuration Notes

This document records the implementation at a reproducible, high level. Adapt interface names and addresses to your own isolated lab; do not paste the sample addresses into another network without checking them first.

## 1. Virtual lab

- Create a dedicated VirtualBox host-only network for `192.168.19.0/24`.
- Attach Ubuntu and Kali to this host-only network.
- Give Ubuntu a separate NAT adapter for package downloads.
- In this implementation, the physical Windows host used `192.168.19.1` on the host-only adapter.
- Ubuntu used `192.168.19.131` on `enp0s8`; Kali used `192.168.19.128` on `eth0`.

## 2. Wazuh

Wazuh Manager, Indexer, and Dashboard were installed on Ubuntu. The Wazuh installation archive contains generated credentials and must **never** be committed to Git.

After installation, confirm service state on Ubuntu:

```bash
sudo systemctl is-active wazuh-manager wazuh-indexer wazuh-dashboard
```

Expected: each service reports `active`.

## 3. Snort 3 and NFQUEUE

Snort 3 was built/installed under `/usr/local/snort`. The lab used the NFQUEUE DAQ module for inline processing. Confirm the binary and available DAQ modules in your own installation before starting IPS mode.

The demonstrated startup command was:

```bash
sudo modprobe nfnetlink_queue
sudo /usr/local/snort/bin/snort -Q --daq nfq --daq-var queue=0 \
  -c /usr/local/snort/etc/snort/snort.lua \
  -R ~/snort-lab/local.rules -A alert_fast -l /var/log/snort \
  --lua "alert_fast = {file = true}"
```

Keep the Snort process running while testing. This command assumes the paths and rule file used in the original lab.

## 4. Forwarding and NFQUEUE

The demonstrated lab used these Ubuntu settings and rule:

```bash
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv4.conf.all.send_redirects=0
sudo sysctl -w net.ipv4.conf.enp0s8.send_redirects=0
sudo iptables -I FORWARD 1 -s 192.168.19.128 -d 192.168.19.1 \
  -p icmp -j NFQUEUE --queue-num 0
```

These commands alter packet forwarding and firewall behavior. Apply them only after verifying the interface, source, destination, and isolated lab topology. The command above is a record of the tested lab configuration, not a general firewall recommendation.

## 5. Wazuh log collection and custom detection

The Snort Fast Alert log was monitored by Wazuh using the localfile block in [`../configs/wazuh/localfile.conf`](../configs/wazuh/localfile.conf). The custom decoder and rule are provided in the same directory.

Integrate the snippets into the existing Wazuh configuration files; do not replace the full `ossec.conf` or `local_rules.xml` with snippets from this repository. Validate Wazuh configuration before restarting services:

```bash
sudo /var/ossec/bin/wazuh-logcollector -t
sudo /var/ossec/bin/wazuh-analysisd -t
```

Then, if validation succeeds, restart the manager:

```bash
sudo systemctl restart wazuh-manager
sudo systemctl is-active wazuh-manager
```

## 6. Version record

Versions recorded during this lab run: Ubuntu Server 26.04.1 LTS, Wazuh 4.14.8, Snort 3.12.2.0, and DAQ 3.0.27. Installation and compatibility behavior can vary by release; consult the official project documentation before reproducing this on a different version.
