resource "google_service_account" "backend" {
  account_id   = "run-backend-sa"
  display_name = "Cloud Run Backend"
}

resource "google_service_account" "adk" {
  account_id   = "run-adk-sa"
  display_name = "Cloud Run ADK"
}

resource "google_service_account" "osm" {
  account_id   = "run-osm-sa"
  display_name = "Cloud Run OSM"
}

resource "google_service_account" "job" {
  account_id   = "run-job-sa"
  display_name = "Cloud Run Job"
}

resource "google_service_account" "tasks_invoker" {
  account_id   = "tasks-invoker-sa"
  display_name = "Cloud Tasks Invoker"
}
