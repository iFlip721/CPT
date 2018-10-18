function Get-IPrange {
    param ( 
      [string]$Start, 
      [string]$End, 
      [string]$Ip, 
      [string]$Mask, 
      [int]$Cidr 
    ) 
 
    function IP-toINT64 () { 
      param ($ip) 
 
      $octets = $ip.split(".") 
      return [int64]([int64]$octets[0]*16777216 +[int64]$octets[1]*65536 +[int64]$octets[2]*256 +[int64]$octets[3]) 
    } 
 
    function INT64-toIP() { 
      param ([int64]$int) 

      return (([math]::truncate($int/16777216)).tostring()+"."+([math]::truncate(($int%16777216)/65536)).tostring()+"."+([math]::truncate(($int%65536)/256)).tostring()+"."+([math]::truncate($int%256)).tostring() )
    } 
 
    if ($ip) {
        $ipaddr = [Net.IPAddress]::Parse($ip)
    } 
    if ($cidr) {
        $maskaddr = [Net.IPAddress]::Parse((INT64-toIP -int ([convert]::ToInt64(("1"*$cidr+"0"*(32-$cidr)),2))))
    } 
    if ($mask) {
        $maskaddr = [Net.IPAddress]::Parse($mask)
    }
    if ($ip) {
        $networkaddr = new-object net.ipaddress ($maskaddr.address -band $ipaddr.address)
    } 
    if ($ip) {
        $broadcastaddr = new-object net.ipaddress (([system.net.ipaddress]::parse("255.255.255.255").address -bxor $maskaddr.address -bor $networkaddr.address))
    } 
 
    if ($ip) { 
      $startaddr = IP-toINT64 -ip $networkaddr.ipaddresstostring 
      $endaddr = IP-toINT64 -ip $broadcastaddr.ipaddresstostring 
    } else { 
      $startaddr = IP-toINT64 -ip $start 
      $endaddr = IP-toINT64 -ip $end 
    } 
 
 
    for ($i = $startaddr; $i -le $endaddr; $i++) { 
      INT64-toIP -int $i 
    }

}