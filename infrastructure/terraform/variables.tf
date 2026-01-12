variable "project_id" {
  type        = string
  description = "GCP project ID."
}

variable "region" {
  type        = string
  description = "Default region."
  default     = "us-central1"
}

variable "firestore_location" {
  type        = string
  description = "Firestore database location."
  default     = "us-central1"
}

variable "network_name" {
  type        = string
  description = "VPC network name."
  default     = "aruku-vpc"
}

variable "subnet_name" {
  type        = string
  description = "VPC subnet name."
  default     = "aruku-subnet"
}

variable "subnet_cidr" {
  type        = string
  description = "VPC subnet CIDR."
  default     = "10.10.0.0/24"
}

variable "artifact_registry_repo" {
  type        = string
  description = "Artifact Registry repo ID."
  default     = "aruku-parallel"
}

variable "tasks_queue_name" {
  type        = string
  description = "Cloud Tasks queue name."
  default     = "suggest-jobs"
}

variable "backend_service_name" {
  type        = string
  description = "Cloud Run backend service name."
  default     = "backend"
}

variable "adk_service_name" {
  type        = string
  description = "Cloud Run ADK service name."
  default     = "adk"
}

variable "osm_service_name" {
  type        = string
  description = "Cloud Run OSM service name."
  default     = "osm"
}

variable "job_name" {
  type        = string
  description = "Cloud Run Job name."
  default     = "suggest-job"
}

variable "backend_image" {
  type        = string
  description = "Container image for backend."
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "adk_image" {
  type        = string
  description = "Container image for ADK."
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "osm_image" {
  type        = string
  description = "Container image for OSM."
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "job_image" {
  type        = string
  description = "Container image for job."
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}
