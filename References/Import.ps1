$cred = Get-Credential
$mps=Get-ChildItem -Path 'C:\Users\grandinid\SkyDrive\Dev\OpsMgr\GIT\QNDSNMP\References' -Filter *.mp* | select FullName | out-gridview -OutputMode Multiple
$mps | % {Import-SCManagementPack -Fullname $_ -ComputerName om2012r2ms1.pre.lab -Credential $cred}