param(
	[Parameter(Mandatory=$false)] [string]$doc,
	[Parameter(Mandatory=$false)] [string]$tableOID,
	[Parameter(Mandatory=$false)] [string]$tableIndexId,
	[Parameter(Mandatory=$false)] [string]$pnormalize='true',
	[int] $TraceLevel=2
)

#region Constants
	#Constants used for event logging
	$SCRIPT_NAME			= "QND-Translate-SnmpTable"
	$SCRIPT_ARGS = 5

	$SCRIPT_STARTED			= 831
	$PROPERTYBAG_CREATED	= 832
	$SCRIPT_STATUS			= 833
	$SCRIPT_ENDED			= 835

	$SCRIPT_VERSION = "1.0"

	#Trace Level Costants
	$TRACE_NONE 	= 0
	$TRACE_ERROR 	= 1
	$TRACE_WARNING = 2
	$TRACE_INFO 	= 3
	$TRACE_VERBOSE = 4
	$TRACE_DEBUG = 5

	#Event Type Constants
	$EVENT_TYPE_SUCCESS      = 0
	$EVENT_TYPE_ERROR        = 1
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
#endregion Section

#region Standard Functions
function Log-Params
{
	$line=''
	foreach($key in $MyInvocation.BoundParameters.Keys) {$line += "$key=$($MyInvocation.BoundParameters[$key])  "}
	Log-Event $START_EVENT_ID $EVENT_TYPE_INFORMATION  ("Starting script. Invocation Name:$($MyInvocation.InvocationName)`n Parameters`n $line") $TRACE_INFO
}

function Log-Event
{
	param($eventID, $eventType, $msg, $level)
	
	Write-Verbose ("Logging event. " + $SCRIPT_NAME + " EventID: " + $eventID + " eventType: " + $eventType + " Version:" + $SCRIPT_VERSION + " --> " + $msg)
	if($level -le $P_TraceLevel)
	{
		Write-Host ("Logging event. " + $SCRIPT_NAME + " EventID: " + $eventID + " eventType: " + $eventType + " Version:" + $SCRIPT_VERSION + " --> " + $msg)
		$g_API.LogScriptEvent($SCRIPT_NAME,$eventID,$eventType, ($msg + "`n" + "Version :" + $SCRIPT_VERSION))
	}
}

Function Throw-EmptyDiscovery
{
	param($SourceId, $ManagedEntityId)

	$oDiscoveryData = $g_API.CreateDiscoveryData(0, $SourceId, $ManagedEntityId)
	Log-Event $FAILURE_EVENT_ID $EVENT_TYPE_WARNING "Exiting with empty discovery data" $TRACE_INFO
	$oDiscoveryData
	If($P_traceLevel -eq $TRACE_DEBUG)
	{
		#just for debug proposes when launched from command line does nothing when run inside OpsMgr Agent
		$g_API.Return($oDiscoveryData)
	}
}

Function Throw-KeepDiscoveryInfo
{
param($SourceId, $ManagedEntityId)
	$oDiscoveryData = $g_API.CreateDiscoveryData(0,$SourceId,$ManagedEntityId)
	#Instead of Snapshot discovery, submit Incremental discovery data
	$oDiscoveryData.IsSnapshot = $false
	Log-Event $FAILURE_EVENT_ID $EVENT_TYPE_WARNING "Exiting with null non snapshot discovery data" $TRACE_INFO
	$oDiscoveryData    
	If($P_traceLevel -eq $TRACE_DEBUG)
	{
		#just for debug proposes when launched from command line does nothing when run inside OpsMgr Agent	
		$g_API.Return($oDiscoveryData)
	}
}

#endregion

#region Test variables
#	$doc=@"
#	<DataItem type="System.SnmpData" time="2014-10-11T16:36:02.1227936+02:00" sourceHealthServiceId="0EBF800D-FC70-DDBC-58EE-565AE0E76DB8"><Source>172.29.4.5</Source><Destination>127.0.0.1</Destination><ErrorCode>1</ErrorCode><Version>2</Version><SnmpVarBinds><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.1.1</OID><Syntax>2</Syntax><Value VariantType="3">1</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.1.2</OID><Syntax>2</Syntax><Value VariantType="3">2</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.2.1</OID><Syntax>4</Syntax><Value VariantType="8">172.29.4.5</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.2.2</OID><Syntax>4</Syntax><Value VariantType="8">slave of 172.29.4.5</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.3.1</OID><Syntax>66</Syntax><Value VariantType="19">80</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.3.2</OID><Syntax>66</Syntax><Value VariantType="19">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.4.1</OID><Syntax>2</Syntax><Value VariantType="3">1</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.4.2</OID><Syntax>2</Syntax><Value VariantType="3">2</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.5.1</OID><Syntax>2</Syntax><Value VariantType="3">6</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.5.2</OID><Syntax>2</Syntax><Value VariantType="3">6</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.6.1</OID><Syntax>4</Syntax><Value VariantType="8">rr</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.6.2</OID><Syntax>4</Syntax><Value VariantType="8">rr</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.7.1</OID><Syntax>2</Syntax><Value VariantType="3">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.7.2</OID><Syntax>2</Syntax><Value VariantType="3">360</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.8.1</OID><Syntax>4</Syntax><Value VariantType="8">tcp</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.8.2</OID><Syntax>4</Syntax><Value VariantType="8">tcp</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.9.1</OID><Syntax>4</Syntax><Value VariantType="8"></Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.9.2</OID><Syntax>4</Syntax><Value VariantType="8"></Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.10.1</OID><Syntax>2</Syntax><Value VariantType="3">1</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.10.2</OID><Syntax>2</Syntax><Value VariantType="3">1</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.11.1</OID><Syntax>4</Syntax><Value VariantType="8"></Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.11.2</OID><Syntax>4</Syntax><Value VariantType="8"></Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.12.1</OID><Syntax>4</Syntax><Value VariantType="8"></Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.12.2</OID><Syntax>4</Syntax><Value VariantType="8"></Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.13.1</OID><Syntax>4</Syntax><Value VariantType="8">Service1</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.13.2</OID><Syntax>4</Syntax><Value VariantType="8">VMM-SubVS1</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.14.1</OID><Syntax>2</Syntax><Value VariantType="3">2</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.14.2</OID><Syntax>2</Syntax><Value VariantType="3">1</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.15.1</OID><Syntax>66</Syntax><Value VariantType="19">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.15.2</OID><Syntax>66</Syntax><Value VariantType="19">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.16.1</OID><Syntax>65</Syntax><Value VariantType="19">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.16.2</OID><Syntax>65</Syntax><Value VariantType="19">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.17.1</OID><Syntax>65</Syntax><Value VariantType="19">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.17.2</OID><Syntax>65</Syntax><Value VariantType="19">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.18.1</OID><Syntax>65</Syntax><Value VariantType="19">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.18.2</OID><Syntax>65</Syntax><Value VariantType="19">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.19.1</OID><Syntax>70</Syntax><Value VariantType="21">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.19.2</OID><Syntax>70</Syntax><Value VariantType="21">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.20.1</OID><Syntax>70</Syntax><Value VariantType="21">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.20.2</OID><Syntax>70</Syntax><Value VariantType="21">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.21.1</OID><Syntax>65</Syntax><Value VariantType="19">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.1.1.21.2</OID><Syntax>65</Syntax><Value VariantType="19">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.2.1.1.2</OID><Syntax>2</Syntax><Value VariantType="3">2</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.2.1.2.2</OID><Syntax>4</Syntax><Value VariantType="8">172.29.4.4</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.2.1.3.2</OID><Syntax>66</Syntax><Value VariantType="19">8100</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.2.1.4.2</OID><Syntax>2</Syntax><Value VariantType="3">1</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.2.1.5.2</OID><Syntax>2</Syntax><Value VariantType="3">2</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.2.1.6.2</OID><Syntax>4</Syntax><Value VariantType="8">nat</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.2.1.7.2</OID><Syntax>2</Syntax><Value VariantType="3">1000</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.2.1.8.2</OID><Syntax>2</Syntax><Value VariantType="3">1</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.2.1.12.2</OID><Syntax>65</Syntax><Value VariantType="19">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.2.1.13.2</OID><Syntax>65</Syntax><Value VariantType="19">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.2.1.14.2</OID><Syntax>65</Syntax><Value VariantType="19">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.2.1.15.2</OID><Syntax>70</Syntax><Value VariantType="21">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.2.1.16.2</OID><Syntax>70</Syntax><Value VariantType="21">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.2.1.17.2</OID><Syntax>65</Syntax><Value VariantType="19">0</Value></SnmpVarBind><SnmpVarBind><OID>.1.3.6.1.4.1.12196.13.2.1.18.2</OID><Syntax>65</Syntax><Value VariantType="19">0</Value></SnmpVarBind></SnmpVarBinds></DataItem>
#"@
#	$tableOID = '.1.3.6.1.4.1.12196.13.1.1'
#	$tableIndexId="$tableOID.1"
#	$normalize=$true
#	$x = [xml]$doc
#endregion

	[Threading.Thread]::CurrentThread.CurrentCulture = "en-US"        
	[Threading.Thread]::CurrentThread.CurrentUICulture = "en-US"

	$P_TraceLevel = $TRACE_VERBOSE
	$g_api = New-Object -comObject 'MOM.ScriptAPI'
	#$g_RegistryStatePath = "HKLM\" + $g_API.GetScriptStateKeyPath($SCRIPT_NAME)
	#to avoid nasty syntax issue with the POSH module
	$normalize = ($pnormalize -ieq 'true')
	$dtStart = Get-Date
	$P_TraceLevel = $traceLevel
	Log-Params 
try {
	$reader = New-Object System.IO.StringReader $doc
	$Settings = New-Object System.Xml.XmlReaderSettings
	$settings.ConformanceLevel=[System.Xml.ConformanceLevel]::Fragment
	$xmlReader = [System.Xml.XmlReader]::Create($reader,$Settings)
	$xmlReader.MoveToContent()
	#to take into account multiple DataItem elements as top document just wrap the resulting document with a new root
	$x = '<QNDCollection>' + $xmlReader.ReadContentAsString() + '</QNDCollection>'
	$x = [xml] $x

	Log-Event 8001 $EVENT_TYPE_INFORMATION "Got: $doc `n`r Decoded to:$x" $TRACE_DEBUG

	#first we need to get all the index, we cannot assume the index is always the first element even if it is almost always this way
	#for this reason we will use an intermediate hashtable before returning the actual property bags
	$snmpData = $x.SelectNodes('//DataItem/SnmpVarBinds/SnmpVarBind')
	$table = @{}
	foreach($node in $snmpData) {
		$OID = $node.OID
		#just filter out unwanted values
		If($OID.IndexOf($tableOID) -eq -1) {
			Log-Event $SCRIPT_STATUS $EVENT_TYPE_INFORMATION "The $OID doesn't belong to the table $tableOID" $TRACE_INFO
			continue
		}
		if ( $OID.Substring(0,$OID.LastIndexOf('.')) -ieq $tableIndexId)
		{
			$table.Add([int]$node.Value.InnerText, @{})
		}  
	}

	#now that we have the indexes / keys loaded reiterate once again to get the values

	$valueIndexes = @()
	foreach($node in $snmpData) {
		$OID = $node.OID
		#just filter out unwanted values
		If($OID.IndexOf($tableOID) -eq -1) {continue;}
		if ( $OID.Substring(0,$OID.LastIndexOf('.')) -ine $tableIndexId)
		{
			$index = [int] $OID.Split('.')[$OID.Split('.').Count-1]
			#Write-Host $node.Value.Attributes.GetNamedItem('VariantType').Value
			#to be implemented the variant type returned by the snmp module are not documented http://msdn.microsoft.com/en-us/library/ee809331.aspx
			switch ([int] $node.Value.Attributes.GetNamedItem('VariantType').Value)
			{
			0 {$value=''}
			1 {$value=''}
			2 {$value=[int] $node.Value.InnerText}
			3 {$value=[int] $node.Value.InnerText}

			default {$value = $node.Value.InnerText}
			}
			$indexLess = $OID.Substring(0,$OID.LastIndexOf('.'))
			
			if($valueIndexes.IndexOf($indexLess) -eq -1) {$valueIndexes += $indexLess}
			if ($table.ContainsKey($index)) {
				($table[$index]).Add($indexLess, $value)
			}
			else {
				Log-Event $SCRIPT_STATUS $EVENT_TYPE_WARNING "$Index not found in hastable" $TRACE_WARNING
			}
		}    
	}

	If ($normalize) {
		foreach($key in $table.Keys) {
			$entry = $table[$key]
			foreach($valueIndex in $valueIndexes) {
				if (! $entry.ContainsKey($valueIndex)) {$entry.Add($valueIndex,'')}
			}
			#$table[$key]=$entry
		}
	}

	foreach($Index in $table.Keys) {
		$bag = $g_api.CreatePropertyBag()
		Log-Event $SUCCESS_EVENT_ID $EVENT_TYPE_SUCCESS ("Writing Entry with Index $index") $TRACE_DEBUG
		$bag.AddValue('Index',$Index)
		foreach($prop in $table[$Index].Keys) {
			#$indexLess = $prop.Substring(0,$currentID.LastIndexOf('.'))
			$indexLess = $prop
			Log-Event $SUCCESS_EVENT_ID $EVENT_TYPE_SUCCESS ("Writing Property $indexLess=$($table[$Index][$prop])") $TRACE_DEBUG
			$bag.AddValue($indexLess,$table[$Index][$prop])
		}
		$bag
		If($P_traceLevel -eq $TRACE_DEBUG) {$g_api.AddItem($bag)} #debug
	}    
	If($P_traceLevel -eq $TRACE_DEBUG) {$g_api.returnItems()}

	Log-Event $STOP_EVENT_ID $EVENT_TYPE_SUCCESS ("has completed successfully in " + ((Get-Date)- ($dtstart)).TotalSeconds + " seconds.") $TRACE_INFO
}
catch {
	Log-Event $FAILURE_EVENT_ID $EVENT_TYPE_ERROR "Main $Error" $TRACE_ERROR	
	write-Verbose $("TRAPPED: " + $_.Exception.GetType().FullName); 
	Write-Verbose $("TRAPPED: " + $_.Exception.Message);
}