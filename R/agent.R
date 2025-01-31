#' create_prompt
#'
#' Create a system prompt for the LLM agent.
#'
#' This uses an a system prompt aimed specifically at open models that
#' do not natively understand tool-calling or structured data replies.
#' @param additional_instructions length-1 character string containing
#' additional instructions to the agent.
#' @param tbl a remote table connection
#' @export
create_prompt <- function(tbl, additional_instructions = "") {
  table_name <- as.character(tbl$lazy_query$x)
  schema <- get_schema_md(tbl)
  head <- head(tbl) |>
    dplyr::collect() |>
    knitr::kable() |>
    paste(collapse = "\n")

  system.file("system-prompt.md",
              package = "duckdb.agent") |>
    readr::read_file() |>
    glue::glue(.open = "<", .close = ">")
}



get_schema_md <- function(tbl) {
  con <- tbl$src$con
  table_name <- as.character(tbl$lazy_query$x)

  schema <- DBI::dbGetQuery(con,
                            glue::glue("PRAGMA table_info({table_name})")
  ) |>
    knitr::kable() |>
    paste(collapse = "\n")
  schema
}

#' agent_query
#'
#' Takes the raw response text and returns a lazy tibble connection to the
#' table (view) containing the response.
#' @param con a DBI connection to the database.
#' @param resp the response from the chat agent.
#' This is assumed to follow the JSON structure set by the system prompt.
#' @export
agent_query <- function(resp, con = duckdbfs::cached_connection()) {
  x <- jsonlite::fromJSON(resp)
  stopifnot("query" %in% names(x))
  DBI::dbExecute(con, x$query)
  dplyr::tbl(con, x$table_name)
}


