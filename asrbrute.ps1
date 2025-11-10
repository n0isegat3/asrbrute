[cmdletbinding()]
param (
    [string]$exePath,
    [string]$bruteRootPath = 'C:\Windows',
    [switch]$continueOnSuccess
)

# Author: Jan Marek, @n0isegat3

$global:log = @()
function Log-Result {
    param (
        [string]$path,
        [bool]$success
    )
    $logEntry = @{
        Path = $path
        Success = $success
    }
    if ($success -eq $true) {$foreColor = 'green'} else {$foreColor = 'red'}


    Write-Host ('--> Execution result of {0} is {1}' -f $path,$success.ToString()) -ForegroundColor $foreColor
    $global:log += $logEntry
}

Write-Host ('Enumerating all subfolders in path {0}' -f $bruteRootPath)
$folders = Get-ChildItem -Path $bruteRootPath -Directory -Recurse -ErrorAction SilentlyContinue

foreach ($folder in $folders) {
    $destination = Join-Path -Path $folder.FullName -ChildPath (Split-Path -Leaf $exePath)
    Copy-Item -Path $exePath -Destination $destination -ErrorAction Stop
    if (Test-Path $destination) {
        Write-Host ('File {0} successfully copied to {1}' -f $exePath,$destination) -ForegroundColor Green
        $execSuccess = $true
        try {
            Start-Process -FilePath $destination -PassThru -ErrorAction Stop -Wait
        } catch {
            $execSuccess = $false
        }
        Remove-Item -Path $destination
        switch ($execSuccess) {
            $true {
                Log-Result -path $folder.FullName -success $true
                if (-not $continueOnSuccess.IsPresent) {break}
            }
            $false {
                Log-Result -path $folder.FullName -success $false
            }
        }
    } else {
        Write-Host ('File {0} failed to copy to {1}' -f $exePath,$destination) -ForegroundColor red
    }

}

$global:log | ConvertTo-Json | Set-Content -Path (Join-Path $PSScriptRoot "execution_log.json")
