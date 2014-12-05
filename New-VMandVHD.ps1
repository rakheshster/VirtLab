[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  [ValidateScript({Test-Path $_ -PathType Leaf})]
  [string]$BaseVHD,
  
  [Parameter(Mandatory=$true)]
  [string]$Name,

  [Parameter(Mandatory=$true)]
  [ValidateScript({Test-Path $_ -PathType Leaf})]
  [string]$UnattendFile,

  [Parameter(Mandatory=$false)]
  [ValidateScript({Test-Path $_ -PathType Leaf})]
  [string]$QuickConfig,

  [Parameter(Mandatory=$false)]
  [ValidateScript({Test-Path $_ -PathType Container})]
  [string]$VHDPath=$(Split-Path $BaseVHD -Parent),

  [Parameter(Mandatory=$false)]
  [ValidateScript({$_ -ge 32MB})]
  [int64]$MemoryStartup = 512MB,

  [Parameter(Mandatory=$true)]
  [string]$LicenseKey
)

New-VHD -Differencing -Path "$VHDPath\$Name.vhdx" -ParentPath $BaseVHD

$VHDDrive = (Mount-VHD "$VHDPath\$Name.vhdx" -Passthru | Get-Disk | Get-Partition | ?{$_.Type -eq "Basic" } | select -First 1).DriveLetter

[xml]$Unattend = Get-Content $UnattendFile
(($Unattend.unattend.settings | ?{ $_.pass -eq "specialize" }).Component | ?{ $_.Name -eq "Microsoft-Windows-Shell-Setup" }).ComputerName = "$Name"
($Unattend.unattend.settings | ?{ $_.pass -eq "oobeSystem" }).component.UserData.ProductKey.Key = "$LicenseKey"
$Unattend.Save("${VHDDrive}:\\Unattend.xml")

if ($QuickConfig -ne $null) { Copy-Item $QuickConfig ${VHDDrive}:\ }
Dismount-VHD "$VHDPath\$Name.vhdx"

New-VM -Name $Name -MemoryStartupBytes $MemoryStartup -SwitchName "Private Switch" -VHDPath "$VHDPath\$Name.vhdx" -Generation 2
Set-VM -Name $Name -DynamicMemory 
Add-VMNetworkAdapter -VMName $Name -SwitchName "Internal Switch"

#Mount-VHD "$VHDPath\$Name.vhdx"
#$IntMac = (Get-VMNetworkAdapter $Name |? {$_.SwitchName -eq "Internal Switch" }).MacAddress
#'Get-NetAdapter | ?{ $_.PermanentAddress -eq ' + "$IntMac" + ' }  | Rename-NetAdapter INTNET' | Out-File ${VHDDrive}:\Network.ps1

#$PrivMac = (Get-VMNetworkAdapter $Name |? {$_.SwitchName -eq "Private Switch" }).MacAddress
#'Get-NetAdapter | ?{ $_.PermanentAddress -eq ' + $PrivMac + ' }  | Rename-NetAdapter PRIVNET' | Out-File ${VHDDrive}:\Network.ps1 -Append
#Dismount-VHD "$VHDPath\$Name.vhdx"
