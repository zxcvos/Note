#!/usr/bin/env bash

if [[ -z "$1" ]]; then
  echo "Usage: $0 <url>"
  exit 1
fi

CHECK_URL=$(echo $1 | grep -oE '[^/]+(\.[^/]+)+\b' | head -n 1)
CHECK_NUM=$(wget -qO- "https://${CHECK_URL}" | stdbuf -oL openssl s_client -connect "${CHECK_URL}:443" -tls1_3 -alpn h2 2>&1 | grep -Eoi '(TLSv1.3)|(^ALPN\s+protocol:\s+h2$)' | sort -u | wc -l)

if [[ ${CHECK_NUM} -eq 2 ]]; then
  echo "https://${CHECK_URL} supports TLS 1.3"
else
  echo "https://${CHECK_URL} does not support TLS 1.3"
fi
