# =========================
# CWPP AKS Lab Delete Script
# =========================

$RG="rg-cwpp-lab"
$ACR_NAME="cwpplabacr123"
$AKS_NAME="aks-cwpp-lab"


Write-Host "Deleting AKS..."

az aks delete `
 --resource-group $RG `
 --name $AKS_NAME `
 --yes


Write-Host "Deleting ACR..."

az acr delete `
 --resource-group $RG `
 --name $ACR_NAME `
 --yes


Write-Host "Cleanup completed"