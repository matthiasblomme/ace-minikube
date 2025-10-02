# Namespace you want to back up
$ns  = "your-namespace"

# Output folder with timestamp
$out = "backup-$ns-$(Get-Date -Format yyyyMMddHHmmss)"
New-Item -ItemType Directory -Path $out -Force | Out-Null

# Get all namespaced API resources (skip noisy kinds like events)
$kinds = kubectl api-resources --namespaced=true -o name `
         | Select-String -NotMatch '^(events(\.events\.k8s\.io)?$)' `
         | ForEach-Object { $_.ToString() }

foreach ($kind in $kinds) {
    # Create subfolder per resource kind (e.g. deployments.apps, services, configmaps)
    $kindSafe = $kind -replace '[^a-zA-Z0-9\.-]', '_'
    $kindDir = Join-Path $out $kindSafe
    New-Item -ItemType Directory -Path $kindDir -Force | Out-Null

    # Get all resources of that kind in the namespace
    $names = kubectl get -n $ns $kind -o name 2>$null

    foreach ($name in $names) {
        # Replace / with - so filenames are safe
        $safe = $name -replace '/', '-'

        # Dump the YAML without managedFields noise
        kubectl get -n $ns $name -o yaml --show-managed-fields=false `
      | Out-File -FilePath "$kindDir\$safe.yaml" -Encoding utf8
    }
}
