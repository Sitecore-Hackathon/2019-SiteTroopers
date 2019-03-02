<#
    .SYNOPSIS
        Get Publishable modified items by current user within a subtree
    
    .NOTES
        Michael West, Alex Washtell, SiteTroopers
        
#>

#Setting the dialog fields for the input from user

$database = "master"
$root = Get-Item -Path (@{$true="$($database):\content\home"; $false="$($database):\content"}[(Test-Path -Path "$($database):\content\home")])
$periodOptions = [ordered]@{Before=1;After=2;}
$settings = @{
    Title = "Report Filter"
    OkButtonName = "Proceed"
    CancelButtonName = "Abort"
    Description = "Filter the results for items updated on or after the specified date"
    Parameters = @(
        @{
            Name="root"; 
            Title="Choose the report root"; 
            Tooltip="Only items from this root will be returned.";
			Mandatory = $true
        },
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
        }
    )
    Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

$result = Read-Variable @settings
if ($result -ne "ok") {
    Exit
}


#Function to Get Workflow Approved States dictionary of WorkflowID->WorkflowApprovedStateID

function GetWorkflowApprovedStates()
{
    $workflowApprovedStates = @{}
    $children = Get-ChildItem -Path "master:\system\Workflows" 
    foreach($child in $children)
    {
        Write-Host $child.Name
        $states = Get-ChildItem -ID $child.ID
        foreach($state in $states)
        {
            $finalState = $state["Final"]
            Write-Host $state.Name $finalState
            if ($finalState -eq 1)
            {
                Write-Host $state.Name "is final state"
                $workflowApprovedStates.Add($child.ID.ToString(), $state.ID.ToString())
            }
        }
    }

    foreach($hash in $workflowApprovedStates.keys)
    {
        Write-Host $hash $workflowApprovedStates[$hash]
    }
    
    return $workflowApprovedStates
}

#Filter for Item last modified by current user

filter Item-LastModifiedByCurrentUser()
{
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Sitecore.Data.Items.Item] $item,
        [string] $currentUser
        )
        
    $itemUpdatedBy = $item["__Updated By"]
    Write-Host "Item updated by" $itemUpdatedBy
    if ($currentUser -eq $itemUpdatedBy)
    {
        $item
    }
}

#Filter for Item is in publishable state if no workflow assigned or if in approved state of workflow 
#and not set to never publish

filter Item-In-Publishable-State()
{
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Sitecore.Data.Items.Item] $item,
        [System.Collections.Hashtable] $workflowApprovedStates
        )
        
    $workflow = $item["__Workflow"]
    $workflowstate = $item["__Workflow state"]
    $neverPublish = $item["__Never publish"]
    Write-Host "ID:" $item.ID "(" $item.FullPath ")"
    Write-Host "Workflow: " $workflow "(" $workflow.DisplayName ")"
    Write-Host "Workflow State: " $workflowstate "(" $workflowstate.DisplayName ")"
    
    if ($workflow -eq "" -and $workflowstate -eq "")
    {
        Write-Host "No workflow for item " $item.FullPath
        
        if(!($neverPublish))
        {
            $item
        }
    }
    else
    {
        if ($workflow -ne "")
        {
            Write-Host "Workflow is set"
            $hashvalue = $workflowApprovedStates[$workflow]
            Write-Host "hashvalue:" $hashvalue
            if ($workflowApprovedStates[$workflow] -eq $workflowstate)
            {
                 Write-Host "workflow for item is approved" $item.FullPath
                 if(!($neverPublish))
                 {
                    $item
                 }
            }
        }
        
    }
}

# Filter for where last updated date is before/after certain date

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

filter Item-Different-In-Web {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Sitecore.Data.Items.Item]$item)
        
    $itemInWeb = Get-Item web: -ID $item.ID
    
    if ($itemInWeb."__Revision" -ne $item."__Revision") {
        $item
    }
}

#Get Current user
$user = Get-User -Current

#Get WorkflowApprovedStates dictionary of WorkflowId -> WorkflowApprovedStateId
$workflowApprovedStates = GetWorkflowApprovedStates

#Get Items to Publish last modified by the current user 
$items = @($root) + @(($root.Axes.GetDescendants() | Initialize-Item)) | Where-LastUpdated -Date $selectedDate -IsBefore:($selectedPeriod -eq 1) `
        | Item-LastModifiedByCurrentUser -currentUser $user.Name | Item-In-Publishable-State -workflowApprovedStates $workflowApprovedStates | Item-Different-In-Web


$message = "before"
if($selectedPeriod -ne 1) {
    $message = "after"
}

#report of the modified publishable items by current user

if($items.Count -eq 0) {
    Show-Alert "There are no items updated on or $message the specified date"
} else {
    $props = @{
        Title = "Items Last Updated Report"
        InfoTitle = "Items last updated $($message) date"
        InfoDescription = "Lists all items last updated $($message) the date selected."
        PageSize = 25
    }
    
    $items |
        Show-ListView @props -Property @{Label="Name"; Expression={$_.DisplayName} },
            @{Label="Updated"; Expression={$_.__Updated} },
            @{Label="Updated by"; Expression={$_."__Updated by"} },
            @{Label="Created"; Expression={$_.__Created} },
            @{Label="Created by"; Expression={$_."__Created by"} },
            @{Label="Path"; Expression={$_.ItemPath} }
}
Close-Window