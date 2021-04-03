resource "google_storage_bucket" "static_backend_bucket" {
  for_each = local.all_env

  name          = "${lower(var.environment_name)}${lower(var.identifier)}-${each.key}-bucket"
  storage_class = "STANDARD"

  # Always use uniform bucket-level access for default bucket.
  uniform_bucket_level_access = each.key == "default" ? true : false

  website {
    main_page_suffix = "index.html"
    not_found_page   = local.not_found
  }

  # Dynamics are here to make advanced options conditional
  # We don't need them on "default" bucket

  dynamic "cors" {
    for_each = each.key == "default" ? [] : [null]

    content {
      origin          = ["*"]
      response_header = ["Content-Type"]
      method          = ["GET", "HEAD", "DELETE"]
      max_age_seconds = 3600
    }
  }

  dynamic "versioning" {
    for_each = each.key == "default" ? [] : [null]

    content {
      enabled = true
    }
  }

  dynamic "lifecycle_rule" {
    for_each = each.key == "default" ? [] : [null]

    content {
      action {
        type = "Delete"
      }

      condition {
        num_newer_versions = 3
      }
    }
  }

  location      = var.bucket_location
  force_destroy = true
}

# Create 404 handler for default backend ####################

resource "google_storage_bucket_object" "page-not-found" {
  for_each = local.default_env

  name    = local.not_found
  content = "PAGE NOT FOUND"
  bucket  = google_storage_bucket.static_backend_bucket[each.key].name
}

# Uniform bucket-level access: grant public readability at the bucket level:
# https://cloud.google.com/storage/docs/access-control/making-data-public#buckets

resource "google_storage_bucket_iam_binding" "staticbackend-iam-public-read-no-list" {
  for_each = local.default_env

  bucket  = google_storage_bucket.static_backend_bucket[each.key].name
  role    = "roles/storage.legacyObjectReader"
  members = [
    "allUsers",
  ]
}
