function New-GenericObject {
    # Creates an object of a generic type - see http://www.leeholmes.com/blog/2006/08/18/creating-generic-types-in-powershell/
 
    param(
        [string] $typeName = $(throw “Please specify a generic type name”),
        [string[]] $typeParameters = $(throw “Please specify the type parameters”),
        [object[]] $constructorParameters
        )
 
    ## Create the generic type name
    $genericTypeName = $typeName + ‘`’ + $typeParameters.Count
    $genericType = [Type] $genericTypeName
 
    if(-not $genericType)
        {
        throw “Could not find generic type $genericTypeName”
        }
 
    ## Bind the type arguments to it
    [type[]] $typedParameters = $typeParameters
    $closedType = $genericType.MakeGenericType($typedParameters)
    if(-not $closedType)
        {
        throw “Could not make closed type $genericType”
        }
 
    ## Create the closed version of the generic type
    ,[Activator]::CreateInstance($closedType, $constructorParameters)
}

function Get-AuthenticationProvider([string] $auth, [Lextm.SharpSnmpLib.OctetString] $phrase)
{
    if ($auth -ieq 'MD5')
    {
        return new-object Lextm.SharpSnmpLib.Security.MD5AuthenticationProvider($phrase)
    }
    if ($auth -ieq 'SHA')
    {
        return new-object Lextm.SharpSnmpLib.Security.SHA1AuthenticationProvider($phrase)
    }
    return $null
}

[reflection.assembly]::LoadFrom( (Resolve-Path ".\SharpSnmpLib.dll") )

#sample walk

$sOIDstart='1.3.6.1.2.1'
$sIP='192.168.167.16'
$community='esva'
$communityO = new-object Lextm.SharpSnmpLib.OctetString($community)
    $maxRepetitions=10  
 $ip = [System.Net.IPAddress]::Parse($sIP)
    $svr = New-Object System.Net.IpEndPoint ($ip, 161)
$ver = [Lextm.SharpSnmpLib.VersionCode]::V2
    # Create OID object
    $oid = New-Object Lextm.SharpSnmpLib.ObjectIdentifier ($sOIDstart)
 
    # Create list for results
    $results = New-GenericObject System.Collections.Generic.List Lextm.SharpSnmpLib.Variable
    $walkMode = [Lextm.SharpSnmpLib.Messaging.WalkMode]::WithinSubtree
    #[Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $oid, $results, 10000, $walkMode)

    [Lextm.SharpSnmpLib.Messaging.Messenger]::BulkWalk($ver, $svr, $communityO, $oid, $results, 10000, $maxRepetitions, $walkMode, $null, $null)

    #sample walk snmpv3
    
    #parameters

    $sOIDstart='1.3.6.1.2.1'
    $v3User='745hfc6736f53f397n'
    $v3Auth='SHA'
    $v3AuthPass='82364cb6429cfn28'
    $v3Priv='DES'
    $v3PrivPass='836c58268c658c6'
    $sIp='172.30.2.100'
    $port=161
    $timeout=10000
    $maxRepetitions=10    

    #parameters transofrms
    $v3UserO=new-object Lextm.SharpSnmpLib.OctetString($v3User)
    $v3AuthPassO=new-object Lextm.SharpSnmpLib.OctetString($v3AuthPass) 
    $v3PrivPassO=new-object Lextm.SharpSnmpLib.OctetString($v3PrivPass)
    $ip=$null
    $ipOK = [System.Net.IPAddress]::TryParse($sIp,[ref] $ip)
    if ($ipOK -eq $false)
    {
        $addresses = $null
        $addresses = [System.Net.Dns]::GetHostAddresses($sIP)
        If ($addresses -ne $null)
        {
            foreach ($addr in $addresses)
            {
                if ($addr.AddressFamily -ieq [System.Net.Sockets.AddressFamily]::InterNetwork)
                {
                    $ip = $addr.Address
                }
            }
        }
    }
    if ($ip -eq $null)
    {
        #error host not found
        exit 1
    }


    #logic
    $level = [Lextm.SharpSnmpLib.Levels]::Reportable
    if ($v3Auth -ne '')
    {
        $level = $level -bor [Lextm.SharpSnmpLib.Levels]::Authentication
    }
    if($v3Priv -ne '')
    {
        $level = $level -bor [Lextm.SharpSnmpLib.Levels]::Privacy
    }
    $ver = [Lextm.SharpSnmpLib.VersionCode]::V3
    $walkMode = [Lextm.SharpSnmpLib.Messaging.WalkMode]::WithinSubtree #Default=All
    #$ip = [System.Net.IPAddress]::Parse($sIP)
    $rcv = New-Object System.Net.IpEndPoint ($ip, $port)
    $oid = New-Object Lextm.SharpSnmpLib.ObjectIdentifier ($sOIDstart)
    $results = New-GenericObject System.Collections.Generic.List Lextm.SharpSnmpLib.Variable
    $authProvider = Get-AuthenticationProvider $v3Auth $v3AuthPassO
    $privProvider = New-Object Lextm.SharpSnmpLib.Security.DESPrivacyProvider($v3PrivPassO, $authProvider)


#Discovery discovery = Messenger.NextDiscovery;
#ReportMessage report = discovery.GetResponse(num3, receiver);
#Messenger.BulkWalk(versionCode, receiver, new OctetString(empty), test, result, num3, num2, walkMode, priv, report);
$discovery = [Lextm.SharpSnmpLib.Messaging.Messenger]::NextDiscovery
$report = $discovery.GetResponse($timeout, $rcv)
[Lextm.SharpSnmpLib.Messaging.Messenger]::BulkWalk($ver, $rcv, $v3User, $oid, $results, $timeout, $maxRepetitions, $walkMode, $privProvider, $report)

