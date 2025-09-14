#!/bin/bash
LOG=/home/aceuser/ace-server/prewarm.log
exec > >(tee -a "$LOG") 2>&1

source /opt/ibm/ace-13/server/bin/mqsiprofile

WORKDIR=/home/aceuser/ace-server
mkdir -p "$WORKDIR"

# Ensure it's a proper Integration Server work dir
if [[ ! -f "$WORKDIR/server.conf.yaml" ]]; then
  echo "[$(date +'%F %T')] mqsicreateworkdir $WORKDIR"
  mqsicreateworkdir "$WORKDIR"
fi

echo "[$(date +'%F %T')] Deploy & optimize"
shopt -s nullglob
for f in /bars/*.bar; do
  echo "[$(date +'%F %T')] Deploying $f"
  ibmint deploy --input-bar-file "$f" \
    --output-work-directory "$WORKDIR" \
    --compile-maps-and-schemas
done
if [[ -f /config/overrides.properties ]]; then
  ibmint apply overrides --work-directory "$WORKDIR" --overrides-file /config/overrides.properties
fi
ibmint optimize server --work-directory "$WORKDIR"

echo "[$(date +'%F %T')] Warm-start IntegrationServer"
LOG=/tmp/is.log
/opt/ibm/ace-13/server/bin/IntegrationServer --work-dir "$WORKDIR" > "$LOG" 2>&1 & pid=$!

# Wait up to 300s for BIP1991I, then stop the server
for i in $(seq 1 300); do
  grep -q "BIP1991I: Integration server has finished initialization" "$LOG" && break
  sleep 1
done
if ! grep -q "BIP1991I" "$LOG"; then
  echo "Warm-start timed out; tail follows:"; tail -n 200 "$LOG"
fi

echo "[$(date +'%F %T')] Stopping warm-started server (pid=$pid)"
kill -INT "$pid" || true
wait "$pid" || true
echo "[$(date +'%F %T')] Warmup complete; exiting init"
