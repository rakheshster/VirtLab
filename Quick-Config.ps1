[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)]
  # idea from http://stackoverflow.com/a/5901728/2610230
  [ipaddress]$IPaddress,

  [Parameter(Mandatory=$true)]
  [int32]$PrefixLength,

  [Parameter(Mandatory=$false)]
  [ipaddress]$DefaultGw,
    
  [Parameter(Mandatory=$true)]
  [ipaddress[]]$DNSServers
)

# First adapter is expected to be connected to the private switch; second to the internal switch
# Rename the adapters to reflect this
Rename-NetAdapter -Name "Ethernet" -NewName PRIVNET -ErrorAction SilentlyContinue
if ($? -eq $false) { Write-Host -ForegroundColor DarkRed -BackgroundColor Black "Error renaming the interface" }
Rename-NetAdapter -Name "Ethernet 2" -NewName INTNET -ErrorAction SilentlyContinue
if ($? -eq $false) { Write-Host -ForegroundColor DarkRed -BackgroundColor Black "Error renaming the interface" }

# Set the second adapter to get addresses from DHCP ...
Set-NetIPInterface -InterfaceAlias INTNET -Dhcp Enabled -ErrorAction SilentlyContinue
if ($? -eq $false) { Write-Host -ForegroundColor DarkRed -BackgroundColor Black "Error enabling DHCP" }

# .. and disable it (enable it when you need the Internet as it shares the hosts' Internet connection)
Disable-NetAdapter -Name INTNET -Confirm:$false -ErrorAction SilentlyContinue
if ($? -eq $false) { Write-Host -ForegroundColor DarkRed -BackgroundColor Black "Error disabling the interface" }

# Assign an IP address for the first adapter
New-NetIPAddress -IPAddress $IPaddress -PrefixLength $PrefixLength -InterfaceAlias PRIVNET
Set-DnsClientServerAddress -InterfaceAlias PRIVNET -ServerAddresses $DNSServers
if ($DefaultGw -ne $null) { Set-NetRoute -DestinationPrefix 0.0.0.0/0 -NextHop $DefaultGw -InterfaceAlias PRIVNET }

# Open up some firewall ports (note: only for the domain profile)
Set-NetFirewallRule -DisplayGroup "Windows Firewall Remote Management" -Profile Domain -Enabled "True"
Set-NetFirewallRule -DisplayGroup "Remote Desktop" -Profile Domain -Enabled "True"
Set-NetFirewallRule -DisplayGroup "Windows Management Instrumentation (WMI)" -Profile Domain -Enabled "True"
Set-NetFirewallRule -DisplayGroup "Virtual Machine Monitoring" -Profile Domain -Enabled "True"

# Turn on remote desktop
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1

# Start PowerShell by default
Set-ItemProperty -Path 'HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name Shell -Value "cmd.exe /C start PowerShell.exe -noExit"
