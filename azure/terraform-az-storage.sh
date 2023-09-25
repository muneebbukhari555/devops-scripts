#!/bin/bash

show_help() {
    echo "Usage: ./script.sh [options]"
    echo "Options:"
    echo "  -k, --key-vault       Key Vault name"
    echo "  -n, --sa-name         Storage Account name"
    echo "  -s, --subscription    Azure subscription"
    echo "  -m, --mode            Script mode"
    exit 1
}

# Read parameters required
while getopts k:n:s:m:h: flag
do
  case "${flag}" in
    k) key_vault=${OPTARG};;
    n) sa_name=${OPTARG};;
    s) subscription=${OPTARG};;
    m) mode=${OPTARG};;
    h)
        show_help
        ;;
    *)
        echo "Invalid option: $key"
        show_help
        exit 1
        ;;
  esac
done

# Check if all required arguments are provided
if [[ -z $key_vault || -z $sa_name || -z $subscription || -z $mode ]]; then
    echo "Missing required arguments."
    show_help
    exit 1
fi

export key_vault=$key_vault
export sa_name=$sa_name
export subscription=$subscription
export mode=$mode
 
#Login to Azure portal and run the helmsman script
AZURE_CLIENT_ID=$(az keyvault secret show --name "az-$subscription-sp-svc-clientid" --vault-name "$key_vault" --query 'value' --output tsv)
AZURE_CLIENT_SECRET=$(az keyvault secret show --name "az-$subscription-sp-svc-clientsecret" --vault-name "$key_vault" --query 'value' --output tsv)
AZURE_TENANT_ID=$(az keyvault secret show --name "az-$subscription-sp-svc-tenantid" --vault-name "$key_vault" --query 'value' --output tsv)
AZURE_SUBS_ID=$(az keyvault secret show --name "az-$subscription-sp-svc-subid" --vault-name "$key_vault" --query 'value' --output tsv)


MODIFIED_FILE_PATH="$subscription/$sa_name.tfvars"

echo "AZURE_CLIENT_ID: $AZURE_CLIENT_ID";
echo "AZURE_TENANT_ID: $AZURE_TENANT_ID";
echo "AZURE_SUB_ID: $AZURE_SUBS_ID";
echo "$MODIFIED_FILE_PATH";
echo "mode: $mode";
echo "-----------------------"

export ARM_SUBSCRIPTION_ID=$AZURE_SUBS_ID
export ARM_CLIENT_ID=$AZURE_CLIENT_ID
export ARM_CLIENT_SECRET=$AZURE_CLIENT_SECRET
export ARM_TENANT_ID=$AZURE_TENANT_ID
export TF_VAR_subscription_id=$AZURE_SUBS_ID
export TF_VAR_client_id=$AZURE_CLIENT_ID
export TF_VAR_client_secret=$AZURE_CLIENT_SECRET
export TF_VAR_tenant_id=$AZURE_TENANT_ID

#Login to Azure portal and run the terraform script 
az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET -t $AZURE_TENANT_ID
az account set --subscription $AZURE_SUBS_ID

terraform init      
terraform plan -var-file=./env-tfvars/$MODIFIED_FILE_PATH
echo "********TERRAFORM_APPLY_START********"
terraform $mode -auto-approve -var-file=./env-tfvars/$MODIFIED_FILE_PATH
echo "********TERRAFORM_APPLY_ENDS********"
