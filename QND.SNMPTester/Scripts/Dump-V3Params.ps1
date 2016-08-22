    Param
    (
        # Param1 help description
        [string] $IP,
        [int] $Port,
        [string] $Version,
        [string] $Community,
        [string] $SNMPv3UserName,
        [string] $SNMPv3AuthProtocol,        
        [string] $SNMPv3AuthPassword,
        [string] $SNMPv3PrivProtocol,
        [string] $SNMPv3PrivPassword,
        [string] $SNMPv3ContextName
    )

	$api =     $api = New-Object -comObject 'MOM.ScriptAPI'
	$message = "IP=$IP, Port=$port, Version=$Version, Timeout=$timeout, Community=$Community, v3User=$SNMPv3UserName, v3AuthProt=$SNMPv3AuthProtocol, v3AuthPass=$SNMPv3AuthPassword, v3PrivProt=$SNMPv3PrivProtocol, v3PrivPass=$SNMPv3PrivPassword, v3Context=$SNMPv3ContextName"
	#$api.LogScriptEvent('Dump-V3Params',100,1, $message )
	$line=''
    foreach($key in $MyInvocation.BoundParameters.Keys) {$line += "$key=$($MyInvocation.BoundParameters[$key])  "}
	$api.LogScriptEvent('Dump-V3Params',101,2,"Starting script. $($MyInvocation.Line) `n$($MyInvocation.ScriptName)`n$($MyInvocation.PSCommandPath)`n$line`n$($MyInvocation.InvocationName)`n$($MyInvocation.ScriptName)$($MyInvocation.CommandOrigin)")
	