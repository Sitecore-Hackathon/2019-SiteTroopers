<#
    .SYNOPSIS
        Allows to edit any field from an Item in Experience Editor
    
    .NOTES
		SiteTroopers
        
#>

#Array to Hash function
function ArrayToHash($a)
{
    $hash = @{}
    for ($i=0; $i -lt $a.GetUpperBound(0)+1; $i++){
        $k = $a[$i]
        $v = $a[$i]
        $hash.add($k,$v)
    }
    return $hash
}
#start up variables
$database = "master"
$contextItem = Get-Item -Path .
$itemTemplate = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($contextItem)

$allFields = $itemtemplate.GetFields($false).Name
$allFieldsHash = ArrayToHash($allFields)

#settings
$settings = @{
    Title = "Fields To Edit"
    OkButtonName = "Proceed"
    CancelButtonName = "Cancel"
    Description = "Select which fields to display the editor window"
    Parameters = @(

        @{
            Name = "selectedFields"
            Title = "Fields"
            Options = $allFieldsHash
            Tooltip = "Pick which field to show editor"
            Editor = "checkbox"
        }
    )
    Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

$result = Read-Variable @settings
if($result -ne "ok") {
    Exit
}

$includedFields = $selectedFields
$excludedFields = $allFields | Where-Object { $includedFields -notcontains $_ }
$formatedExcludedFields = $excludedFields | ForEach-Object { "-$_" }
$editorFields = $includedFields + $formatedExcludedFields
#show editor
show-fieldeditor -item $contextItem -preservesections -name $editorFields -Title "EDIT"

Close-Window
