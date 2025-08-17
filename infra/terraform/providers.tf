variable "cloudflare_api_token" {
  type      = string
  sensitive = true
  description = "Cloudflare API token with least-privilege (Workers:Edit, D1:Edit)"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
