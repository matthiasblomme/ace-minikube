#!/bin/bash
# Always source the ACE env here (don’t rely on .bashrc)
source /opt/ibm/ace-13/server/bin/mqsiprofile

ts() { date +"%Y-%m-%d %H:%M:%S"; }
say() { echo "[$(ts)] $*"; }

WORKDIR=/home/aceuser/ace-server
mkdir -p "$WORKDIR"

say "Starting deployments"
# Deploy all BARs you copied into /bars
shopt -s nullglob
for f in /bars/*.bar; do
  say "Deploying $f"
  ibmint deploy --input-bar-file "$f" \
    --output-work-directory "$WORKDIR" \
    --compile-maps-and-schemas
  say "Finished deploying $f"
done

say "Starting overrides (if present)"
# Optional overrides
if [[ -f /config/overrides.properties ]]; then
  ibmint apply overrides \
    --work-directory "$WORKDIR" \
    --overrides-file /config/overrides.properties
  say "Finished overrides"
else
  say "No overrides.properties found; skipping"
fi

say "Starting optimize"
# Optimize
ibmint optimize server --work-directory "$WORKDIR"
say "Finished optimize"

say "Starting server"
# First start to finalize runtime artifacts
/opt/ibm/ace-13/server/bin/IntegrationServer --name "${ACE_SERVER_NAME}" --work-dir "$WORKDIR" > /tmp/is.log 2>&1 & pid=$!
say "IntegrationServer launched (pid=$pid). Logs: /tmp/is.log"
