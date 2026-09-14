#' CAGE `name_snyder` crosswalk for the 2020 Texas presidential candidates
#'
#' A small default crosswalk mapping the Capitol Data Portal candidate/party
#' labels to the standardized `name_snyder` used by the CAGE dataset
#' (`"[Last], [First] [Middle] ([Nick]), [Suffix]"`). This is a best-effort
#' starting point and should be reconciled against the archived CAGE file
#' (pullable with the \pkg{dataverse} package) before relying on it.
#'
#' @format A data frame with columns `candidate`, `party`, and `name_snyder`.
#' @keywords internal
tx_president_2020_cage <- data.frame(
  candidate   = c("Biden", "Trump", "Jorgensen", "Hawkins", "Write-In"),
  party       = c("D", "R", "L", "G", "W"),
  name_snyder = c("BIDEN, JOSEPH R., JR.", "TRUMP, DONALD J.",
                  "JORGENSEN, JO", "HAWKINS, HOWARD", NA_character_),
  stringsAsFactors = FALSE
)

#' Attach CAGE-style identifiers to tidy returns
#'
#' Adds the constituency-level identifiers used by CAGE, the "Candidates in
#' American General Elections" dataset (Cha, Kuriwaki, and Snyder,
#' <https://doi.org/10.7910/DVN/DGDRDT>): `state`, a CAGE office label
#' (`office_cage`), `dist`, `type`, and the standardized `name_snyder`.
#'
#' In CAGE, `dist` is the congressional-district number for the U.S. House, the
#' Senate class for the U.S. Senate, and blank for President and statewide
#' executives; it is left `NA` here for president. `name_snyder` values are
#' taken from `crosswalk`.
#'
#' @param returns Tidy returns from [tidy_ted_returns()].
#' @param state Two-letter state abbreviation. Defaults to `"TX"`.
#' @param crosswalk A candidate/party -> `name_snyder` lookup. Defaults to
#'   [tx_president_2020_cage].
#' @return `returns` with added `state`, `office_cage`, `dist`, `type`, and
#'   `name_snyder` columns.
#' @seealso [validate_totals()]
#' @export
#' @examples
#' returns <- tibble::tibble(
#'   cntyvtd = "0010001", county_fips = "001",
#'   candidate = "Biden", party = "D", year = 2020L,
#'   election_type = "G", office = "President", votes = 357L
#' )
#' add_cage_keys(returns)
add_cage_keys <- function(returns, state = "TX",
                          crosswalk = tx_president_2020_cage) {
  office_map <- c(President = "US President")
  type_map <- c(G = "gen", P = "primary", R = "runoff")

  out <- dplyr::left_join(returns, crosswalk, by = c("candidate", "party"))
  dplyr::mutate(
    out,
    state       = state,
    office_cage = dplyr::coalesce(unname(office_map[.data$office]), .data$office),
    dist        = NA_character_,
    type        = dplyr::coalesce(unname(type_map[.data$election_type]),
                                  .data$election_type)
  )
}
