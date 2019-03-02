<#
    .SYNOPSIS
        Get Items with Disable Analytics setting within a subtree
    
    .NOTES
		SiteTroopers
        
#>

#function to check disable analytics setting of item

function CheckDisableAnlayticsSetting()
{
    Param ([string] $itemTrackingFieldValue)
    $goalExists = $itemTrackingFieldValue.Contains("<tracking ignore=""1""")
    return $goalExists
}

#Setting the dialog fields for the input from user

$database = "master"
$contentRoot = Get-Item -Path (@{$true="$($database):\content\home"; $false="$($database):\content"}[(Test-Path -Path "$($database):\content\home")])

$props = @{
    
    Title = "Page items with disabled analytics setting"
    Description = "Lists all page items that have analytics disabled."
    OkButtonName = "Run Report"
    CancelButtonName = "Cancel"
    Parameters = @(
        @{ Name = "contentRoot"; Title = "Content Root"; Editor = "droptree"; Source = "/sitecore/content"; Mandatory = $true }
        @{ Title = "Note"; Value = "Finds items with analytics disabled."; Editor = "info" }
        
    )
}

$result = Read-Variable @props

if($result -ne "ok") {
    Close-Window
    Exit
}


#recurse through items and find the pages with disableAnlayticsSetting
$output = @()

  $items = Get-ChildItem master: -ID $contentRoot.ID -Recurse 

    ForEach ($pageItem in $items) {
        Write-Host "ID:" $pageItem.ID
        $tracking = $pageItem["__Tracking"]
        $goalExists  = CheckDisableAnlayticsSetting -itemTrackingFieldValue $tracking
        Write-Host $goalExists
        if ($goalExists)
        {
              $output += $pageItem
        }
    }

#report of pages with disabled analytics setting
if ($output.Count -eq 0)
{
    Show-Alert("No pages exist with disabled analytics")
}
else
{
    $props = @{
        Title = "Disabled Analytics Pages Report"
        InfoTitle = "Items with the Disabled Analytics option selected."
        PageSize = 25
    }
    
    $output | Show-ListView @props -Property `
        @{ Label = "Item Name"; Expression = { $_.DisplayName } },
        @{ Label = "Path"; Expression = { $_.ItemPath } },
        @{ Label = "ID"; Expression = { $_.ID } }
     
}

Close-Window