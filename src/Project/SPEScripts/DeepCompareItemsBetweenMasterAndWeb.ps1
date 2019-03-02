<#
    .SYNOPSIS
        Compare fields and values from Items between Master and Web database within a subtree
    
    .NOTES
		SiteTroopers
        
#>

#report entry class
Class ReportEntry {
    [Sitecore.Data.Items.Item]$item
    [System.Object[]]$diffFields
    [System.Object[]]$missingFields
}

#start up variables
$editDatabase = "master"
$publishDatabase = "web"
$report = @()
$root = Get-Item -Path (@{$true="$($editDatabase):\content\home"; $false="$($editDatabase):\content"}[(Test-Path -Path "$($editDatabase):\content\home")])

#retrieve settings
$settings = @{
    Title = "Deep Content Comparison"
    ShowHint = $true
    OkButtonName = "Run Report"
    CancelButtonName = "Cancel"
    Description = "Compare content between Master and Web field by field"
    Parameters = @(
        @{
            Name="root"
            Title="Choose Start Item"
            Tooltip="Report will run only for items under this tree"
            Root="/sitecore/content/"
        }
    )
    Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

$result = Read-Variable @settings
if($result -ne "ok") {
    Exit
}

filter Where-DeepCompare {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Sitecore.Data.Items.Item]$item
    )

    if ($item) {
	
        $latestMasterItem = $item.Versions.GetLatestVersion()
		$webItem = [Sitecore.Data.Database]::GetDatabase("web").GetItem($item.Id)
		
		if ($webItem){
			$latestWebItem = $webItem.Versions.GetLatestVersion()
			
			#Compare 
            $ATemplate = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($latestMasterItem)
            $BTemplate = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($latestWebItem)
            
            $AAFields = $ATemplate.OwnFields + $ATemplate.Fields | Select-Object -ExpandProperty key -Unique
            $BBFields = $BTemplate.OwnFields + $BTemplate.Fields | Select-Object -ExpandProperty key -Unique
            
            $AFields = $ATemplate.GetFields($false).Name
            $BFields = $BTemplate.GetFields($false).Name
            
            $ABMissingFields = Compare-Object -ReferenceObject ($AFields) -DifferenceObject ($BFields) -PassThru
            $AvailableFields = $AFields | Where-Object { $BFields -contains $_ }
            
            $diff = @()

            foreach($cFields in $AvailableFields) {
                $aField = $latestMasterItem.Fields[$cFields].Value
                $bField = $latestWebItem.Fields[$cFields].Value
    
                if ($aField -ne $bField){
                    $diff += $cFields
                }
            }
            
            $reportEntry = [ReportEntry]::New()
            $reportEntry.item = $item
            $reportEntry.diffFields = $diff
            $reportEntry.missingFields = $ABMissingFields
			
			if ($diff.Count -ne 0) {
                $reportEntry
			}
		}
    }
}

$items = @($root) + @(($root.Axes.GetDescendants() | Initialize-Item)) | Where-DeepCompare

if($items.Count -eq 0) {
    Show-Alert "No differences found"
} else {
    $props = @{
        Title = "Item Field Difference"
        InfoTitle = "Items with different values or fields on web db vs master"
        InfoDescription = "Items with different values or fields on web db vs master"
        PageSize = 25
    }

    $items |
        Show-ListView @props -Property @{Label="Icon"; Expression={$_.item.__Icon} },
            @{Label="Name"; Expression={$_.item.DisplayName} },
            @{Label="Updated"; Expression={$_.item.__Updated} },
            @{Label="Updated by"; Expression={$_.item."__Updated by"} },
            @{Label="Created"; Expression={$_.item.__Created} },
            @{Label="Created by"; Expression={$_.item."__Created by"} },
            @{Label="Path"; Expression={$_.item.ItemPath} },
            @{Label="Different Fields"; Expression={[system.String]::Join(", ", $_.diffFields)} },
            @{Label="Missing Fields"; Expression={[system.String]::Join(", ", $_.missingFields)} }
}

Close-Window