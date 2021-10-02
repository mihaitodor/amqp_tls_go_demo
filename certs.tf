resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm     = "RSA"
  private_key_pem   = tls_private_key.ca.private_key_pem
  is_ca_certificate = true

  subject {
    common_name = "rabbitmq.ca"
  }

  validity_period_hours = 43800

  allowed_uses = [
    "keyCertSign",
    "cRLSign",
  ]
}

resource "tls_private_key" "client" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "client" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.client.private_key_pem

  subject {
    # rabbitmq client username is included in the certificate
    common_name = "guest"
  }
}

resource "tls_locally_signed_cert" "client" {
  cert_request_pem   = tls_cert_request.client.cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

resource "local_file" "ca_cert_pem" {
  content  = tls_self_signed_cert.ca.cert_pem
  filename = "ca-cert.pem"
}

resource "local_file" "client_cert_pem" {
  content  = tls_locally_signed_cert.client.cert_pem
  filename = "client-cert.pem"
}

resource "local_file" "client_privkey_pem" {
  content  = tls_private_key.client.private_key_pem
  filename = "client-privkey.pem"
}
