#!/usr/bin/env bash
# Read-only status checks for the Wazuh + Snort lab. Run on Ubuntu.
set -u

printf '\n== Wazuh services ==\n'
for service in wazuh-manager wazuh-indexer wazuh-dashboard; do
  if systemctl is-active --quiet "$service"; then
    printf '[OK] %s is active\n' "$service"
  else
    printf '[WARN] %s is not active\n' "$service"
  fi
done

printf '\n== IPv4 forwarding ==\n'
if [[ -r /proc/sys/net/ipv4/ip_forward ]]; then
  forwarding="$(cat /proc/sys/net/ipv4/ip_forward)"
  printf 'net.ipv4.ip_forward=%s\n' "$forwarding"
  [[ "$forwarding" == "1" ]] || printf '[WARN] Forwarding is not enabled\n'
else
  printf '[WARN] Cannot read IPv4 forwarding state\n'
fi

printf '\n== FORWARD chain ==\n'
sudo iptables -L FORWARD -n -v --line-numbers || true

printf '\n== Latest Snort alerts ==\n'
if [[ -r /var/log/snort/alert_fast.txt ]]; then
  sudo tail -n 5 /var/log/snort/alert_fast.txt
else
  printf '[WARN] Snort alert log is not readable or does not exist\n'
fi

printf '\n== Latest Wazuh rule 100204 alerts ==\n'
if [[ -r /var/ossec/logs/alerts/alerts.json ]]; then
  sudo grep -a '"id":"100204"' /var/ossec/logs/alerts/alerts.json | tail -n 3 || true
else
  printf '[WARN] Wazuh alerts file is not readable or does not exist\n'
fi
