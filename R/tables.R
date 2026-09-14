#' Build a normalized precinct / candidate / votes schema
#'
#' Splits tidy returns into a small relational "database": a `precinct` table
#' (one row per `cntyvtd`), a `candidate` metadata table (one row per
#' candidate, carrying any CAGE keys added by [add_cage_keys()]), and a `votes`
#' table keyed by `precinct_id` and `candidate_id`.
#'
#' @param returns Tidy returns from [tidy_ted_returns()], optionally passed
#'   through [add_cage_keys()].
#' @return A named list of three tibbles: `precinct`, `candidate`, and `votes`.
#' @seealso [write_returns_parquet()], [open_returns_parquet()]
#' @export
#' @examples
#' returns <- tibble::tibble(
#'   cntyvtd = c("0010001", "0010001"), county_fips = c("001", "001"),
#'   candidate = c("Biden", "Trump"), party = c("D", "R"),
#'   year = 2020L, election_type = "G", office = "President",
#'   votes = c(357L, 791L)
#' )
#' build_tables(returns)
build_tables <- function(returns) {
  precinct <- dplyr::distinct(returns, .data$cntyvtd, .data$county_fips)
  precinct <- dplyr::arrange(precinct, .data$cntyvtd)
  precinct <- dplyr::mutate(precinct, precinct_id = dplyr::row_number(),
                            .before = 1)

  cand_cols <- intersect(
    c("candidate", "party", "office", "office_cage", "dist", "type",
      "state", "name_snyder", "year", "election_type"),
    names(returns)
  )
  candidate <- dplyr::distinct(returns, dplyr::across(dplyr::all_of(cand_cols)))
  candidate <- dplyr::arrange(candidate, .data$office, .data$party,
                              .data$candidate)
  candidate <- dplyr::mutate(candidate, candidate_id = dplyr::row_number(),
                             .before = 1)

  key <- intersect(c("candidate", "party", "office"), names(returns))
  votes <- dplyr::left_join(
    returns,
    dplyr::select(precinct, "precinct_id", "cntyvtd"),
    by = "cntyvtd"
  )
  votes <- dplyr::left_join(
    votes,
    dplyr::select(candidate, "candidate_id", dplyr::all_of(key)),
    by = key
  )
  votes <- dplyr::transmute(votes, .data$precinct_id, .data$candidate_id,
                            .data$votes)

  list(precinct = precinct, candidate = candidate, votes = votes)
}

#' Write the normalized tables to a directory of Parquet files
#'
#' @param tables A named list of tables, e.g. from [build_tables()].
#' @param dir Output directory. Created if it does not exist.
#' @return (Invisibly) a named character vector of the written file paths.
#' @seealso [open_returns_parquet()]
#' @export
write_returns_parquet <- function(tables, dir) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  paths <- vapply(names(tables), function(nm) {
    p <- file.path(dir, paste0(nm, ".parquet"))
    arrow::write_parquet(tables[[nm]], p)
    p
  }, character(1))
  invisible(paths)
}

#' Open a directory of Parquet tables as Arrow datasets
#'
#' Opens the `precinct`, `candidate`, and `votes` Parquet files as lazy Arrow
#' datasets that can be queried with the \pkg{dplyr} backend (no SQL engine
#' required) and materialized with [dplyr::collect()].
#'
#' @param dir Directory containing `precinct.parquet`, `candidate.parquet`, and
#'   `votes.parquet`.
#' @return A named list of three [arrow::Dataset] objects.
#' @seealso [write_returns_parquet()], [candidate_totals()]
#' @export
open_returns_parquet <- function(dir) {
  nms <- c("precinct", "candidate", "votes")
  stats::setNames(
    lapply(nms, function(n) arrow::open_dataset(file.path(dir, paste0(n, ".parquet")))),
    nms
  )
}
