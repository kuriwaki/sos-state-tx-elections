# Reproducible pipeline: 2020 Texas General — President/Vice-President
# ---------------------------------------------------------------------------
# Fetches precinct-level (VTD) returns from the Texas Capitol Data Portal,
# reshapes them into the normalized precinct/candidate/votes schema, attaches
# CAGE identifiers, writes Parquet tables, and validates the statewide totals
# against the certified Secretary of State figures.
#
# Outputs are written under data/ (git-ignored) — only this script is tracked,
# so the dataset is reproducible without committing large files.
#
# Run from the repo root:  Rscript data-raw/01_president_2020_general.R
# ---------------------------------------------------------------------------

library(txsos)
library(dplyr)

# Capitol Data Portal identifiers (from the CKAN catalogue):
#   election 377 = 2020 General, office 1 = President/Vice-President.
ELECTION <- 377L
OFFICE   <- 1L
OUT_DIR  <- file.path("data", "president_2020_general")

message("1/5 Fetching precinct (VTD) returns from the Capitol Data Portal ...")
raw <- fetch_ted_returns(election = ELECTION, office = OFFICE)
message(sprintf("    fetched %d precincts x %d candidate columns",
                nrow(raw), ncol(raw) - 2L))

message("2/5 Tidying + attaching CAGE identifiers ...")
returns <- raw |>
  tidy_ted_returns() |>
  add_cage_keys(state = "TX")

message("3/5 Building normalized precinct/candidate/votes tables ...")
tables <- build_tables(returns)
message(sprintf("    precinct: %d rows | candidate: %d rows | votes: %d rows",
                nrow(tables$precinct), nrow(tables$candidate),
                nrow(tables$votes)))

message("4/5 Writing Parquet tables to ", OUT_DIR, " ...")
paths <- write_returns_parquet(tables, OUT_DIR)
print(paths)

message("5/5 Validating statewide totals against certified SoS figures ...")
# Certified statewide totals, Texas 2020 General, President
# (Texas Secretary of State official canvass).
certified <- tibble::tibble(
  candidate   = c("Trump", "Biden", "Jorgensen", "Hawkins"),
  party       = c("R", "D", "L", "G"),
  total_votes = c(5890347, 5259126, 126243, 33396)
)

totals <- candidate_totals(open_returns_parquet(OUT_DIR))
check  <- validate_totals(totals, certified,
                          by = c("candidate", "party"), tol = 0.005)

cat("\nStatewide candidate totals (from precinct Parquet) vs certified:\n")
check |>
  transmute(candidate, party,
            precinct_sum = total_votes,
            certified    = total_votes_ref,
            pct_diff     = sprintf("%+.3f%%", 100 * pct_diff),
            within_0.5pct = within_tol) |>
  as.data.frame() |>
  print(row.names = FALSE)

if (!all(check$within_tol)) {
  stop("Some totals fall outside the 0.5% tolerance vs certified figures.")
}
message("\nDone: Parquet database written and validated within 0.5% of certified totals.")
