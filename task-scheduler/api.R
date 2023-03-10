library(plumber)
library(googleComputeEngineR)
library(future)
source("task.R", local = TRUE)
plan(multisession)

#* @apiTitle Auto GH runner
#* @apiDescription Manages GH runners.

#* Healtcheck
#* @get /healthcheck
function() {
  "ok"
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

    gpu <- as.numeric("gpu" %in% body$workflow_job$labels)
    labels <- paste(body$workflow_job$labels[-1], collapse = ",")

    if (grepl("windows", labels)) {
      # windows instance names won't keep more than 15 characters thus we
      # create just a random name with maximum 15 characters
      instance_id <- paste0("ghgce-", paste0(sample(letters, 9), collapse=""))
    } else {
      instance_id <- paste0("ghgce-", body$workflow_job$id, "-",  body$workflow_job$run_id)
      # add some more randomstuff to the instance name to avoid collisions.
      instance_id <- paste0(instance_id, "-", paste0(sample(letters, 10, replace=TRUE), collapse = ""))
    }

    cat("creating instace with id: ", instance_id, "\n")
    return(tasks_create_vm(instance_id, labels, gpu))
  }

  if (body$action == "completed") {
    instance_id <- tolower(as.character(body$workflow_job$runner_name))

    if (is.null(instance_id)) {
      return("nothing to delete")
    }

    if (!grepl("ghgce", instance_id)) {
      return("not gce allocated instance")
    }

    cat("deleting instance with id: ", instance_id, "\n")
    return(tasks_delete_vm(instance_id))
  }

  cat("returning!", "\n")
  return(body)
}

