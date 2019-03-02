<#
    .SYNOPSIS
        Get items created by given user before or after certain date
    
    .NOTES
        SiteTroopers
        
#>

#Setting the dialog fields for the input from user

$database = "master"
$contentRoot = Get-Item -Path (@{$true="$($database):\content\home"; $false="$($database):\content"}[(Test-Path -Path "$($database):\content\home")])
$periodOptions = [ordered]@{Before=1;After=2;}
$props = @{
    
    Title = "Find Pages Created By user before or after specific date"
    Description = "Find pages By by User before or after specific date"
    OkButtonName = "Run Report"
    CancelButtonName = "Cancel"
    Parameters = @(
        @{ Name = "contentRoot"; Title = "Content Root"; Editor = "droptree"; Source = "/sitecore/content"; Mandatory = $true }
        @{ Title = "Note"; Value = "Finds items created by user before or after specific date."; Editor = "info" }
        @{ 
            Name = "selectedDate"
            Value = [System.DateTime]::Now
            Title = "Date"
            Tooltip = "Filter the results for items created on or before/after the specified date"
            Editor = "date time"
        },
        @{
            Name = "selectedPeriod"
            Title = "Period"
            Value = 1
            Options = $periodOptions
            Tooltip = "Pick whether the items should have been created before or after the specified date"
            Editor = "radio"
        },
        @{
            Name = "userName"
            Title = "UserName"
            ToolTip = "Enter the username in format example sitecore\admin"
            Editor = "text"
        }
       
    )
}

$result = Read-Variable @props

if($result -ne "ok") {
    Close-Window
    Exit
}

#Filter for checking for items created before/after certain date

filter Where-Created {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Sitecore.Data.Items.Item]$Item,
        
        [datetime]$Date=([datetime]::Now),
        [switch]$IsBefore
    )
    
    if($IsBefore.IsPresent) {
        if($item."__Created" -le $Date.ToUniversalTime()) {
            $item
        }
    } else {
        if($item."__Created" -ge $Date.ToUniversalTime()) {
            $item
        }
    }
}

#Filter for checking items created by current user

filter Item-CreatedByUser {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Sitecore.Data.Items.Item]$Item,
        [string] $userName
    )
    
        if($item."__Created By" -eq $userName) {
            $item
        }
    
}

#Get items created by given user with the applied filters

$items = @($contentRoot) + @(($contentRoot.Axes.GetDescendants() | Initialize-Item)) | Where-Created -Date $selectedDate -IsBefore:($selectedPeriod -eq 1) `
        |Item-CreatedByUser -userName $userName

$message = "before"
if($selectedPeriod -ne 1) {
    $message = "after"
}

# Report of items created by given user before/after certain date

if ($items.Count -eq 0)
{
    Show-Alert("No pages created by given user during that period")
}
else
{
    $props = @{
        Title = "Items Created By User Report"
        InfoTitle = "Items created $($message) date by Given user"
        InfoDescription = "Lists all items created $($message) the date selected by user."
        PageSize = 25
    }

	$items |
        Show-ListView @props -Property @{Label="Name"; Expression={$_.DisplayName} },
            @{Label="Created"; Expression={$_.__Created} },
            @{Label="Created by"; Expression={$_."__Created by"} },
            @{Label="Path"; Expression={$_.ItemPath} }
}

Close-Window
