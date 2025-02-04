




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


#' create_prompt
#'
#' Create a system prompt for the LLM agent.
#'
#' This uses an a system prompt aimed specifically at open models that
#' do not natively understand tool-calling or structured data replies.
#' @param additional_instructions length-1 character string containing
#' additional instructions to the agent.
#' @param con a database connection
#' @export
create_prompt <- function(con = duckdbfs::cached_connection(),
                            additional_instructions = "") {


  tables <- DBI::dbListTables(con)
  table_info <-
    lapply(tables,
           function(x) {
                        schema <- tbl_schema_md(x, con)
                        head <- tbl_head_md(x, con)
                        table_info <- glue::glue(
"
Pay attention to the schema of the table <x>:
<schema>

Also pay close attention to how data is represented in each column,
as seen by the HEAD (ommitting large list-type columns, if any) of table <x>:
<head>
", .open = "<", .close = ">")

           }) |>
    paste(collapse = "\n\n")

  prompt <- system.file("system-prompt.md",
                        package = "duckdb.agent") |>
    readr::read_file() |>
    glue::glue(.open = "<", .close = ">")

  prompt
}


# render table info as markdown tables:
tbl_head_md <- function(table_name, con) {
    x <- dplyr::tbl(con, table_name)

    # drop non-list types.
    # backend doesn't support tidyselect predicates
    types <- dplyr::collect(utils::head(x,1)) |>
      purrr::map_lgl(function(x) class(x)[[1]] != "list")
    keep <- names(types)[types]

    x |>
      dplyr::select(dplyr::all_of(keep)) |>
      utils::head() |>
      dplyr::collect() |>
      knitr::kable() |>
      paste(collapse = "\n")
}

tbl_schema_md <- function(table_name, con) {
  DBI::dbGetQuery(con,
                  glue::glue("PRAGMA table_info({table_name})")
  ) |>
    knitr::kable() |>
    paste(collapse = "\n")
}
