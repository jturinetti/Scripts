# credit to https://stackoverflow.com/questions/1287718/how-can-i-display-my-current-git-branch-name-in-my-powershell-prompt
function Write-BranchName () {
    try {
        $branch = git rev-parse --abbrev-ref HEAD

        Write-Host "  Current Branch:" -NoNewline
        if ($branch -eq "HEAD") {
            # we're probably in detached HEAD state, so print the SHA
            $branch = git rev-parse --short HEAD
            Write-Host " ($branch)" -ForegroundColor Red
        }
        else {
            # we're on an actual branch, so print it
            Write-Host " ($branch)" -ForegroundColor Blue
        }
    } catch {
        # we'll end up here if we're in a newly initiated git repo
        Write-Host " (no branches yet)" -ForegroundColor Red
    }
}

$folders = Get-ChildItem "."

foreach ($subFolder in $folders) {
    if ($subFolder.PSIsContainer) {
        Push-Location $subFolder
        # check if we're in a git repo folder
        if (Test-Path ".git") {
            Write-Host "Updating $subFolder" -ForegroundColor Yellow
            Write-BranchName
            git pull
        } else {
            Write-Host "   $subFolder does not contain a Git repository!" -ForegroundColor Red
        }        
        
        Pop-Location
        Write-Host
    }
}