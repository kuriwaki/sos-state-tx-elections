test_that("tidy_ted_returns reshapes and parses the TLC column encoding", {
  raw <- tibble::tibble(
    CNTYVTD = c("0010001", "0030002"),
    VTDKEY = 1:2,
    BidenD_20G_President = c(357L, 207L),
    TrumpR_20G_President = c(791L, 1499L),
    `Write-InW_20G_President` = c(2L, 0L)
  )

  out <- tidy_ted_returns(raw)

  expect_setequal(
    names(out),
    c("cntyvtd", "county_fips", "candidate", "party", "year",
      "election_type", "office", "votes")
  )
  # 2 precincts x 3 candidates
  expect_equal(nrow(out), 6L)
  expect_equal(sort(unique(out$candidate)), c("Biden", "Trump", "Write-In"))
  expect_equal(sort(unique(out$party)), c("D", "R", "W"))
  expect_equal(unique(out$year), 2020L)
  expect_equal(unique(out$election_type), "G")
  expect_equal(unique(out$office), "President")
  expect_equal(unique(out$county_fips), c("001", "003"))

  biden_001 <- out$votes[out$cntyvtd == "0010001" & out$candidate == "Biden"]
  expect_equal(biden_001, 357L)
})

test_that("tidy_ted_returns errors without CNTYVTD", {
  expect_error(tidy_ted_returns(tibble::tibble(x = 1)), "CNTYVTD")
})
