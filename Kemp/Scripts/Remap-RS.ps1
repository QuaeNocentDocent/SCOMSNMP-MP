#quick and dirty

param(
[Parameter(Mandatory=$true)]	[string] $RSAddrType
)

	[Threading.Thread]::CurrentThread.CurrentCulture = "en-US"        
    [Threading.Thread]::CurrentThread.CurrentUICulture = "en-US"
	$api = New-Object -comObject 'MOM.ScriptAPI'

	$bag = $api.CreatePropertyBag()
	#Put the gathered statistics into the property bag.  
	#Includes a value for the folder name so that we can tell which folder the data is from.
	switch ($RSAddrType)
	{
	    0 {$AddrType='Unknown';break;}
		1 {$AddrType='IPv4';break;}
		2 {$AddrType= 'IPv6'; break;}
		16 {$AddrType= 'DNS'; break;}
		default {$AddrType = $VSAddrType;}
	}	
	$bag.AddValue('RSAddrType',$AddrType)
	
	$bag