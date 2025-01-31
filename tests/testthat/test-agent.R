test_that("create system prompt", {
  library(duckdbfs)
  con = duckdbfs::cached_connection()
  tbl <- as_dataset(mtcars, con)
  prompt <- create_prompt(tbl)

  expect_type(prompt, "character")
})

test_that("create system prompt", {
  library(duckdbfs)
  tbl <- as_dataset(mtcars)
  input_table <- as.character(tbl$lazy_query$x)
  response_table <- "answer"
  # manually mock up a response

  query = glue::glue("CREATE OR REPLACE VIEW <response_table> ",
                     "AS SELECT DISTINCT cyl FROM <input_table>",
                     .open = "<", .close = ">")
  resp <- glue::glue(
                  '{
                    "query": "<query>",
                    "table_name": "<response_table>"
                  }',
                  .open = "<",
                  .close = ">")

  out <- agent_query(resp)
  expect_s3_class(out, "tbl_lazy")

})
