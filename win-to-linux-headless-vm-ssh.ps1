$vmName = ""
$sshUser = ""
$vbPath = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

# Section 1: Starting the VM
Write-Host "`n========== [1/4] Starting VM '$vmName' in headless mode ==========" -ForegroundColor Cyan
& $vbPath startvm "$vmName" --type headless
Write-Host "--> Command sent to start VM '$vmName'" -ForegroundColor Gray

# Section 2: Waiting for VM to be running
Write-Host "`n========== [2/4] Waiting for VM '$vmName' to reach running state ==========" -ForegroundColor Cyan
do {
    Start-Sleep -Seconds 2
    $vmStateLine = & $vbPath showvminfo $vmName --machinereadable | Select-String 'VmState='
    $vmState = if ($vmStateLine) {
        $vmStateLine.ToString().Split('=')[1].Trim().Trim('"')
    } else {
        ""
    }
    Write-Host "--> Current VM state: " -NoNewline
    Write-Host "$vmState" -ForegroundColor Yellow
} while ($vmState -ne "running")

# Section 3: Waiting for IP address
Write-Host "`n========== [3/4] VM is running. Waiting for IP address ==========" -ForegroundColor Cyan
do {
    Start-Sleep -Seconds 2
    $ipRaw = & "$vbPath" guestproperty get "$vmName" "/VirtualBox/GuestInfo/Net/0/V4/IP"
    $ip = $ipRaw -replace '^Value: ', ''
    Write-Host "--> Current VM IP: " -NoNewline
    Write-Host "$ip" -ForegroundColor Yellow
} while ($ip -eq "No value set" -or [string]::IsNullOrWhiteSpace($ip))

Write-Host "`n[OK] VM IP retrieved: " -ForegroundColor Green -NoNewline
Write-Host "$ip" -ForegroundColor Cyan
Write-Host "--> Waiting for SSH port (22) to open..." -ForegroundColor Gray

# Section 3.5: Waiting for SSH port to be open
$sshReady = $false
while (-not $sshReady) {
    $connTest = Test-NetConnection -ComputerName $ip -Port 22
    if ($connTest.TcpTestSucceeded) {
        $sshReady = $true
        Write-Host "[OK] Port 22 is open. Proceeding to SSH..." -ForegroundColor Green
    } else {
        Write-Host "WARNING: SSH not available yet. Retrying..." -ForegroundColor DarkYellow
        Start-Sleep -Seconds 2
    }
}

# Section 4: Connecting via SSH
Write-Host "`n========== [4/4] Connecting via SSH ==========" -ForegroundColor Cyan
Write-Host "--> User: $sshUser" -ForegroundColor Gray
Write-Host "--> IP: $ip" -ForegroundColor Gray

ssh -o StrictHostKeyChecking=accept-new $sshUser@$ip