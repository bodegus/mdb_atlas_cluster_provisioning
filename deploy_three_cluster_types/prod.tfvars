cluster_name = "e-clus-prod"
cluster_type = "GEOSHARDED"
regions = [
  {
    name       = "US_EAST_1"
    node_count = 3
    zone_name  = "US"
  },
  {
    name       = "US_EAST_2"
    node_count = 3
    zone_name  = "FLORIDA"
  }
]

termination_protection_enabled = false

environment = "prod"
team        = "DevOps"
application = "MongoDB Atlas Example"
department  = "Engineering"
app_version = "1.0.0"
email       = "devops@example.com"
criticality = "high"
