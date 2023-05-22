PROJECT_ID <- "rstudio-cloudml"
REGION_ID <- "us-central1"
ZONE_ID <- paste0(REGION_ID, "-f")

token <- gargle::credentials_service_account(
  scopes = "https://www.googleapis.com/auth/cloud-platform",
  path = Sys.getenv("GCE_AUTH_FILE")
)

gce_request_build <- function(..., method = "POST", params = NULL, path="") {
  gargle::request_build(
    base_url = "https://compute.googleapis.com",
    method = method,
    path = paste0("/compute/v1/projects/{project}/zones/{zone}/instances", path),
    params = append(list(project = PROJECT_ID, zone = ZONE_ID), params),
    ...,
    token = token
  )
}

gce_request_make <- function(req, ...) {
  tryCatch({
    httr::content(gargle::request_make(req, ...), as = "parsed")
  }, error = function(e) {
    list(error = list(errors = list(code = "501", message = "Unknown error: ", e$message)))
  })
}

instance_from_config <- function(name, ..., .sourceImage = NULL, .machineType = NULL) {
  if (is.null(.sourceImage)) {
    .sourceImage <- "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20230425"
  }
  if (is.null(.machineType)) {
    .machineType <- glue::glue("zones/{ZONE_ID}/machineTypes/n1-standard-4")
  }

  .subnetwork <- glue::glue("projects/{PROJECT_ID}/regions/{REGION_ID}/subnetworks/default")

  default_instance <- list(
    name = name,
    disks = list(
      list(
        boot = TRUE,
        autoDelete = TRUE,
        initializeParams = list(
          diskSizeGb = "120",
          sourceImage = .sourceImage
        )
      )
    ),
    networkInterfaces = list(
      list(
        subnetwork = .subnetwork,
        accessConfigs = list(
          list(
            type = "ONE_TO_ONE_NAT"
          )
        )
      )
    ),
    machineType = .machineType
  )
  purrr::list_modify(default_instance, ...)
}

vm_insert <- function(name, ...) {
  req <- gce_request_build(
    params = list(
      project = PROJECT_ID,
      zone = ZONE_ID
    ),
    body = jsonlite::toJSON(instance_from_config(name, ...), auto_unbox = TRUE)
  )
  gce_request_make(req, encode = "raw")
}

vm_delete <- function(name) {
  req <- gce_request_build(
    path = "/{name}",
    method = "DELETE",
    params = list(
      name = name
    )
  )
  gce_request_make(req)
}
