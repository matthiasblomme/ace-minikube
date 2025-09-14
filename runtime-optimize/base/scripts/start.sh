#!/bin/bash
# Always source the ACE env here (don’t rely on .bashrc)
source /opt/ibm/ace-13/server/bin/mqsiprofile

WORKDIR=/home/aceuser/ace-server
mkdir -p "$WORKDIR"

echo "Starting deployments"
# Deploy all BARs you copied into /bars
shopt -s nullglob
for f in /bars/*.bar; do
  echo "Deploying $f"
  ibmint deploy --input-bar-file "$f" \
    --output-work-directory "$WORKDIR" \
    --compile-maps-and-schemas
done

echo "Starting overrides"
# Optional overrides
if [[ -f /config/overrides.properties ]]; then
  ibmint apply overrides \
    --work-directory "$WORKDIR" \
    --overrides-file /config/overrides.properties
fi

echo "Starting optimize"
# Optimize
ibmint optimize server --work-directory "$WORKDIR"

echo "Starting server"
# First start to finalize runtime artifacts
/opt/ibm/ace-13/server/bin/IntegrationServer --work-dir "$WORKDIR" > /tmp/is.log 2>&1 & pid=$!
