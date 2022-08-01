# NOTE - Borrowed ideas from here: https://medium.com/@dorlugasigal/how-to-set-up-your-powershell-f004c90bbafb

# Requires install of https://ohmyposh.dev/
oh-my-posh init powershell --config "$env:POSH_THEMES_PATH\hotstick.minimal.omp.json" | Invoke-Expression

# Requires install of PowerType
# Enable-PowerType
# Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView
# Set-PSReadLineOption -PredictionSource HistoryAndPlugin
# Set-PSReadLineKeyHandler -Key Tab -Function Complete -Debug

# Requires install of Terminal-Icons
Import-Module -Name Terminal-Icons

# Requires install of PSFzf
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider ‘Ctrl+f’ -PSReadLineChordReverseHistory ‘Ctrl+r’

# Requires install of thefuck
$env:PYTHONIOENCODING="utf-8"
iex "$(thefuck --alias)"