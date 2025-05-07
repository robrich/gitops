
$ErrorActionPreference = "Stop"

Set-Location -Path $PSScriptRoot
cd ..

cd ../server/git

git checkout main # TODO: pass in arg for branch name
# commented out for demo:
#git reset --hard

$output = git pull
if ($output -match "Already up[ -]to[ -]date") {
  Write-Host "Repo is already up to date. Skipping deploy."
  Set-Location -Path $PSScriptRoot
  cd ..
  exit 0
} else {
  Write-Host "Repo was updated:"
  Write-Host $output
}

pm2 stop backend

robocopy /mir . ../wwwroot /XD ".git" /NFL /NDL /NP

pm2 reload all
pm2 ls

Set-Location -Path $PSScriptRoot
cd ..
