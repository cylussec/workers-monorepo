# Placeholder Terraform configuration for Cloudflare resources.
# This workspace is configured to use Terraform Cloud via versions.tf.
# Add Cloudflare resources here as you adopt IaC (e.g., DNS, routes, KV, queues).
# NOTE: Avoid managing Worker routes here if you already define them in wrangler.jsonc,
#       to prevent drift or conflicts. Prefer one source of truth.

# Example (commented) for reference only:
# resource "cloudflare_workers_route" "prod_root" {
#   zone_id = var.zone_id
#   pattern = "busandbrew.com/*"
#   script_name = "workers-monorepo-prod"
# }

# variable "zone_id" {
#   description = "Cloudflare Zone ID for busandbrew.com"
#   type        = string
# }
