locals {
  firestore_rules_path = "${path.module}/../firebase/firestore.rules"
  firestore_indexes    = jsondecode(file("${path.module}/../firebase/firestore.indexes.json"))
}

resource "google_firebaserules_ruleset" "firestore" {
  provider = google-beta
  project  = var.project_id

  source {
    files {
      name    = "firestore.rules"
      content = file(local.firestore_rules_path)
    }
  }

  depends_on = [google_firebase_project.default]
}

resource "google_firebaserules_release" "firestore" {
  provider     = google-beta
  project      = var.project_id
  name         = "cloud.firestore"
  ruleset_name = google_firebaserules_ruleset.firestore.name
}

resource "google_firestore_index" "indexes" {
  for_each = {
    for index, item in local.firestore_indexes.indexes :
    "${index}-${item.collectionGroup}-${item.queryScope}" => item
  }

  project     = var.project_id
  database    = google_firestore_database.default.name
  collection  = each.value.collectionGroup
  query_scope = each.value.queryScope

  dynamic "fields" {
    for_each = each.value.fields
    content {
      field_path  = fields.value.fieldPath
      order       = lookup(fields.value, "order", null)
      array_config = lookup(fields.value, "arrayConfig", null)
    }
  }

  depends_on = [google_firestore_database.default]
}
