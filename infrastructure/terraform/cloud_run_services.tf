resource "google_cloud_run_v2_service" "backend" {
  name     = var.backend_service_name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.backend.email

    containers {
      image = var.backend_image
      env {
        name  = "PROJECT_ID"
        value = var.project_id
      }
      env {
        name  = "REGION"
        value = var.region
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
      env {
        name  = "TASKS_QUEUE"
        value = google_cloud_tasks_queue.suggest.name
      }
      env {
        name  = "TASKS_LOCATION"
        value = var.region
      }
      env {
        name  = "TASKS_TARGET_URL"
        value = "${google_cloud_run_v2_service.suggest_job.uri}/jobs/suggestions"
      }
      env {
        name  = "TASKS_INVOKER_SERVICE_ACCOUNT"
        value = google_service_account.tasks_invoker.email
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

  depends_on = [google_project_service.services]
}

resource "google_cloud_run_v2_service" "adk" {
  name     = var.adk_service_name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.adk.email

    containers {
      image = var.adk_image
      env {
        name  = "GOOGLE_GENAI_USE_VERTEXAI"
        value = "TRUE"
      }
      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = var.project_id
      }
      env {
        name  = "GOOGLE_CLOUD_LOCATION"
        value = "global"
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

  depends_on = [google_project_service.services]
}

resource "google_cloud_run_v2_service" "osm" {
  name     = var.osm_service_name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.osm.email

    containers {
      image = var.osm_image
    }

    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"
      network_interfaces {
        network    = google_compute_network.main.id
        subnetwork = google_compute_subnetwork.main.id
      }
    }
  }

  depends_on = [google_project_service.services]
}

resource "google_cloud_run_v2_service" "suggest_job" {
  name     = var.suggest_job_service_name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

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

  depends_on = [google_project_service.services]
}
