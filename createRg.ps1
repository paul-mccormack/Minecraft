# Parameters
$RGroupName = "rg-uks-sandbox-github-actions-paulmc"
$RGroupLocation = "UK South"
## Add/Modify Tags
$ResourceGroupTags = @{
"Created By" = "Paul McCormack"; 
"Environment" = "Training";
"Service" = "Training";
"Management Area" = "DDaT";
"Recharge" = "DDaT";
}

# Create Resource Group
New-AzResourceGroup -Name $RGroupName -Location $RGroupLocation -Tag $ResourceGroupTags