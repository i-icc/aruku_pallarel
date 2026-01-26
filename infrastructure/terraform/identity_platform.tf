resource "google_identity_platform_config" "default" {
  provider = google-beta
  project  = var.project_id

  sign_in {
    allow_duplicate_emails = false
    email {
      enabled           = true
      password_required = true
    }
    phone_number {
      enabled = false
    }
  }

  multi_tenant {
    allow_tenants = false
  }

  depends_on = [google_project_service.services]
}
