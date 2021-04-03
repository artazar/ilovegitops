resource "google_service_account" "sa" {
  account_id   = "${lower(var.environment_name)}${lower(var.identifier)}-cdn-sa"
  display_name = "Created by terraform for giving RW access to ${lower(var.environment_name)} buckets for CI/CD pipelines"
}

output "email-sa" {
  description = "CI/CD service account email"
  value       = google_service_account.sa.email
}

resource "google_storage_bucket_iam_member" "staticbackend-iam-read-write" {
  for_each = local.all_env
  bucket   = google_storage_bucket.static_backend_bucket[each.key].name
  role     = "roles/storage.admin"
  member   = "serviceAccount:${google_service_account.sa.email}"
}
