# Assumes PowerShell 5+
# Installs are performed globally (i.e. for all users)

# install git tools if not installed
if (-Not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    # install Chocolatey just to install git for Windows
    if (-Not (Get-Command "choco" -ErrorAction SilentlyContinue)) {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
    choco install git -y
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

# NOTE: Chocolatey will probably automatically edit this profile file somewhere down here after it installs.
