make_returns <- function() {
  tibble::tibble(
    cntyvtd = c("0010001", "0010001", "0010002", "0010002"),
    county_fips = c("001", "001", "001", "001"),
    candidate = c("Biden", "Trump", "Biden", "Trump"),
    party = c("D", "R", "D", "R"),
    year = 2020L,
    election_type = "G",
    office = "President",
    votes = c(357L, 791L, 205L, 1548L)
  )
}

test_that("build_tables produces a normalized precinct/candidate/votes schema", {
  tabs <- build_tables(make_returns())

  expect_named(tabs, c("precinct", "candidate", "votes"))
  expect_equal(nrow(tabs$precinct), 2L)   # two distinct precincts
  expect_equal(nrow(tabs$candidate), 2L)  # two distinct candidates
  expect_equal(nrow(tabs$votes), 4L)      # 2 precincts x 2 candidates

  expect_true(all(c("precinct_id", "cntyvtd", "county_fips") %in%
                    names(tabs$precinct)))
  expect_true(all(c("candidate_id", "candidate", "party", "office") %in%
                    names(tabs$candidate)))
  expect_setequal(names(tabs$votes), c("precinct_id", "candidate_id", "votes"))

  # foreign keys resolve and no votes are dropped
  expect_true(all(tabs$votes$precinct_id %in% tabs$precinct$precinct_id))
  expect_true(all(tabs$votes$candidate_id %in% tabs$candidate$candidate_id))
  expect_equal(sum(tabs$votes$votes), sum(make_returns()$votes))
})

test_that("parquet round-trip preserves the tables", {
  tabs <- build_tables(make_returns())
  dir <- file.path(tempdir(), paste0("txsos-", as.integer(runif(1, 1, 1e6))))
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  paths <- write_returns_parquet(tabs, dir)

  expect_true(all(file.exists(paths)))

  ds <- open_returns_parquet(dir)
  votes_back <- dplyr::collect(ds$votes)
  expect_equal(sum(votes_back$votes), sum(tabs$votes$votes))
})
