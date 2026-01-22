locals {
  job_image_resolved = var.job_image != "" ? var.job_image : var.backend_image
}

resource "google_cloud_run_v2_job" "suggest" {
  name     = var.job_name
  location = var.region

  template {
    template {
      service_account = google_service_account.job.email

      containers {
        image = local.job_image_resolved
        env {
          name  = "PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "REGION"
          value = var.region
        }
        env {
          name  = "ENABLE_JOB_ENDPOINTS"
          value = "true"
        }
        env {
          name  = "ADK_BASE_URL"
          value = google_cloud_run_v2_service.adk.uri
        }
        env {
          name  = "ADK_APP_NAME"
          value = var.adk_app_name
        }
        env {
          name  = "ADK_ID_TOKEN_AUDIENCE"
          value = google_cloud_run_v2_service.adk.uri
        }
        env {
          name  = "OSM_BASE_URL"
          value = google_cloud_run_v2_service.osm.uri
        }
        env {
          name  = "OSM_ID_TOKEN_AUDIENCE"
          value = google_cloud_run_v2_service.osm.uri
        }
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
