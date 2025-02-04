
<!-- README.md is generated from README.Rmd. Please edit that file -->

# duckdb.agent

<!-- badges: start -->

[![R-CMD-check](https://github.com/boettiger-lab/duckdb.agent/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/boettiger-lab/duckdb.agent/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of duckdb.agent is to provide convenient utilities for working
with chat-generated SQL.

## Installation

You can install the development version of duckdb.agent from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("boettiger-lab/duckdb.agent")
```

## Example

``` r
library(duckdb.agent)
library(duckdbfs)
library(ellmer)

tracts_url <- "https://minio.carlboettiger.info/public-social-vulnerability/2022-tracts-h3-z6.parquet"
tracts_h3 <- open_dataset(tracts_url, tblname = "censustracts")
system_prompt = create_prompt()
```

``` r
agent <- ellmer::chat_vllm(
    base_url = "https://llm.cirrus.carlboettiger.info/v1/",
    model = "kosbu/Llama-3.3-70B-Instruct-AWQ",
    api_key = Sys.getenv("CIRRUS_LLM_KEY"),
    system_prompt = system_prompt,
    api_args = list(temperature = 0)
)

resp <- agent$chat("Yolo County")
#> {
#> "query": "CREATE OR REPLACE VIEW yolo_county AS SELECT * FROM censustracts 
#> WHERE COUNTY = 'Yolo County'",
#> "table_name": "yolo_county",
#> "explanation": "This query creates a view named 'yolo_county' that selects all 
#> rows from the 'censustracts' table where the 'COUNTY' column is 'Yolo County'."
#> }
agent_query(resp)
#> [90m# Source:   table<yolo_county> [?? x 4][39m
#> [90m# Database: DuckDB v1.1.3 [unknown@Linux 6.9.3-76060903-generic:R 4.4.2/:memory:][39m
#>    STATE      COUNTY      FIPS        h6             
#>    [3m[90m<chr>[39m[23m      [3m[90m<chr>[39m[23m       [3m[90m<chr>[39m[23m       [3m[90m<chr>[39m[23m          
#> [90m 1[39m California Yolo County 06113010102 862832B0FFFFFFF
#> [90m 2[39m California Yolo County 06113010313 862832B07FFFFFF
#> [90m 3[39m California Yolo County 06113010401 8628304AFFFFFFF
#> [90m 4[39m California Yolo County 06113010401 8628304C7FFFFFF
#> [90m 5[39m California Yolo County 06113010401 8628304D7FFFFFF
#> [90m 6[39m California Yolo County 06113010401 8628304DFFFFFFF
#> [90m 7[39m California Yolo County 06113010401 8628304F7FFFFFF
#> [90m 8[39m California Yolo County 06113010401 862830417FFFFFF
#> [90m 9[39m California Yolo County 06113010401 86283041FFFFFFF
#> [90m10[39m California Yolo County 06113010401 862832B2FFFFFFF
#> [90m# ℹ more rows[39m
```
