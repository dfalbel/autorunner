library(plumber)
library(googleComputeEngineR)
library(future)
source("pushover.R")

#* Healtcheck
#* @get /healthcheck
function() {
  "ok"
}

#* Start a new runner with specified options
#*
#* @post vm_create
function(instance_id, labels, gpu) {
  pushover("[HANDLER] -> CREATE", paste0("instance_id: ", instance_id))
  gpu <- as.numeric(gpu)
  start_gce_vm(instance_id, labels, gpu)
}

#* Start a new runner with specified options
#*
#* @post vm_delete
function(instance_id) {
  pushover("[HANDLER] -> DELETE", paste0("instance_id: ", instance_id))
  googleComputeEngineR::gce_vm_delete(
    instances = instance_id,
    project = googleComputeEngineR::gce_get_global_project(),
    zone = googleComputeEngineR::gce_get_global_zone()
  )
  pushover("[HANDLER] DELETE!", paste0("instance_id: ", instance_id))
}

#* Stop VM
#*
#* @post vm_stop
function(instance_id) {
  pushover("[HANDLER] -> STOP", paste0("instance_id: ", instance_id))
  googleComputeEngineR::gce_vm_stop(
    instances = instance_id,
    project = googleComputeEngineR::gce_get_global_project(),
    zone = googleComputeEngineR::gce_get_global_zone()
  )
  pushover("[HANDLER] STOP!", paste0("instance_id: ", instance_id))
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

shutdown_script <- function(instance_id, labels, gpu) {
  meta_name <- "shutdown-script"
  shutdown <- readr::read_file("shutdown.sh")
  glue_open <- "<"
  glue_close <- ">"

  out <- list()
  out[[meta_name]] <- glue::glue(
    shutdown,
    instance_id = instance_id,
    labels = sub(",", "%2C", labels),
    gpu = gpu,
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
    if (!gpu) {
      image_project <- "ubuntu-os-cloud"
      image_family <- "ubuntu-2204-lts"
    } else {
      image_project <- googleComputeEngineR::gce_get_global_project()
      image_family <- "gpu-docker"
    }
  }

  metadata <- list()
  metadata <- append(metadata, startup_script(
    org = "mlverse",
    labels = labels,
    gpu = gpu
  ))
  metadata <- append(metadata, shutdown_script(
    instance_id = instance_id,
    labels = labels,
    gpu = gpu
  ))

  out <- capture.output(
    x <- try(googleComputeEngineR::gce_vm(
      instance_id,
      image_project = image_project,
      image_family = image_family,
      predefined_type = "n1-standard-4",
      disk_size_gb = 120,
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

  if (any(grepl("ZONE_RESOURCE_POOL_EXHAUSTED_WITH_DETAILS", out))) {
    pushover(
      "[HANDLER] CREATE FAIL! No resources",
      paste0("No resources available. instance_id: ", instance_id, " gpu: ", gpu, " labels: ", labels)
    )
    stop("Could not start the VM. THe zone doesn't have the resouce. Try again in a few minutes.")
  }

  if (inherits(x, "try-error")) {
    pushover(
      "[HANDLER] CREATE FAIL! Unknown",
      paste0("Unknown error starting VM. instance_id: ", instance_id, " gpu: ", gpu, " labels: ", labels)
    )
    stop("Unknown error when starting the VM.")
  }

  pushover(
    "[HANDLER] CREATE Instance created!",
    paste0("Instance successfuly created. instance_id: ", instance_id, " gpu: ", gpu, " labels: ", labels)
  )
}
