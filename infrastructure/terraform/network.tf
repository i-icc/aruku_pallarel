data "google_project" "current" {
  project_id = var.project_id
}

resource "google_compute_network" "main" {
  name                    = var.network_name
  auto_create_subnetworks = false
  depends_on              = [google_project_service.services]
}

resource "google_compute_subnetwork" "main" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id
}

resource "google_compute_subnetwork_iam_member" "serverless_network_user" {
  subnetwork = google_compute_subnetwork.main.name
  region     = var.region
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:service-${data.google_project.current.number}@serverless-robot-prod.iam.gserviceaccount.com"
}
