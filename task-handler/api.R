library(plumber)
library(googleComputeEngineR)
library(future)

#* Healtcheck
#* @get /healthcheck
function() {
  "ok"
}

#* Start a new runner with specified options
#*
#* @post vm_create
function(instance_id, labels, gpu) {
  gpu <- as.numeric(gpu)
  start_gce_vm(instance_id, labels, gpu)
}

#* Start a new runner with specified options
#*
#* @post vm_delete
function(instance_id) {
  googleComputeEngineR::gce_vm_delete(
    instances = instance_id,
    project = googleComputeEngineR::gce_get_global_project(),
    zone = googleComputeEngineR::gce_get_global_zone()
  )
}

#* Install the GPU drivers
#*
#* @assets ./driver /driver
list()

startup_script <- function(org, labels, gpu) {
  token <- gh::gh("POST /orgs/{org}/actions/runners/registration-token", org = org)

  if (grepl("windows", labels)) {
    meta_name <- "windows-startup-script-ps1"
    bootstrap <- readr::read_file("bootstrap-win.ps1")
    glue_open <- "<"
    glue_close <- ">"
  } else {
    meta_name <- "startup-script"
    bootstrap <- readr::read_file("bootstrap.sh")
    glue_open <- "{"
    glue_close <- "}"
  }

  out <- list()
  out[[meta_name]] <- glue::glue(
    bootstrap,
    org = org,
    runner_token = token$token,
    labels = labels,
    .open = glue_open,
    .close = glue_close
  )
  out
}

start_gce_vm <- function(instance_id, labels, gpu) {
  if (grepl("windows", labels)) {
    image_project <- "windows-cloud"
    image_family <- "windows-2019"
  } else {
    image_project <- "ubuntu-os-cloud"
    image_family <- "ubuntu-2204-lts"
  }

  metadata <- list()
  metadata <- append(metadata, startup_script(
    org = "mlverse",
    labels = labels,
    gpu = gpu
  ))

  out <- capture.output(
    x <- try(googleComputeEngineR::gce_vm(
      instance_id,
      image_project = image_project,
      image_family = image_family,
      predefined_type = "n1-standard-4",
      disk_size_gb = 90,
      project = googleComputeEngineR::gce_get_global_project(),
      zone = googleComputeEngineR::gce_get_global_zone(),
      metadata = metadata,
      acceleratorCount = if (gpu) 1 else NULL,
      acceleratorType = if (gpu) "nvidia-tesla-t4" else "",
      scheduling = list(
        'preemptible' = TRUE
      )
    ))
  )

  if (grepl(out, "ZONE_RESOURCE_POOL_EXHAUSTED_WITH_DETAILS")) {
    stop("Could not start the VM. THe zone doesn't have the resouce. Try again in a few minutes.")
  }

  if (inherits(x, "try-error")) {
    stop("Unknown error when starting the VM.")
  }
}
