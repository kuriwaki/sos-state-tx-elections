#' Add per-precinct vote share within each office
#'
#' @param returns Tidy returns from [tidy_ted_returns()].
#' @return `returns` with an added `share` column giving each candidate's share
#'   of the total votes cast in that precinct-office.
#' @export
#' @examples
#' returns <- tibble::tibble(
#'   cntyvtd = c("0010001", "0010001"),
#'   office = "President", candidate = c("Biden", "Trump"),
#'   votes = c(357L, 791L)
#' )
#' vote_share(returns)
vote_share <- function(returns) {
  out <- dplyr::group_by(returns, .data$cntyvtd, .data$office)
  out <- dplyr::mutate(out, share = .data$votes / sum(.data$votes))
  dplyr::ungroup(out)
}

#' Aggregate candidate totals from the normalized tables
#'
#' Joins the `votes` and `candidate` tables and sums votes per candidate. Works
#' on both in-memory tibbles and lazy Arrow datasets (from
#' [open_returns_parquet()]); the query runs through the \pkg{dplyr} backend and
#' is materialized with [dplyr::collect()] — no SQL engine is involved.
#'
#' @param tables A named list with `votes` and `candidate`, e.g. from
#'   [build_tables()] or [open_returns_parquet()].
#' @return A tibble of `candidate`, `party`, `office`, and `total_votes`,
#'   ordered by descending `total_votes`.
#' @export
candidate_totals <- function(tables) {
  group_cols <- intersect(c("candidate", "party", "office"),
                          names(tables$candidate))
  out <- dplyr::left_join(tables$votes, tables$candidate, by = "candidate_id")
  out <- dplyr::group_by(out, dplyr::across(dplyr::all_of(group_cols)))
  out <- dplyr::summarise(out, total_votes = sum(.data$votes, na.rm = TRUE),
                          .groups = "drop")
  out <- dplyr::collect(out)
  dplyr::arrange(out, dplyr::desc(.data$total_votes))
}

#' Validate aggregated totals against a reference (e.g. CAGE)
#'
#' Compares candidate totals (from [candidate_totals()]) against a reference
#' table of certified totals, such as figures derived from the CAGE dataset,
#' and flags rows whose relative difference exceeds `tol`. Precinct/VTD sums can
#' differ slightly from certified statewide totals because some ballots are not
#' assignable to a voting district, so a small tolerance is expected.
#'
#' @param totals Candidate totals with a `total_votes` column.
#' @param reference Reference totals joined on `by`, also with a `total_votes`
#'   column.
#' @param by Join keys. Defaults to `c("candidate", "party")`.
#' @param tol Maximum acceptable absolute relative difference. Defaults to
#'   `0.005` (0.5%).
#' @return `totals` joined to the reference with added `total_votes_ref`,
#'   `diff`, `pct_diff`, and `within_tol` columns.
#' @export
#' @examples
#' totals <- tibble::tibble(candidate = "Trump", party = "R",
#'                          total_votes = 5889022)
#' reference <- tibble::tibble(candidate = "Trump", party = "R",
#'                             total_votes = 5890347)
#' validate_totals(totals, reference)
validate_totals <- function(totals, reference, by = c("candidate", "party"),
                            tol = 0.005) {
  cmp <- dplyr::inner_join(totals, reference, by = by,
                           suffix = c("", "_ref"))
  dplyr::mutate(
    cmp,
    diff       = .data$total_votes - .data$total_votes_ref,
    pct_diff   = .data$diff / .data$total_votes_ref,
    within_tol = abs(.data$pct_diff) <= tol
  )
}
