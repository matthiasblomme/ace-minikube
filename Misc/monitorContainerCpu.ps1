while ($true) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "`n[$ts]"
    kubectl -n ace-demo top pod -l app.kubernetes.io/name=ir-01-quickstart-ir --containers
    Start-Sleep -Seconds 1
}
