resource "google_cloud_run_v2_job" "suggest" {
  name     = var.job_name
  location = var.region

  template {
    template {
      service_account = google_service_account.job.email

      containers {
        image = var.job_image
      }

      vpc_access {
        egress = "PRIVATE_RANGES_ONLY"
        network_interfaces {
          network    = google_compute_network.main.id
          subnetwork = google_compute_subnetwork.main.id
        }
      }
    }
  }

  depends_on = [google_project_service.services]
}
