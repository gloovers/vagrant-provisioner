[string]$NETWORK_SUBNET = "172.16.0.0/24"
[string]$GATEWAY_ADDRESS = ""
[int]$n = 0

# getting the address of gateway
$NETWORK_SUBNET.Split('/')[0].Split('.') | ForEach-Object {
    
    if ($n -eq 3) {
        $str = $($_ -as [int]) + 1 
    } else {
        $str = $_ + '.'
    } 
    $GATEWAY_ADDRESS = $GATEWAY_ADDRESS + $str
    $n++
}


If ("NATSwitch" -in (Get-VMSwitch | Select-Object -ExpandProperty Name) -eq $FALSE) {
    "Creating Internal-only switch named 'NATSwitch' on Windows Hyper-V host..."

    New-VMSwitch -SwitchName "NATSwitch" -SwitchType Internal

    New-NetIPAddress -IPAddress $GATEWAY_ADDRESS -PrefixLength 24 -InterfaceAlias "vEthernet (NATSwitch)"

    New-NetNAT -Name "NATNetwork" -InternalIPInterfaceAddressPrefix $NETWORK_SUBNET
}
else {
    "NATSwitch for static IP configuration already exists; skipping"
}

If ($GATEWAY_ADDRESS -in (Get-NetIPAddress | Select-Object -ExpandProperty IPAddress) -eq $FALSE) {
    "Registering new IP address $GATEWAY_ADDRESS on Windows Hyper-V host..."

    New-NetIPAddress -IPAddress $GATEWAY_ADDRESS -PrefixLength $NETWORK_SUBNET.Split('/')[1] -InterfaceAlias "vEthernet (NATSwitch)"
}
else {
    "$GATEWAY_ADDRESS for static IP configuration already registered; skipping"
}

If ("$NETWORK_SUBNET" -in (Get-NetNAT | Select-Object -ExpandProperty InternalIPInterfaceAddressPrefix) -eq $FALSE) {
    'Registering new NAT adapter for $NETWORK_SUBNET on Windows Hyper-V host...'

    New-NetNAT -Name "NATNetwork" -InternalIPInterfaceAddressPrefix $NETWORK_SUBNET
}
else {
    "$($NETWORK_SUBNET) for static IP configuration already registered; skipping"
}