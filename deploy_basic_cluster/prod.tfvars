cluster_name = "e-clus-prod"

regions = [
  {
    name       = "US_EAST_1"
    node_count = 3
    #node_count_analytics = 1
    shard_number = 1

  },
  {
    name       = "US_EAST_2"
    node_count = 2
    #node_count_analytics = 1
    shard_number = 1

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
