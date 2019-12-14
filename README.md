# Vault PKI for Code Signing Common Name Enforcement Example

## Description
Terraform code for provisioning a code signing CA with sentinel enforcement of common_name field.

## Inputs
- ldaps_server - Hostname of LDAPS server
- ldaps_userdn - Base DN under which to perform user search
- ldaps_groupdn - Base DN under which to perform group search
- ldaps_ca_file - CA certificate file for LDAPS server
- code_sign_user_cn_valid_domain - Email domain to validate against CN in code signing certificate requests
