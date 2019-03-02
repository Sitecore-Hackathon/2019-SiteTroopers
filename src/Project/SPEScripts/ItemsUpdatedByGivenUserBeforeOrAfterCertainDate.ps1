<#
    .SYNOPSIS
        Get items updated by given user before or after certain date
    
    .NOTES
        SiteTroopers
        
#>

#Setting the dialog fields for the input from user

$database = "master"
$contentRoot = Get-Item -Path (@{$true="$($database):\content\home"; $false="$($database):\content"}[(Test-Path -Path "$($database):\content\home")])
$periodOptions = [ordered]@{Before=1;After=2;}
$props = @{
    
    Title = "Find Pages Updated By user before or after specific date"
    Description = "Find pages updated by User before or after specific date"
    OkButtonName = "Run Report"
    CancelButtonName = "Cancel"
    Parameters = @(
        @{ Name = "contentRoot"; Title = "Content Root"; Editor = "droptree"; Source = "/sitecore/content"; Mandatory = $true }
        @{ Title = "Note"; Value = "Finds items updated by user before or after specific date."; Editor = "info" }
        @{ 
            Name = "selectedDate"
            Value = [System.DateTime]::Now
            Title = "Date"
            Tooltip = "Filter the results for items updated on or before/after the specified date"
            Editor = "date time"
        },
        @{
            Name = "selectedPeriod"
            Title = "Period"
            Value = 1
            Options = $periodOptions
            Tooltip = "Pick whether the items should have been last updated before or after the specified date"
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

#Filter items updated before/after certain date

filter Where-LastUpdated {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Sitecore.Data.Items.Item]$Item,
        
        [datetime]$Date=([datetime]::Now),
        [switch]$IsBefore
    )
    
    if($IsBefore.IsPresent) {
        if($item."__Updated" -le $Date.ToUniversalTime()) {
            $item
        }
    } else {
        if($item."__Updated" -ge $Date.ToUniversalTime()) {
            $item
        }
    }
}

#Filter items updated by given user name

filter Item-UpdatedByUser {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Sitecore.Data.Items.Item]$Item,
        [string] $userName
    )
    
        if($item."__Updated By" -eq $userName) {
            $item
        }
    
}

#Get items updated before/after certain date by given user

$items = @($contentRoot) + @(($contentRoot.Axes.GetDescendants() | Initialize-Item)) | Where-LastUpdated -Date $selectedDate -IsBefore:($selectedPeriod -eq 1) `
        |Item-UpdatedByUser -userName $userName

$message = "before"
if($selectedPeriod -ne 1) {
    $message = "after"
}

#Report of items updated before/after certain date by given user
if ($items.Count -eq 0)
{
    Show-Alert("No pages updated by given user during that period")
}
else
{
    $props = @{
        Title = "Items Updated By User Report"
        InfoTitle = "Items last updated $($message) date"
        InfoDescription = "Lists all items last updated $($message) the date selected by user."
        PageSize = 25
    }

	$items |
        Show-ListView @props -Property @{Label="Name"; Expression={$_.DisplayName} },
            @{Label="Updated"; Expression={$_.__Updated} },
            @{Label="Updated by"; Expression={$_."__Updated by"} },
            @{Label="Path"; Expression={$_.ItemPath} }
}

Close-Window
