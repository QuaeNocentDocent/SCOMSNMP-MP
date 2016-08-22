#quick and dirty

param(

[Parameter(Mandatory=$true)]	[int] $VSProtocol,
[Parameter(Mandatory=$true)]	[string] $VSAddrType
)

	[Threading.Thread]::CurrentThread.CurrentCulture = "en-US"        
    [Threading.Thread]::CurrentThread.CurrentUICulture = "en-US"
	$api = New-Object -comObject 'MOM.ScriptAPI'

	$bag = $api.CreatePropertyBag()
	#Put the gathered statistics into the property bag.  
	#Includes a value for the folder name so that we can tell which folder the data is from.
	switch ($VSProtocol)
	{
		6 {$port='tcp';break;}
		17 {$port = 'udp'; break;}
		default {$port = $VSProtocol ;}
	}
	$bag.AddValue('VSProtocol',$port)
	switch ($VSAddrType)
	{
	    0 {$AddrType='Unknown';break;}
		1 {$AddrType='IPv4';break;}
		2 {$AddrType= 'IPv6'; break;}
		16 {$AddrType= 'DNS'; break;}
		default {$AddrType = $VSAddrType;}
	}	
	$bag.AddValue('VSAddrType',$AddrType)
	
	$bag
