#!/bin/bash

#################################################################
#                        USAGE:                                 #
#  write-secrets-to-kv.sh -n kv-eng-dev -f secrets.txt          #
#  -n is the name of key vault                                  #
#  -f is the file containing secrets                            #
#  see secrets.txt file for the format of secrets               #
#################################################################

# Read Key Vault name and secrets file name
while getopts n:f: flag
do
    case "${flag}" in
        n) key_vault_name=${OPTARG};;
        f) file_name=${OPTARG};;
    esac
done
echo "key_vault_name: $key_vault_name";
echo "file_name: $file_name"; 

# Read secrets file name into array
secrets=()
i=1
while read line; do  
    secrets+=($line)  
    i=$((i+1))  
done < $file_name

# Loop through the secrets and create them in the Key Vault
for secret_info in "${secrets[@]}"; do
    secret_name="${secret_info%%:*}"
    secret_value="${secret_info#*:}"
    az keyvault secret set --name "$secret_name" --vault-name "$key_vault_name" --value "$secret_value"
done