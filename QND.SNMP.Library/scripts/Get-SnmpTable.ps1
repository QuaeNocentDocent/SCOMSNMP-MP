<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>

#function Get-SNMPTable
#{
	[CmdletBinding()]
#    [OutputType([xml])] #to be verified
	Param
	(
		# Param1 help description
		[string] $SharpSnmpLibPath,

		# Param2 help description
		[Parameter(Mandatory=$true)]
		[string] $IP,
		[Parameter(Mandatory=$true)]
		[string] $TableOID,        
		[string] $TableIndexID='1',
		[int] $Port=161,
		[ValidateSet("2", "3")]
		[string] $Version='2',
		[int] $Timeout=60000,
		[int] $Retries=3,
		[string] $Community,
		[string] $SNMPv3UserName,
		[string] $SNMPv3AuthProtocol,        
		[string] $SNMPv3AuthPassword,
		[string] $SNMPv3PrivProtocol,
		[string] $SNMPv3PrivPassword,
		[string] $SNMPv3ContextName,
		[int] $TraceLevel=2
	)


$SCRIPT_NAME = "Get-SnmpTable"
$SCRIPT_VERSION = "1.0"

#Trace Level Costants
$TRACE_NONE = 0
$TRACE_ERROR = 1
$TRACE_WARNING = 2
$TRACE_INFO = 3
$TRACE_VERBOSE = 4
$TRACE_DEBUG = 5

#Event Type Constants
$EVENT_TYPE_SUCCESS = 0
$EVENT_TYPE_ERROR   = 1
$EVENT_TYPE_WARNING      = 2
$EVENT_TYPE_INFORMATION  = 4
$EVENT_TYPE_AUDITSUCCESS = 8
$EVENT_TYPE_AUDITFAILURE = 16

#Standard Event IDs
$FAILURE_EVENT_ID = 4000		#errore generico nello script
$SUCCESS_EVENT_ID = 1101
$START_EVENT_ID = 1102
$STOP_EVENT_ID = 1103

#TypedPropertyBag
$AlertDataType = 0
$EventDataType	= 2
$PerformanceDataType = 2
$StateDataType       = 3

function Log-Params
{
	param($parameters,$invocationName)
	$line=''
	foreach($key in $parameters.Keys) {$line += "$key=$($parameters[$key])  "}
	Log-Event $START_EVENT_ID $EVENT_TYPE_INFORMATION  ("Starting script. Invocation Name:$InvocationName`n Parameters`n $line") $TRACE_VERBOSE
}

function Log-Event
{
	param($eventID, $eventType, $msg, $level)
	
	Write-Verbose ("Logging event. " + $SCRIPT_NAME + " EventID: " + $eventID + " eventType: " + $eventType + " Version:" + $SCRIPT_VERSION + " --> " + $msg)
	if($level -le $script:TraceLevel)
	{
		Write-Host ("Logging event. " + $SCRIPT_NAME + " EventID: " + $eventID + " eventType: " + $eventType + " Version:" + $SCRIPT_VERSION + " --> " + $msg)
		$api.LogScriptEvent($SCRIPT_NAME,$eventID,$eventType, ($msg + "`n" + "Version :" + $SCRIPT_VERSION))
	}
}


try {
	[Threading.Thread]::CurrentThread.CurrentCulture = "en-US"        
	[Threading.Thread]::CurrentThread.CurrentUICulture = "en-US"
	$api = New-Object -comObject 'MOM.ScriptAPI'
	#$g_RegistryStatePath = "HKLM\" + $g_API.GetScriptStateKeyPath($SCRIPT_NAME)
	Log-Params $MyInvocation.BoundParameters $MyInvocation.InvocationName
	$dtStart = Get-Date
	#parameters checking
	if(! $TraceLevel) {$TraceLevel = $TRACE_WARNING }
	$script:TraceLevel=$TraceLevel

	if ([string]::IsNullOrEmpty($SharpSnmpLibPath)) {
		$ResPath = (get-itemproperty -path 'HKLM:\system\currentcontrolset\services\healthservice\Parameters' -Name 'State Directory').'State Directory' + '\Resources'
		if(Test-Path $ResPath) {
			$SharpSnmpLibPath = "$ResPath\" + @(get-childitem -path $ResPath -Name sharpsnmplib.dll -Recurse)[0]
			[reflection.assembly]::LoadFrom( $SharpSnmpLibPath ) | Out-Null
		}
		else {Throw [System.DllNotFoundException] 'SharpSnmpLib not found'}
	}
	else {[reflection.assembly]::LoadFrom( (Resolve-Path "$SharpSnmpLibPath\SharpSnmpLib.dll") ) | Out-Null}

	if([string]::IsNullOrEmpty($TableIndexID)) {$TableIndexID ='1'}

		# Create OID object
	$oid = New-Object Lextm.SharpSnmpLib.ObjectIdentifier ($TableOID)
	# Create list for results
	$output= New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]'

	# Create endpoint for SNMP server
	$sip = new-object System.Net.IPAddress -ArgumentList @('')
	if(! ([System.Net.IPAddress]::TryParse($IP,[ref] $sip))) {
		$ipaddresses = [System.Net.Dns]::GetHostAddresses($ip)
		foreach($ipa in $ipaddresses) {
			$sip = $ipa
			break;
		}
	}
	#$sip = [System.Net.IPAddress]::Parse($IP)
	#Dns.GetHostAddresses($IP)

	$device = New-Object System.Net.IpEndPoint ($sip, $port)
 
	switch ($Version)
	{
		'2' {$ver = [Lextm.SharpSnmpLib.VersionCode]::V2
				$priv=$null
				$report = $null
		}
		'3' {
				$ver = [Lextm.SharpSnmpLib.VersionCode]::V3
				$community = $SNMPv3UserName
				switch ($SNMPv3AuthProtocol)
				{
					'MD5' {
						$auth = new-object Lextm.SharpSnmpLib.Security.MD5AuthenticationProvider ($SNMPv3AuthPassword) #OctectString($SNMPv3...)
					}
					'SHA' {
						$auth  = new-object Lextm.SharpSnmpLib.Security.SHA1AuthenticationProvider ($SNMPv3AuthPassword)
					}
				}
				if ($SNMPv3PrivProtocol -and $SNMPv3PrivPassword) {
					$priv = new-object Lextm.SharpSnmpLib.Security.DESPrivacyProvider ($SNMPv3PrivPassword, $auth)
				}
				else {
					$priv = new-object Lextm.SharpSnmpLib.Security.DefaultPrivacyProvider ($auth)
				}
				$discovery = [Lextm.SharpSnmpLib.Messaging.Messenger]::GetNextDiscovery([Lextm.SharpSnmpLib.SnmpType]::GetBulkRequestPdu)
				$report = $discovery.GetResponse($timeout, $device);
		}
	}
	
	$walkMode = [Lextm.SharpSnmpLib.Messaging.WalkMode]::WithinSubtree
 
	# Perform SNMP Get
	try {
		$res= [Lextm.SharpSnmpLib.Messaging.Messenger]::BulkWalk($ver, $device, $community, $oid, $output, $timeout, $retries, $walkMode, $priv, $report)
	} catch [Lextm.SharpSnmpLib.Messaging.TimeoutException] {
		Log-Event $FAILURE_EVENT_ID $EVENT_TYPE_ERROR "SNMP Get on $sIP timed-out" $TRACE_ERROR 
		Return 1
	} catch {
		Log-Event $FAILURE_EVENT_ID $EVENT_TYPE_ERROR "SNMP Walk error: $_" $TRACE_ERROR
		Return 1
	}
 
 #load the table indexes
	$tableIndex = $TableOID+'.'+$TableIndexID
	$res = @{}
	foreach ($var in $output) {
		$currentID = $var.ID.ToString()
		if ( $currentID.Substring(0,$currentID.LastIndexOf('.')) -ieq $tableIndex)
		{
			$res.Add($var.Data.ToInt32(), @{})
		}
		else
		{
			$index = [int] $currentID.Split('.')[$currentID.Split('.').Count-1]
			($res[$index]).Add($currentID, $var.Data.ToString())
		}
	}
 #Now that we have a table we just need to return  a properly formatted prperty bag
 #The property bag has an Index property and then one property for each table element, the property is the property OID without index
	foreach($index in $res.Keys) {
		$bag = $api.CreatePropertyBag()
		Log-Event $SUCCESS_EVENT_ID $EVENT_TYPE_SUCCESS ("Writing Entry with Index $Index") $TRACE_VERBOSE
		$bag.AddValue('Index',$Index)
		foreach($prop in $res[$Index].Keys) {
			$indexLess = $prop.Substring(0,$currentID.LastIndexOf('.')-1)
			Log-Event $SUCCESS_EVENT_ID $EVENT_TYPE_SUCCESS ("Writing Property $indexLess=$($res[$index][$prop])") $TRACE_VERBOSE
			$bag.AddValue($indexLess,$res[$index][$prop])
		}
		$bag
		$api.AddItem($bag) #debug
	}    
	#$api.returnItems() #debug
	Log-Event $STOP_EVENT_ID $EVENT_TYPE_SUCCESS ("has completed successfully in " + ((Get-Date)- ($dtstart)).TotalSeconds + " seconds.") $TRACE_INFO
}
catch {
	Log-Event $FAILURE_EVENT_ID $EVENT_TYPE_ERROR "Main $Error" $TRACE_ERROR	
	write-Verbose $("TRAPPED: " + $_.Exception.GetType().FullName); 
	Write-Verbose $("TRAPPED: " + $_.Exception.Message);
}


#}



