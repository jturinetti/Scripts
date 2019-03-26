# change directory to parent folder containing folders of all your git repos
pushd E:\Code\GitHub

$childDirectories = gci -Directory

foreach ($dir in $childDirectories) {
    pushd $dir
    Write-Host $dir
    $gitCommandOutput = (git rev-parse --is-inside-work-tree) | Out-String
    if ($gitCommandOutput.StartsWith("true")) {
        $currentBranch = (git branch | grep \* | cut -d  ' ' -f2)        
        Write-Host "  - $($currentBranch)"
    }
    popd
}

popd