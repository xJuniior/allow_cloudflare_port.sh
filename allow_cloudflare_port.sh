#!/usr/bin/env bash
#
# allow_cloudflare_port.sh
# Fetches the current Cloudflare IPv4 ranges and adds UFW rules
# that expose a single port only to those CF addresses.
#
# Usage:
#   chmod +x allow_cloudflare_port.sh
#   sudo ./allow_cloudflare_port.sh

set -euo pipefail

CF_URL="https://www.cloudflare.com/ips-v4"

# Download the latest list
printf '\nFetching Cloudflare IPv4 ranges… '\n
if ! mapfile -t CLOUDFLARE_IPS < <(curl -fsSL "$CF_URL"); then
  echo "\n❌  Unable to retrieve $CF_URL" >&2
  exit 1
fi
printf 'done. %s prefixes found.\n' "${#CLOUDFLARE_IPS[@]}"

# Ask for the port
read -rp $'Please input the port you want to allow through Cloudflare only: ' PORT

# Validation (1–65535)
if ! [[ $PORT =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )); then
  echo "❌  Invalid port: $PORT" >&2
  exit 2
fi

echo "▶️  Adding UFW rules for port $PORT …"
for ip in "${CLOUDFLARE_IPS[@]}"; do
  ufw allow proto tcp from "$ip" to any port "$PORT" comment "CF-$ip"
  ufw allow proto udp from "$ip" to any port "$PORT" comment "CF-$ip"
  # comment field helps later clean‑up:  ufw delete allow … comment CF-<prefix>
done

ufw reload

echo "✅  Done. Port $PORT is now reachable only from the latest Cloudflare IPv4 ranges."