1:  Create a key vault:
    New-AzKeyVault -Name "<your-unique-keyvault-name>" -ResourceGroupName "myResourceGroup" -Location "EastUS"

2:  Give your user account permissions to manage secrets in Key Vault:
    Set-AzKeyVaultAccessPolicy -VaultName "<your-unique-keyvault-name>" -UserPrincipalName "user@domain.com" -PermissionsToSecrets get,set,delete

3:  Adding a secret to Key Vault:
    $secretvalue = ConvertTo-SecureString "<password>" -AsPlainText -Force

4:  Then use the Azure PowerShell Set-AzKeyVaultSecret cmdlet to create a secret in Key Vault called ExamplePassword with the value hVFkk965BuUv:
    $secret = Set-AzKeyVaultSecret -VaultName "kv-eng" -Name "jfrog-username" -SecretValue $secretvalue

5:  Retrieve a secret from Key Vault
    secret = Get-AzKeyVaultSecret -VaultName "kv-eng" -Name "ExamplePassword" -AsPlainText