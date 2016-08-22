param($ElementId, $TargetId, $DeviceKey, $OID)

	[Threading.Thread]::CurrentThread.CurrentCulture = "en-US"        
    [Threading.Thread]::CurrentThread.CurrentUICulture = "en-US"
	
$index=$oid.Substring($oid.LastIndexOf('.')+1)
$oAPI = new-object -comObject "MOM.ScriptAPI"
# Create Discovery Data
$discoveryData = $oAPI.CreateDiscoveryData(0, $ElementID, $TargetID)

if ($index -match '^[0-9]*$')
{
	$Instance = $discoveryData.CreateClassInstance("$MPElement[Name='Progel.LibraEsva.Disk']$")
	$Instance.AddProperty("$MPElement[Name='Network!System.NetworkManagement.Node']/DeviceKey$", $deviceKey)
	$Instance.AddProperty("$MPElement[Name='Network!System.NetworkManagement.LogicalDevice']/Key$", "Disk - $Index")
	$Instance.AddProperty("$MPElement[Name='Network!System.NetworkManagement.LogicalDevice']/Index$", $Index)
	$Instance.AddProperty("$MPElement[Name='Network!System.NetworkManagement.Disk']/Removable$", $false)
	$discoveryData.AddInstance($Instance)
}
$discoveryData			
