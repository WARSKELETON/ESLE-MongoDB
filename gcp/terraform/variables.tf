variable "project_id" {
  description = "project id"
}

variable "region" {
  description = "region"
}

variable "gke_num_nodes" {
  default     = 1
  description = "number of gke nodes" # this is the number of nodes per zone
}

variable "machine_type" {
  default     = "n2-standard-1"
}
