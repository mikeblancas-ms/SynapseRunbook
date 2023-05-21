param(
    [parameter(Mandatory=$true)] 
    [string] $RGName,
    [parameter(Mandatory=$true)] 
    [string] $SynWSName,
    [parameter(Mandatory=$true)] 
    [string] $SynDPName,
    [parameter(Mandatory=$true)] 
    [string] $SubscriptionName,
    [parameter(Mandatory=$true)] 
    [string] $SKU,
    [int] $RetryTime = 60,
    [int] $cRetry = 1
)

Connect-AzAccount -Identity
Set-AzContext -SubscriptionName $SubscriptionName
$DWProps = Get-AzSynapseSqlPool -ResourceGroupName $RGName -Workspacename $SynWSName -name $SynDPName

$DWStatus = $DWProps.Status
$DWSku = $DWProps.Sku

if ($DWStatus -eq "Online" -and $DWSku -ne $SKU) {
    Update-AzSynapseSqlPool -ResourceGroupName $RGName -Workspacename $SynWSName -name $SynDPName -PerformanceLevel  $SKU
    Write-Verbose "Scaling $SynDPName to $SKU"

    do {
        Start-Sleep -Seconds $RetryTime
        $DWStatus = (Get-AzSynapseSqlPool -ResourceGroupName $RGName -Workspacename $SynWSName -name $SynDPName).Status
        Write-Verbose "$SynDPName is $DWStatus [$cRetry]"
        $cRetry++
    } while ($DWStatus -eq "Scaling")

    Get-AzSynapseSqlPool -ResourceGroupName $RGName -Workspacename $SynWSName -name $SynDPName
} else {
    Write-Error "Error in Scaling SQL Dedicated Pool"
}
