library(plumber)
library(googleComputeEngineR)
library(future)
source("pushover.R")
source("gce.R")

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
  out <- vm_delete(instance_id)

  if (is.null(out$error)) {
    msg <- list(severity = "NOTICE", message = "Successfully created VM", component = out)
    cat(jsonlite::toJSON(msg, auto_unbox = TRUE), "\n")
    return(out)
  }

  err <- list(severity = "ERROR", message = "Error deleting VM", component = out$error)
  cat(jsonlite::toJSON(err, auto_unbox = TRUE), "\n")
  stop("Error deleting VM")
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

start_gce_vm <- function(instance_id, labels, gpu) {

  source_image <- source_image_from_config(instance_id, labels, gpu)
  metadata <- metadata_from_config(instance_id, labels, gpu)

  args <- list()
  args$scheduling <- list(preemptible = TRUE)
  args$metadata <- metadata
  if (gpu) {
    args$guestAccelerators <- list(list(
     acceleratorType = accelerator_type_from_config("nvidia-tesla-t4"),
     acceleratorCount = "1"
    ))
  }

  out <- vm_insert(
    name = instance_id,
    .sourceImage = source_image,
    !!!args
  )

  if (is.null(out$error)) {
    msg <- list(severity = "NOTICE", message = "Successfully created VM", component = out)
    cat(jsonlite::toJSON(msg, auto_unbox = TRUE), "\n")
    return(out)
  }

  err <- list(severity = "ERROR", message = "Error creating VM", component = out$error)
  cat(jsonlite::toJSON(err, auto_unbox = TRUE), "\n")

  stop("Error creating VM")
}

source_image_from_config <- function(instance_id, labels, gpu) {
  if (gpu) {
    "projects/rstudio-cloudml/global/images/gpu-docker"
  } else {
    "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20230425"
  }
}

metadata_from_config <- function(instance_id, labels, gpu) {
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
}

accelerator_type_from_config <- function(accelerator) {
  glue::glue("projects/rstudio-cloudml/zones/{ZONE_ID}/acceleratorTypes/{accelerator}")
}

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
