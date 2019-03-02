<#
    .SYNOPSIS
        Get Items associated with given goal within a subtree
    
    .NOTES
		SiteTroopers
        
#>

#Setting the dialog fields for the input from user

$database = "master"
$contentRoot = Get-Item -Path (@{$true="$($database):\content\home"; $false="$($database):\content"}[(Test-Path -Path "$($database):\content\home")])
$props = @{
    
    Title = "Items with Goal"
    Description = "Lists all page items that have specific marketing goal."
    OkButtonName = "Run Report"
    CancelButtonName = "Cancel"
    Parameters = @(
        @{ Name = "marketingGoal"; Title = "Marketing Goal"; Editor = "droptree"; Source = "/sitecore/system/Marketing Control Panel/Goals"; Mandatory = $true },
        @{ Name = "contentRoot"; Title = "Content Root"; Mandatory = $true }
        @{ Title = "Note"; Value = "Finds items marked with the marketing goal."; Editor = "info" }
        
    )
}

$result = Read-Variable @props

if($result -ne "ok") {
    Close-Window
    Exit
}

#Function to check if Goal Exists in tracking value

function CheckGoalExists()
{
    Param ([string] $goalId, [string] $itemTrackingFieldValue)
    $goalExists = $itemTrackingFieldValue.Contains($goalId)
    return $goalExists
}

$marketingGoalId = $marketingGoal.ID

#recurse through items and check if goal exists and write to output
$output = @()
$items = Get-ChildItem master: -ID $contentRoot.ID -Recurse
    ForEach ($pageItem in $items) {
        $tracking = $pageItem["__Tracking"]
        $goalExists  = checkGoalExists -goalId $marketingGoalId -itemTrackingFieldValue $tracking
        Write-Host $goalExists
        if ($goalExists)
        {
            $output += $pageItem
        }
    }

#report of the items with given goal	
if ($output.Count -eq 0)
{
    Show-Alert("No pages exist with given goal")
}
else
{
    $props = @{
        Title = "Items with Given Goal Report"
        InfoTitle = "Items with specified Goal '$($marketingGoal.Name)'"
        PageSize = 25
    }

	$output | Show-ListView @props -Property `
		@{ Label = "Item Name"; Expression = { $_.DisplayName } },
        @{ Label = "Path"; Expression = { $_.ItemPath } },
        @{ Label = "ID"; Expression = { $_.ID } }
}

Close-Window
