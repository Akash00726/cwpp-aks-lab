#!/bin/bash

# ==========================
# CWPP AKS + ACR DELETE
# ==========================


RG="rg-cwpp-lab"

AKS_NAME="aks-cwpp-lab"

ACR_NAME="cwpplabacr123"


echo "Deleting AKS..."

az aks delete \
--resource-group $RG \
--name $AKS_NAME \
--yes


echo "Deleting ACR..."

az acr delete \
--resource-group $RG \
--name $ACR_NAME \
--yes


echo "Checking remaining resources..."

az resource list \
--resource-group $RG \
-o table


echo "Cleanup completed"