<#
    .SYNOPSIS
        Get Items set to never publish within a subtree
    
    .NOTES
		SiteTroopers
        
#>

#Setting the dialog fields for the input from user

$database = "master"
$contentRoot = Get-Item -Path (@{$true="$($database):\content\home"; $false="$($database):\content"}[(Test-Path -Path "$($database):\content\home")])

$props = @{
    
    Title = "Find Pages with Never Publish Setting"
    Description = "Lists all page items that have never publish setting set."
    OkButtonName = "Run Report"
    CancelButtonName = "Cancel"
    Parameters = @(
        @{ Name = "contentRoot"; Title = "Content Root"; Editor = "droptree"; Source = "/sitecore/content"; Mandatory = $true }
        @{ Title = "Note"; Value = "Finds items marked with the never publish setting."; Editor = "info" }
        
    )
}

$result = Read-Variable @props

if($result -ne "ok") {
    Close-Window
    Exit
}

#recurse through items and get items with never publish setting set
$output = @()

$items = Get-ChildItem master: -ID $contentRoot.ID -Recurse
    ForEach ($pageItem in $items) {
        $neverPublish = $pageItem["__Never publish"]
        Write-Host $neverPublish
        if ($neverPublish)
        {
              $output += $pageItem
        }
    }

# report of items with never publish setting
if ($output.Count -eq 0)
{
    Show-Alert("No pages exist with never publish setting")
}
else
{
    $props = @{
        Title = "Never Publish Pages Report"
        InfoTitle = "Items with the Never Publish option selected."
        PageSize = 25
    }
    
	$output | Show-ListView @props -Property `
        @{ Label = "Item Name"; Expression = { $_.DisplayName } },
        @{ Label = "Path"; Expression = { $_.ItemPath } },
        @{ Label = "ID"; Expression = { $_.ID } }
}   

Close-Window