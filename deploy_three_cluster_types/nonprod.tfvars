cluster_name = "e-clus-nonprod"
cluster_type = "SHARDED"
regions = [
  {
    name         = "US_EAST_1"
    node_count   = 3
    shard_number = 1
  }
]

termination_protection_enabled = false

# Customer meta data
environment = "nonprod"
team        = "DevOps"
application = "MongoDB Atlas Example"
department  = "Engineering"
app_version = "1.0.0"
email       = "devops@example.com"
criticality = "medium"
