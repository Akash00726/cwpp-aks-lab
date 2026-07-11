#!/bin/bash

# ==========================
# CWPP AKS + ACR CREATE
# ==========================

RG="rg-cwpp-lab"
LOCATION="centralindia"

ACR_NAME="cwpplabacr123"
AKS_NAME="aks-cwpp-lab"

# GitHub OIDC App Client ID
GITHUB_APP_ID="2d4e1dff-f101-4ee4-bf89-6000997fe7e9"


echo "Creating Resource Group..."
az group create \
  --name $RG \
  --location $LOCATION


echo "Creating ACR Basic..."
az security pricing create \
  --name "Containers" \
  --tier "Free"

az acr create \
  --resource-group $RG \
  --name $ACR_NAME \
  --sku Basic

# Add a small delay to ensure resource propagation
echo "Waiting for ACR to be ready..."
sleep 5

echo "Getting ACR ID..."
# Stripping \r to prevent 'Invalid URL' errors if file has CRLF endings
ACR_ID=$(az acr show --name $ACR_NAME --query id -o tsv | tr -d '\r')


echo "Assigning AcrPush to GitHub OIDC..."
az role assignment create \
  --assignee $GITHUB_APP_ID \
  --role AcrPush \
  --scope $ACR_ID


echo "Creating AKS Free Tier..."
az aks create \
  --resource-group $RG \
  --name $AKS_NAME \
  --tier free \
  --node-count 1 \
  --node-vm-size Standard_B2s \
  --enable-managed-identity \
  --attach-acr $ACR_NAME \
  --generate-ssh-keys


echo "Connecting kubectl.exe..."
az aks get-credentials \
  --resource-group $RG \
  --name $AKS_NAME \
  --overwrite-existing


echo "Creating namespaces..."
kubectl.exe create ns cwpp-dev --dry-run=client -o yaml | kubectl.exe apply -f -
kubectl.exe create ns cwpp-test --dry-run=client -o yaml | kubectl.exe apply -f -
kubectl.exe create ns cwpp-prod --dry-run=client -o yaml | kubectl.exe apply -f -
kubectl.exe create ns argocd --dry-run=client -o yaml | kubectl.exe apply -f -


echo "Installing Argo CD..."
kubectl.exe apply \
--server-side \
-n argocd \
-f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


echo "AKS + ACR Ready"
echo "ACR Login Server:"
az acr show --name $ACR_NAME --query loginServer -o tsv

echo "Verify:"
kubectl.exe get nodes

kubectl apply -f argocd/application.yaml