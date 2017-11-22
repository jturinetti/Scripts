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

# start the SSH agent and load SSH keys for GitHub authentication
# assumes keys already exist in ~/.ssh/
Start-SshAgent -Quiet
Add-SshKey                      # adds id_rsa
Add-SshKey "~/.ssh/github_rsa"  # adds github key

if ($shouldRefresh) {
    refreshenv
}

# NOTE: Chocolatey will probably automatically edit this profile file somewhere down here after it installs.