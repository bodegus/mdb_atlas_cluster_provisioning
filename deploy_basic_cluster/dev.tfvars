cluster_name = "e-clus-dev"

regions = [
  {
    name          = "US_EAST_1"
    node_count    = 3
    shard_number  = 1
    instance_size = "M30"
  }
]

auto_scaling = {
  compute_enabled = false
}

termination_protection_enabled = false

# Customer meta data
environment = "dev"
team        = "DevOps"
application = "MongoDB Atlas Example"
department  = "Engineering"
app_version = "1.0.0"
email       = "devops@example.com"
criticality = "low"
