resource "google_cloud_tasks_queue" "suggest" {
  name     = var.tasks_queue_name
  location = var.region

  depends_on = [google_project_service.services]
}
