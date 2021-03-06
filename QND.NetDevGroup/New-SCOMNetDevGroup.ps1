<#
.Synopsis
   Batch generates Operations Manager Groups for network devices based network discovery rule membership
   
.DESCRIPTION
Using a pre-imported base management pack creates one group of network devices per network discovery rule. 
The groups are dynamically populated and can be used as any other standard group. The classes will be Singleton so that they are properly displayed in UI for user role Scoping.
Alternatively we could void to user posh and the sdk and just disocver one group for each netwokdisocveryserver
Requirements
 - SCOM Operations Console console must be installed on the system used to run the script
 - the account used to execute the script must be an Operations Manager Admin
 - the base management pack must be pre imported in the management group

.EXAMPLE
   .\QND-CreateNetGroups.ps1 -ManagementServer 'localhost' -MPName 'QND.NetDevGroup'


#>
    [CmdLetBinding()]
param(
    [Parameter(Mandatory=$True,HelpMessage="Please Enter the management server name")]
                    [string] $ms,
    [Parameter(Mandatory=$False,HelpMessage="Please Enter the base managament pack name")]
                    [string] $mpName='QND.NetDevGroup'
)

#init session
try
{
    $error.Clear()
    if (!(Get-Module OperationsManager))
    {
        Import-Module OperationsManager
    }

    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.EnterpriseManagement.Monitoring')
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.EnterpriseManagement.Configuration')
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.EnterpriseManagement')

    New-SCManagementGroupConnection -ComputerName $ms
    $mg = Get-SCOMManagementGroup
}
catch {
    Write-Error 'An Error accured initializing the session. Exiting'
    Write-Error $error
    Exit 1;
}

#check for MP existence
try
{
    $mp = $mg.GetManagementPacks($mpName)[0]
    $scmp = $mg.GetManagementPacks('Microsoft.SystemCenter.Library')[0]
}
catch {
    Write-Error "$mpName not found in Management Group $($mg.Name)"
    exit 1
}

#constants
$config = @'
          <RuleId>$MPElement$</RuleId>
          <GroupInstanceId>$Target/Id$</GroupInstanceId>
          <MembershipRules>
            <MembershipRule>
              <MonitoringClass>$MPElement[Name="SNL!System.NetworkManagement.Node"]$</MonitoringClass>
              <RelationshipClass>$MPElement[Name="QND.NetDevGroup.GroupContainsNode"]$</RelationshipClass>
              <Expression>
                <Contained>
                  <MonitoringClass>$MPElement[Name="SNL!System.NetworkManagement.NetworkDiscoveryServer"]$</MonitoringClass>
                  <Expression>
                    <SimpleExpression>
                      <ValueExpression>
                        <Property>$MPElement[Name="System!System.Entity"]/DisplayName$</Property>
                      </ValueExpression>
                      <Operator>Equal</Operator>
                      <ValueExpression>
                        <Value>//NetworkDiscoveryServerDisplayName//</Value>
                      </ValueExpression>                      
                    </SimpleExpression>
                  </Expression>
                </Contained>
              </Expression>
            </MembershipRule>
          </MembershipRules>
'@

$netdiscoserver = get-scomclassinstance -class (get-scclass -DisplayName 'Network Discovery Server')

foreach ($nd in $netdiscoserver)
{
    $groupDisplayName = $nd.DisplayName + ' Group'
    $groupClassName = $mpName + '.' + $nd.Name
    $groupDiscoveryName = $mpName + '.' + $nd.Name + '.Discovery'
    $groupDiscoveryDisplayName = 'Discovers ' + $groupDisplayName
    try
    {
        $groupClass = $mp.GetClass($groupClassName)
        #if we get here the group has already been defined so you have finished
        Write-Output "Group $groupClassName already defined, skipping"
        continue;
    }
    catch [System.Management.Automation.MethodInvocationException] {
        Write-Output "Group $groupClassName not found, going to create one"
        $Error.Clear()
    }
    catch {
        Write-Error "Uncaught exception, skipping $groupDisplayName"
        Write-Error $Error
        $Error.Clear()
        continue;
    }
    try {
        $grp = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackClass ($mp, $groupClassName, [Microsoft.EnterpriseManagement.Configuration.ManagementPackAccessibility]::Public)   
        $grp.DisplayName = $groupDisplayName
        $grp.LanguageCode = 'ENU'
        $grp.Abstract = $false
        $grp.Singleton = $true
        $grp.Base = $mp.GetClass('QND.NetDevGroup.Class')
        Write-Output "Group $groupDisplayName created, adding discovery rule"
        $discovery = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiscovery ($mp, $groupDiscoveryName)     
        $discovery.DisplayName = $groupDiscoveryDisplayName
        $discovery.LanguageCode = 'ENU'
        $discovery.Category=[Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::Discovery
        $discovery.ConfirmDelivery = $false
        $discovery.Remotable = $true
        $discovery.Priority = [Microsoft.EnterpriseManagement.Configuration.ManagementPackWorkflowPriority]::Normal
        $discovery.Target = $grp
        $discovery.Enabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true
        
        #the ManagementPackDiscovery property DiscoveryClassCollection is marked as readonly so I cannot add the class and relationship documentation
        #$discoveryClass = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiscoveryClass
        #$discoveryClass.TypeID =$mp.GetClass('QND.NetDevGroup.Class') 
        #$t = new-object 'System.Collections.Generic.List[Microsoft.EnterpriseManagement.Configuration.ManagementPackDiscoveryClass]'
        #$t.Add($discoveryClass)
        
        $ds = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDataSourceModule( $discovery,'DS')
        $ds.TypeId = $scmp.GetModuleType('Microsoft.SystemCenter.GroupPopulator')
        $newConfig = $config.Replace('//NetworkDiscoveryServerDisplayName//', $nd.DisplayName)
        $ds.Configuration = $newConfig
        $discovery.DataSource = $ds
     }
     catch {
        Write-Error "Error generating class and disocvery, skipping $groupDisplayName"
        Write-Error $Error
        $Error.Clear()
        continue;
     }
}
     try {
	$mp.Verify()
        $mp.AcceptChanges()
     }
     catch {
        Write-Error "Fatal Error saving management pack, exiting"
        Write-Error $Error
        Exit 2
     }