# Validation Matrix

| Test | Generator / action | Expected evidence | Status from recorded lab run |
|---|---|---|---|
| Wazuh services | Check manager, indexer, dashboard with `systemctl` | All three `active` | Passed during final demonstration setup |
| Snort inline startup | Start Snort with `-Q` and NFQUEUE DAQ | `nfq DAQ configured to inline`; packet processing starts | Passed |
| ICMP IPS block | Kali: `ping -c 4 192.168.19.1` | No replies and matching Snort `[block]` event | Passed |
| Wazuh ingestion | Search `alerts.json` for the Snort message | Wazuh event decoded as `snort3-fast` | Passed |
| Custom Wazuh rule | Inspect event `rule.id` and `rule.level` | Rule `100204`, level `12` | Passed |
| Dashboard visibility | Threat Hunting → Events; filter `rule.id:100204` | Matching blocked-ICMP event appears | Passed |
| Nmap IDS tests | Kali Nmap discovery, SYN, and Xmas scans | Snort IDS events | Previously observed; capture current screenshots if reproducing |

## Evidence status

The status entries above reflect the lab outputs recorded during implementation. Add genuine screenshots and fresh test output before presenting a new run as independently reproduced.
