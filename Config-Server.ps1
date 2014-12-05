[string]$uinput = ""
[bool]$exit_script = 0


while (($uinput -ne "99") -and (!$exit_script)) {
    Write-Host
    Write-Host ""
    Write-Host
    $uinput = Read-Host "What would you like to do?"

    if ($uinput -eq "1") {

    }

    if ($uinput -eq "x") {
        Write-Host
 
        $exit_script = 1
        }

    # reset $uinput
    $uinput = ""
} 