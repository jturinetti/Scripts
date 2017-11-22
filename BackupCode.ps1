param([string]$SSHUser, [string]$SSHPassword)

if (-Not ($sshUser -and $sshPassword)) {
    throw "SSH user and password must be provided."
}

$codePath = 'E:\Code'

Push-Location $codePath

$dt = Get-Date
Write-Host "Starting code backup job."

# ensure Zip is installed
if (-Not (Get-Command 'zip' -ErrorAction SilentlyContinue)) {
    # install Chocolatey just to install zip
    if (-Not (Get-Command "choco" -ErrorAction SilentlyContinue)) {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }

    Write-Host 'Zip not installed.  Installing Zip.'
    choco install zip -y
    refreshenv
}

# create unique timestamp for filename
$fdt = "$($dt.Year)$($dt.Month)$($dt.Day)_$($dt.Hour)$($dt.Minute)$($dt.Second)"
$filename = "Code_$fdt.zip"

# zip up all code in directory excluding binaries, other non-code files, and specific directories that don't need backing up
zip -r $filename . -x "*bin\*" "*packages\*" "*obj\*" "*.git*" "*.zip" "*.vscode\" "*.idea\" "*Scala*target\*" "Scratch*" "*TestResults\*" "GitHub*"

# ensure Posh-SSH is installed
if (-Not (Get-Module -ListAvailable -Name Posh-SSH)) {
    Install-Module Posh-SSH -Force
}

Import-Module Posh-SSH

# create PSCredential object
$pw = ConvertTo-SecureString $sshPassword -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential($sshUser, $pw)

# create new SFTP session
$ssh = New-SFTPSession -ComputerName "DATABOX" -Credential $creds

# upload zip file to server
Write-Host
Write-Host 'Uploading zip file to server...'
Set-SFTPFile -LocalFile $filename -RemotePath '/Code Backup' -SessionId $ssh.SessionId
Write-Host '...done.'

# disconnect and remove local zip file
$ssh.Disconnect()
Remove-Item $filename

Write-Host
Write-Host "Started code backup job at $dt"
$dt = Get-Date
Write-Host "Ended code backup job at $dt"
Write-Host

Pop-Location