param($OID)
$index=$oid.Substring($oid.LastIndexOf('.')+1)
$oAPI = new-object -comObject "MOM.ScriptAPI"
$pb = $oAPI.CreatePropertyBag()
# Populate the property bag with data from the registy
$pb.AddValue("Index", $index)
$pb
