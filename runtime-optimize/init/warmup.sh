#!/bin/bash
set -euo pipefail
WORKDIR=${WORKDIR:-/home/aceuser/ace-server}

mkdir -p "$WORKDIR"

# 1) Deploy + compile
ibmint deploy \
  --input-bar-file /bars/*.bar \
  --output-work-directory "$WORKDIR" \
  --compile-maps-and-schemas

# 2) Optimize
ibmint optimize server --work-directory "$WORKDIR"

# 3) First start to trigger runtime-level compilation/validation
IntegrationServer --work-dir "$WORKDIR" > /tmp/is.log 2>&1 & pid=$!

# Wait for BIP1991I ("finished initialization") up to 180s
for i in $(seq 1 180); do
  grep -q "BIP1991I: Integration server has finished initialization" /tmp/is.log && break
  sleep 1
done

# Graceful stop (SIGINT)
kill -INT "$pid"
wait "$pid" || true
