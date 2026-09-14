#' Reshape raw TED returns into a tidy long table
#'
#' Pivots the wide per-candidate columns produced by [fetch_ted_returns()] into
#' one row per precinct-candidate, and parses the Texas Legislative Council
#' column encoding `"<Candidate><Party>_<YY><Type>_<Office>"`
#' (for example `"BidenD_20G_President"` -> candidate `"Biden"`, party `"D"`,
#' year `2020`, election type `"G"`, office `"President"`).
#'
#' The leading three characters of `CNTYVTD` are the Texas county FIPS-style
#' code; the remainder identifies the voting district (precinct) within the
#' county.
#'
#' @param raw Wide returns as returned by [fetch_ted_returns()].
#' @return A tibble with one row per precinct-candidate and columns `cntyvtd`,
#'   `county_fips`, `candidate`, `party`, `year`, `election_type`, `office`,
#'   and `votes`.
#' @seealso [fetch_ted_returns()], [build_tables()]
#' @export
#' @examples
#' raw <- tibble::tibble(
#'   CNTYVTD = c("0010001", "0010002"),
#'   VTDKEY = 1:2,
#'   BidenD_20G_President = c(357, 205),
#'   TrumpR_20G_President = c(791, 1548)
#' )
#' tidy_ted_returns(raw)
tidy_ted_returns <- function(raw) {
  id_cols <- intersect(c("CNTYVTD", "VTDKEY"), names(raw))
  if (!"CNTYVTD" %in% id_cols) {
    stop("`raw` must contain a `CNTYVTD` column.", call. = FALSE)
  }
  long <- tidyr::pivot_longer(
    raw,
    cols = -dplyr::all_of(id_cols),
    names_to = "col",
    values_to = "votes"
  )
  long <- tidyr::separate(
    long, "col",
    into = c("cand_party", "yeartype", "office"),
    sep = "_", extra = "merge", fill = "right"
  )
  dplyr::transmute(
    long,
    cntyvtd       = .data$CNTYVTD,
    county_fips   = stringr::str_sub(.data$CNTYVTD, 1, 3),
    candidate     = stringr::str_sub(.data$cand_party, 1, -2),
    party         = stringr::str_sub(.data$cand_party, -1),
    year          = 2000L + as.integer(stringr::str_sub(.data$yeartype, 1, 2)),
    election_type = stringr::str_sub(.data$yeartype, 3),
    office        = .data$office,
    votes         = as.integer(.data$votes)
  )
}
