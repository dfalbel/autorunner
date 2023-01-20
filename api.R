library(plumber)
library(googleComputeEngineR)
library(future)
plan(multisession)

#* @apiTitle Auto GH runner
#* @apiDescription Manages GH runners.

#* Healtcheck
#* @get /healthcheck
function() {
  "ok"
}

startup_script <- function(org, labels, gpu) {
  token <- gh::gh("POST /orgs/{org}/actions/runners/registration-token", org = org)
  glue::glue(
    readr::read_file("bootstrap.sh"),
    org = org,
    runner_token = token$token,
    labels = labels
  )
}


#* GitHub WebHook
#* @post /webhook
#* @parser json
function(req) {
  body <- jsonlite::fromJSON(req$postBody)

  if (!"self-hosted" %in% body$workflow_job$labels)
    return("ok")

  if (body$action == "queued") {

    if (!"gce" %in% body$workflow_job$labels)
      return("ok")

    instance_id <- paste0("ghgce-", body$workflow_job$id, "-",  body$workflow_job$run_id)
    gpu <- as.numeric("gpu" %in% body$workflow_job$labels)
    cat("creating instace with id: ", instance_id, "\n")
    labels <- paste(body$workflow_job$labels[-1], collapse = ",")
    res <- future::future({
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
    })
  }

  if (body$action == "completed") {
    instance_id <- as.character(body$workflow_job$runner_name)

    if (is.null(instance_id)) {
      return("nothing to delete")
    }

    if (!grepl("ghgce", instance_id)) {
      return("not gce allocated instance")
    }

    cat("deleting instance with id: ", instance_id, "\n")
    res <- future::future({
      googleComputeEngineR::gce_vm_delete(
        instances = instance_id,
        project = googleComputeEngineR::gce_get_global_project(),
        zone = googleComputeEngineR::gce_get_global_zone()
      )
    })
  }

  cat("returning!", "\n")
  return(body)
}

#* Install the GPU drivers
#*
#* @assets ./driver /driver
list()

#* Request a script to bootstrap installation of GH actions stuff
#*
#* @get macbootstrap
#* @serializer text
function(req, key, labels) {
  if (is.null(key) || key != Sys.getenv("GITHUB_PAT"))
    return("not authorized")

  token <- gh::gh("POST /orgs/{org}/actions/runners/registration-token", org = "mlverse")
  glue::glue(
    readr::read_file("bootstrap-macos.sh"),
    org = "mlverse",
    runner_token = token$token,
    labels = labels,
    name = paste(c("mac-", sample(letters, 10, replace=TRUE)), collapse="")
  )
}
