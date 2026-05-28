# Requires: Run as Administrator
Write-Output "=== SYSTEM CLEANUP STARTED ==="

# ------------------------------------------------------------
# 1. CapabilityAccessManager WAL/SHM Cleanup
# ------------------------------------------------------------
$capFolder = "C:\ProgramData\Microsoft\Windows\CapabilityAccessManager"

if (Test-Path $capFolder) {
    Write-Output "`n[CapabilityAccessManager] Stopping camsvc..."
    Stop-Service -Name camsvc -Force -ErrorAction SilentlyContinue

    # Delete WAL/SHM immediately (tiny timing window)
    Start-Sleep -Milliseconds 100

    Write-Output "[CapabilityAccessManager] Deleting *.db-wal and *.db-shm..."
    Get-ChildItem -Path $capFolder -Filter "*.db-wal" -Force -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue

    Get-ChildItem -Path $capFolder -Filter "*.db-shm" -Force -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue

    Write-Output "[CapabilityAccessManager] Restarting camsvc..."
    Start-Service -Name camsvc -ErrorAction SilentlyContinue
} else {
    Write-Output "[CapabilityAccessManager] Folder not found — skipping."
}

# ------------------------------------------------------------
# 2. Windows Temp Cleanup
# ------------------------------------------------------------
Write-Output "`n[Temp] Cleaning C:\Windows\Temp..."
Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# ------------------------------------------------------------
# 3. User Temp Cleanup
# ------------------------------------------------------------
Write-Output "[Temp] Cleaning User Temp..."
Remove-Item "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# ------------------------------------------------------------
# 4. Windows Update Download Cache
# ------------------------------------------------------------
Write-Output "`n[Windows Update] Cleaning SoftwareDistribution\Download..."
Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
Start-Service wuauserv -ErrorAction SilentlyContinue

# ------------------------------------------------------------
# 5. Delivery Optimization Cache
# ------------------------------------------------------------
Write-Output "[Delivery Optimization] Cleaning DO cache..."
Remove-Item "C:\ProgramData\Microsoft\Windows\DeliveryOptimization\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue

# ------------------------------------------------------------
# 6. Windows Error Reporting Dumps
# ------------------------------------------------------------
Write-Output "[WER] Cleaning Windows Error Reporting..."
Remove-Item "C:\ProgramData\Microsoft\Windows\WER\ReportQueue\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\ProgramData\Microsoft\Windows\WER\ReportArchive\*" -Recurse -Force -ErrorAction SilentlyContinue

# ------------------------------------------------------------
# 7. MEMORY.DMP Cleanup
# ------------------------------------------------------------
$memDump = "C:\Windows\Memory.dmp"
if (Test-Path $memDump) {
    Write-Output "[Memory Dump] Deleting MEMORY.DMP..."
    Remove-Item $memDump -Force -ErrorAction SilentlyContinue
}

# ------------------------------------------------------------
# 8. Optional: Disable Hibernation (saves 6–16 GB)
# ------------------------------------------------------------
# Write-Output "[Hibernation] Disabling hibernation..."
# powercfg -h off

Write-Output "`n=== SYSTEM CLEANUP COMPLETE ==="
