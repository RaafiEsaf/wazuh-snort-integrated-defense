# Testing and Validation

## Test A — Snort inline block

**Run from:** Kali lab terminal.

```bash
ping -c 4 192.168.19.1
```

**Expected:** no ICMP replies while the inline block rule and forwarding path are active. Packet loss alone is not sufficient proof of an IPS block; confirm the Snort event as well.

**Run on:** Ubuntu Wazuh/Snort server.

```bash
sudo tail -n 5 /var/log/snort/alert_fast.txt
```

**Verified event pattern:**

```text
[block] [**] [1:1000101:1] "LAB IPS - ICMP blocked from Kali to Windows" [**] [Priority: 0] {ICMP} 192.168.19.128 -> 192.168.19.1
```

## Test B — Wazuh alert generation

**Run on:** Ubuntu Wazuh/Snort server.

```bash
sudo grep -aF 'LAB IPS - ICMP blocked from Kali to Windows' \
  /var/ossec/logs/alerts/alerts.json | tail -n 5
```

**Verified result on 11 November 2026:** Wazuh generated an event with:

- `rule.id`: `100204`
- `rule.level`: `12`
- `decoder.name`: `snort3-fast`
- `data.srcip`: `192.168.19.128`
- `data.dstip`: `192.168.19.1`
- `data.protocol`: `ICMP`
- `location`: `/var/log/snort/alert_fast.txt`

## Test C — Dashboard

Open `https://192.168.19.131`, go to **Threat Hunting → Events**, and filter for `rule.id:100204`. The verified event was displayed with the description:

`Snort IPS BLOCKED ICMP packet from Kali to Windows.`

The Dashboard displayed the event on 11 November 2026 at approximately 18:54 local time (Asia/Kolkata).

## IDS tests

Separate Snort IDS tests used Nmap host discovery, SYN scanning, and Xmas scanning. Snort generated alerts for the lab's custom ICMP, SYN, and Xmas signatures. The exact complete IDS signature definitions should be exported from the working lab before they are added to this repository; this starter repository includes only the exact IPS rule whose contents and SID were verified.
