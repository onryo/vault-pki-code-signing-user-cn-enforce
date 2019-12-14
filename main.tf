provider "vault" {}

resource "vault_ldap_auth_backend" "ldap" {
  path         = "ldap"
  url          = "ldaps://${var.ldaps_server}"
  userdn       = var.ldaps_userdn
  userattr     = "uid"
  discoverdn   = false
  groupdn      = var.ldaps_groupdn
  insecure_tls = false
  starttls     = true
  certificate  = file(var.ldaps_ca_file)
}

resource "vault_policy" "ldap_code_sign" {
  name = "ldap_code_sign"

  policy = file("pki_policy.hcl")
}

resource "vault_egp_policy" "code_sign_user_cn_enforce" {
  name              = "code_sign_user_cn_enforce"
  paths             = ["/pki/issue/code_sign"]
  enforcement_level = "hard-mandatory"

  policy = data.template_file.code_sign_user_cn_enforce.rendered
}

data "template_file" "code_sign_user_cn_enforce" {
  template = file("code_sign_user_cn_enforce.sentinel.tpl")
  vars = {
    valid_domain = var.code_sign_user_cn_valid_domain
  }
}

resource "vault_ldap_auth_backend_group" "group" {
  groupname = "users"
  policies  = ["ldap_code_sign"]
  backend   = vault_ldap_auth_backend.ldap.path
}

resource "vault_mount" "pki" {
  path                      = "pki"
  type                      = "pki"
  default_lease_ttl_seconds = 86400
  max_lease_ttl_seconds     = 31536000
}

resource "vault_pki_secret_backend_config_urls" "config_urls" {
  backend                 = "${vault_mount.pki.path}"
  issuing_certificates    = ["http://127.0.0.1:8200/v1/pki/ca"]
  crl_distribution_points = ["http://127.0.0.1:8200/v1/pki/crl"]
}

resource "vault_pki_secret_backend_root_cert" "code_sign_root_ca" {
  depends_on = ["vault_mount.pki"]

  backend = vault_mount.pki.path

  type                 = "internal"
  common_name          = "Acme Corp - Code Signing Root CA"
  ttl                  = 31536000
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 4096
  exclude_cn_from_sans = true
  ou                   = "Information Technology"
  organization         = "Acme Corp"
  country              = "US"
  locality             = "Seattle"
  province             = "Washington"
}

resource "vault_pki_secret_backend_role" "code_sign" {
  backend = vault_mount.pki.path

  name              = "code_sign"
  ttl               = 86400
  max_ttl           = 86400
  code_signing_flag = true
  allow_any_name    = true
  key_type          = "rsa"
  key_bits          = 4096
  key_usage         = ["DigitalSignature"]
  ou                = ["Information Technology"]
  organization      = ["Acme Corp"]
  country           = ["US"]
  locality          = ["Seattle"]
  province          = ["Washington"]
}
