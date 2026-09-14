#' Fetch precinct (VTD) election returns from the Texas Capitol Data Portal
#'
#' Downloads precinct-level ("VTD") returns for a single office in a single
#' election from the Texas Legislative Council TED API, the machine-readable
#' source behind the Secretary of State returns
#' (<https://data.capitol.texas.gov>). The returned frame is *wide*: one integer
#' column per candidate. Use [tidy_ted_returns()] to reshape it.
#'
#' Election and office identifiers come from the Capitol Data Portal CKAN
#' catalogue. For example, election `377` is the 2020 General election and
#' office `1` is President/Vice-President.
#'
#' @param election Integer election id used by the TED API.
#' @param office Integer office id within that election.
#' @param base_url API base URL. Defaults to the public TED endpoint.
#' @param max_tries Number of times to retry a failed request.
#' @return A [tibble][tibble::tibble] of wide returns with `CNTYVTD`, `VTDKEY`,
#'   and one column per candidate named
#'   `"<Candidate><Party>_<YY><Type>_<Office>"` (e.g. `"BidenD_20G_President"`).
#' @seealso [tidy_ted_returns()]
#' @export
#' @examplesIf interactive()
#' # 2020 General (377), President (1)
#' raw <- fetch_ted_returns(election = 377, office = 1)
fetch_ted_returns <- function(election, office,
                              base_url = "https://ted.capitol.texas.gov/api/Offices",
                              max_tries = 3) {
  url <- sprintf("%s/%d/%d/vtd", sub("/$", "", base_url),
                 as.integer(election), as.integer(office))
  resp <- httr2::request(url)
  resp <- httr2::req_user_agent(
    resp, "txsos (https://github.com/kuriwaki/sos-state-tx-elections)")
  resp <- httr2::req_retry(resp, max_tries = max_tries)
  resp <- httr2::req_perform(resp)
  body <- httr2::resp_body_string(resp)
  readr::read_csv(body, show_col_types = FALSE,
                  col_types = readr::cols(CNTYVTD = readr::col_character()))
}
