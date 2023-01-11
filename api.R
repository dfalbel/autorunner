library(plumber)

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

  if (!"self-hosted" %in% workflow_job$labels)
    return("ok")

  return(body)
}
