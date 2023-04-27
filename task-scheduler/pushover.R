
pushover <- function(title, msg) {
  invisible(httr::POST(
    "https://api.pushover.net/1/messages.json",
    body = jsonlite::toJSON(list(
      token = Sys.getenv("PUSHOVER_TOKEN"),
      user = Sys.getenv("PUSHOVER_USER"),
      title = title,
      message = msg
    )),
    httr::content_type_json(),
    encode = "raw"
  ))
}
