#!/usr/bin/env bash

if [[ -z "$1" ]]; then
  echo "Usage: $0 <url>"
  exit 1
fi

CHECK_URL=$(echo $1 | sed -En 's|^(https?://)?([^./]+\.)*([^.]+\.[^./]+).*|\3|p')
wget -qO- "https://${CHECK_URL}" | stdbuf -oL openssl s_client -connect "${CHECK_URL}:443" -brief 2>&1 | grep -Eqi 'TLSv1.3'

if [[ $? -eq 0 ]]; then
  echo "https://${CHECK_URL} supports TLS 1.3"
else
  echo "https://${CHECK_URL} does not support TLS 1.3"
fi
