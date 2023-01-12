library(plumber)
library(googleComputeEngineR)

#* @apiTitle Auto GH runner
#* @apiDescription Manages GH runners.

#* Healtcheck
#* @get /healthcheck
function() {
  "ok"
}

startup_script <- function(org, labels) {
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

  if (body$repository$name != "gh-actions-test")
    return("ok")

  if (body$action == "queued") {
    instance_id <- paste0("gh-", body$workflow_job$id, "-",  body$workflow_job$run_id)
    gce_vm(
      instance_id,
      image_project = "ubuntu-os-cloud",
      image_family = "ubuntu-2204-lts",
      predefined_type = "n2-standard-2",
      project = gce_get_global_project(),
      zone = gce_get_global_zone(),
      metadata = list(
        "startup-script" = startup_script(org = "mlverse", labels = "gpug")
      )
    )
  }

  if (body$action == "completed") {
    gce_vm_delete(body$workflow_job$runner_name)
  }

  return(body)
}
