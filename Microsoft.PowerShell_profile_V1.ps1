# Assumes PowerShell 5+
# Installs are performed globally (i.e. for all users)

$shouldRefresh = $false

# install git tools if not installed
if (-Not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    # install Chocolatey just to install git for Windows
    if (-Not (Get-Command "choco" -ErrorAction SilentlyContinue)) {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
    choco install git -y -params "/GitAndUnixToolsOnPath"
    $shouldRefresh = $true
}

# install and import Posh-Git if not installed
if (-Not (Get-Module -ListAvailable -Name Posh-Git)) {
    Install-Module Posh-Git -Force
}

Import-Module Posh-Git

# install and import Posh-SSH if not installed
if (-Not (Get-Module -ListAvailable -Name Posh-SSH)) {
    Install-Module Posh-SSH -Force
}

Import-Module Posh-SSH

# By default the ssh-agent service is disabled. Allow it to be manually started for the next step to work.
# Make sure you're running as an Administrator.
Get-Service ssh-agent | Set-Service -StartupType Manual

# Start the service
Start-Service ssh-agent

# This should return a status of Running
Get-Service ssh-agent

Add-SshKey                      # adds id_rsa
# Add-SshKey "~/.ssh/github_rsa"  # adds github key

if ($shouldRefresh) {
    refreshenv
}

# NOTE: Chocolatey will probably automatically edit this profile file somewhere down here after it installs.
# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
