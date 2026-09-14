test_that("vote_share sums to 1 within each precinct-office", {
  returns <- tibble::tibble(
    cntyvtd = c("0010001", "0010001", "0010002", "0010002"),
    office = "President",
    candidate = c("Biden", "Trump", "Biden", "Trump"),
    votes = c(357L, 791L, 205L, 1548L)
  )
  out <- vote_share(returns)
  expect_true("share" %in% names(out))

  sums <- dplyr::summarise(dplyr::group_by(out, cntyvtd),
                           s = sum(share), .groups = "drop")
  expect_equal(sums$s, rep(1, nrow(sums)))
})

test_that("candidate_totals aggregates across precincts", {
  returns <- tibble::tibble(
    cntyvtd = c("0010001", "0010001", "0010002", "0010002"),
    county_fips = "001",
    candidate = c("Biden", "Trump", "Biden", "Trump"),
    party = c("D", "R", "D", "R"),
    year = 2020L, election_type = "G", office = "President",
    votes = c(357L, 791L, 205L, 1548L)
  )
  tabs <- build_tables(returns)
  totals <- candidate_totals(tabs)

  expect_setequal(names(totals),
                  c("candidate", "party", "office", "total_votes"))
  trump <- totals$total_votes[totals$candidate == "Trump"]
  biden <- totals$total_votes[totals$candidate == "Biden"]
  expect_equal(trump, 791L + 1548L)
  expect_equal(biden, 357L + 205L)
  # ordered by descending total_votes
  expect_equal(totals$candidate[1], "Trump")
})

test_that("validate_totals flags rows outside tolerance", {
  totals <- tibble::tibble(
    candidate = c("Trump", "Biden"), party = c("R", "D"),
    total_votes = c(5889022, 5257513)
  )
  reference <- tibble::tibble(
    candidate = c("Trump", "Biden"), party = c("R", "D"),
    total_votes = c(5890347, 4000000)   # Biden ref deliberately off
  )
  cmp <- validate_totals(totals, reference, tol = 0.005)

  expect_true(all(c("total_votes_ref", "diff", "pct_diff", "within_tol") %in%
                    names(cmp)))
  expect_true(cmp$within_tol[cmp$candidate == "Trump"])   # within 0.5%
  expect_false(cmp$within_tol[cmp$candidate == "Biden"])  # far off
})
