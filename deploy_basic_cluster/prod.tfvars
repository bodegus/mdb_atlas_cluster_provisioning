cluster_name = "e-clus-prod"
environment  = "prod"
regions = [
  {
    name       = "US_EAST_1"
    node_count = 3
  },
  {
    name       = "US_EAST_2"
    node_count = 2
  },
  {
    name       = "US_WEST_1"
    node_count = 2
  }
]
