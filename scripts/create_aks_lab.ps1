# =========================
# CWPP AKS Lab Create Script
# =========================

$RG="rg-cwpp-lab"
$LOCATION="centralindia"

$ACR_NAME="cwpplabacr123"
$AKS_NAME="aks-cwpp-lab"

$GITHUB_APP_ID="2d4e1dff-f101-4ee4-bf89-6000997fe7e9"


Write-Host "Creating Resource Group..."

az group create `
 --name $RG `
 --location $LOCATION


Write-Host "Creating ACR..."

az acr create `
 --resource-group $RG `
 --name $ACR_NAME `
 --sku Basic


$ACR_ID = az acr show `
 --name $ACR_NAME `
 --query id `
 -o tsv


Write-Host "Assigning GitHub OIDC AcrPush..."

az role assignment create `
 --assignee $GITHUB_APP_ID `
 --role AcrPush `
 --scope $ACR_ID


Write-Host "Creating AKS Free Tier..."

az aks create `
 --resource-group $RG `
 --name $AKS_NAME `
 --tier free `
 --node-count 1 `
 --node-vm-size Standard_B2s `
 --enable-managed-identity `
 --attach-acr $ACR_NAME `
 --generate-ssh-keys


Write-Host "Getting AKS Credentials..."

az aks get-credentials `
 --resource-group $RG `
 --name $AKS_NAME `
 --overwrite-existing


Write-Host "Creating Namespaces..."

kubectl create namespace cwpp-dev --dry-run=client -o yaml | kubectl apply -f -

kubectl create namespace cwpp-test --dry-run=client -o yaml | kubectl apply -f -

kubectl create namespace cwpp-prod --dry-run=client -o yaml | kubectl apply -f -

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -


Write-Host "Installing Argo CD..."

kubectl apply `
 --server-side `
 -n argocd `
 -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


Write-Host "Done"

Write-Host "ACR:"
az acr show `
 --name $ACR_NAME `
 --query loginServer `
 -o tsv

 