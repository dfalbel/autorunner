PROJECT_ID <- "rstudio-cloudml"
LOCATION_ID <- "us-central1"
QUEUE_ID <- "gh-actions"

token <- gargle::credentials_service_account(
  scopes = "https://www.googleapis.com/auth/cloud-platform",
  path = Sys.getenv("GCE_AUTH_FILE")
)

cloud_tasks_request <- function(..., method) {
  req <- gargle::request_build(
    method = method,
    path = "v2/projects/{PROJECT_ID}/locations/{LOCATION_ID}/queues/{QUEUE_ID}/tasks",
    params = list(
      PROJECT_ID = PROJECT_ID,
      LOCATION_ID = LOCATION_ID,
      QUEUE_ID = QUEUE_ID
    ),
    ...,
    token = token,
    base_url = "https://cloudtasks.googleapis.com/v2/"
  )
  out <- gargle::request_make(req)
  httr::content(out, "parsed")
}


tasks_list() <- function() {
  cloud_tasks_request(method = "GET")
}

tasks_create_vm <- function(instance_id, labels, gpu) {
  cloud_tasks_request(
    method = "POST",
    body = list(
      task = list(
        httpRequest = list(
          url = paste0(Sys.getenv("SERVICE_URL"), "vm_create"),
          httpMethod = "POST",
          body = openssl::base64_encode(jsonlite::toJSON(auto_unbox = TRUE, list(
            instance_id = instance_id,
            labels = labels,
            gpu = gpu
          )))
        )
      )
    )
  )
}

tasks_delete_vm <- function(instance_id) {
  cloud_tasks_request(
    method = "POST",
    body = list(
      task = list(
        httpRequest = list(
          url = paste0(Sys.getenv("SERVICE_URL"), "vm_delete"),
          httpMethod = "POST",
          body = openssl::base64_encode(jsonlite::toJSON(auto_unbox = TRUE, list(
            instance_id = instance_id
          )))
        )
      )
    )
  )
}

