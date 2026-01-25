locals {
  backend_roles = [
    "roles/logging.logWriter",
    "roles/cloudtasks.enqueuer",
    "roles/datastore.user",
    "roles/firebase.growthAdmin",
    "roles/aiplatform.user",
  ]

  job_roles = [
    "roles/logging.logWriter",
    "roles/datastore.user",
    "roles/firebase.growthAdmin",
    "roles/aiplatform.user",
  ]

  adk_roles = [
    "roles/logging.logWriter",
  ]

  osm_roles = [
    "roles/logging.logWriter",
  ]
}

resource "google_project_iam_member" "backend_roles" {
  for_each = toset(local.backend_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.backend.email}"
}

resource "google_project_iam_member" "job_roles" {
  for_each = toset(local.job_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.job.email}"
}

resource "google_project_iam_member" "adk_roles" {
  for_each = toset(local.adk_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.adk.email}"
}

resource "google_project_iam_member" "osm_roles" {
  for_each = toset(local.osm_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.osm.email}"
}

resource "google_cloud_run_v2_service_iam_member" "backend_public" {
  name     = google_cloud_run_v2_service.backend.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_service_iam_member" "adk_invoker_backend" {
  name     = google_cloud_run_v2_service.adk.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.backend.email}"
}

resource "google_cloud_run_v2_service_iam_member" "adk_invoker_job" {
  name     = google_cloud_run_v2_service.adk.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.job.email}"
}

resource "google_cloud_run_v2_service_iam_member" "osm_invoker_backend" {
  name     = google_cloud_run_v2_service.osm.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.backend.email}"
}

resource "google_cloud_run_v2_service_iam_member" "osm_invoker_job" {
  name     = google_cloud_run_v2_service.osm.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.job.email}"
}

resource "google_cloud_run_v2_job_iam_member" "job_invoker_tasks" {
  name     = google_cloud_run_v2_job.suggest.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.tasks_invoker.email}"
}

resource "google_cloud_run_v2_service_iam_member" "suggest_job_invoker_tasks" {
  name     = google_cloud_run_v2_service.suggest_job.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.tasks_invoker.email}"
}

resource "google_service_account_iam_member" "tasks_invoker_token_creator" {
  service_account_id = google_service_account.tasks_invoker.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-cloudtasks.iam.gserviceaccount.com"
}

resource "google_service_account_iam_member" "tasks_invoker_act_as" {
  service_account_id = google_service_account.tasks_invoker.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-cloudtasks.iam.gserviceaccount.com"
}

resource "google_service_account_iam_member" "tasks_invoker_act_as_backend" {
  service_account_id = google_service_account.tasks_invoker.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.backend.email}"
}
