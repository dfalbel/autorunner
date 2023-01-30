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
  glue::glue(
    readr::read_file("bootstrap.sh"),
    org = org,
    runner_token = token$token,
    labels = labels
  )
}

start_gce_vm <- function(instance_id, labels, gpu) {
  googleComputeEngineR::gce_vm(
    instance_id,
    image_project = "ubuntu-os-cloud",
    image_family = "ubuntu-2204-lts",
    predefined_type = "n1-standard-4",
    disk_size_gb = 90,
    project = googleComputeEngineR::gce_get_global_project(),
    zone = googleComputeEngineR::gce_get_global_zone(),
    metadata = list(
      "startup-script" = startup_script(
        org = "mlverse",
        labels = labels,
        gpu = gpu
      )
    ),
    acceleratorCount = if (gpu) 1 else NULL,
    acceleratorType = if (gpu) "nvidia-tesla-t4" else "",
    scheduling = list(
      'preemptible' = TRUE
    )
  )
}
