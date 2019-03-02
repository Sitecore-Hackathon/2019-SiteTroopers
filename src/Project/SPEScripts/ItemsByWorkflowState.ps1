<#
    .SYNOPSIS
		Report: Items on Specific Workflow State
    
    .NOTES
		SiteTroopers
        
#>

# User Prompt

$props = @{
    Title = "Items on Specific Workflow State"
    Description = "Lists all items that are on the specified Workflow state."
    OkButtonName = "Run Report"
    CancelButtonName = "Cancel"
    Parameters = @(
        @{ Name = "workflowState"; Title = "Workflow State"; Editor = "droptree"; Source = "/sitecore/system/Workflows"; Mandatory = $true },
        @{ Name = "startItem"; Title = "Start Item"; Editor = "droptree"; Source = "/sitecore/content"; Mandatory = $true }
        @{ Title = "Note"; Value = "Only descendants from selected item will be searched."; Editor = "info" }
    )
    Validator = {
        $selectedState = $variables.workflowState.Value
        
        if ($selectedState.TemplateID -ne "{4B7E2DA9-DE43-4C83-88C3-02F042031D04}") {
            $variables.workflowState.Error = "Please select a valid Workflow State"
        }
    }
}

$result = Read-Variable @props

if ($result -ne "ok") {
    Close-Window
    Exit
}

#
# PROCESS
#

# Get all items under specified start item
$allTargetItems = Get-ChildItem master: -ID $startItem.ID -Recurse

# Get workflow state item ID
$stateItemId = $workflowState.ID

# For each item, get the current workflow state
$output = $allTargetItems | Where {$_."__Workflow state" -eq $stateItemId}

if ($output) {
    $props = @{
        Title = "Items on Specific Workflow State Report"
        InfoTitle = "Items in State '$($workflowState.Name)' from Workflow '$($workflowState.Parent.Name)'"
        InfoDescription = "Lists all items that are in workflow state $($workflowState.FullPath)"
        PageSize = 25
    }

    $output | Show-ListView @props -Property `
        @{ Label = "Item Name"; Expression = { $_.DisplayName } },
        @{ Label = "Path"; Expression = { $_.ItemPath } },
        @{ Label = "ID"; Expression = { $_.ID } }
} else {
    Show-Alert "There are no items on the selected Workflow State."
}

Close-Window