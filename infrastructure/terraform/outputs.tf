output "backend_url" {
  value = google_cloud_run_v2_service.backend.uri
}

output "adk_url" {
  value = google_cloud_run_v2_service.adk.uri
}

output "osm_url" {
  value = google_cloud_run_v2_service.osm.uri
}

output "job_name" {
  value = google_cloud_run_v2_job.suggest.name
}

output "tasks_queue_name" {
  value = google_cloud_tasks_queue.suggest.name
}

output "tasks_invoker_service_account" {
  value = google_service_account.tasks_invoker.email
}

output "github_wif_provider_name" {
  value = google_iam_workload_identity_pool_provider.github_actions.name
}

output "github_actions_service_account_email" {
  value = google_service_account.github_actions.email
}
