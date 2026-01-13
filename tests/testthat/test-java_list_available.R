test_that("java_list_available handles 'all' platform and arch", {
  skip_on_cran()

  # Mock config and helpers
  local_mocked_bindings(
    java_config = function(...) {
      list(
        platforms = list(supported = c("linux", "macos")),
        sdkman = list(
          platform_map = list(linux = "linux", macos = "darwin"),
          arch_map = list(x64 = "x64", aarch64 = "arm64"),
          vendor_map = list(Temurin = "tem")
        )
      )
    },
    memoised_list_temurin = function(p, a) {
      data.frame(
        backend = "native",
        vendor = "Temurin",
        major = 21L,
        version = paste0("21-", p, "-", a),
        platform = p,
        arch = a,
        identifier = "id",
        checksum_available = TRUE,
        stringsAsFactors = FALSE
      )
    },
    memoised_list_corretto = function(...) data.frame(),
    memoised_list_zulu = function(...) data.frame(),
    memoised_list_sdkman = function(...) data.frame()
  )

  # Use 'all/all' and check for warning
  expect_warning(
    res <- java_list_available(platform = "all", arch = "all", quiet = TRUE),
    "advanced users"
  )

  expect_s3_class(res, "data.frame")
  # 2 platforms * 2 arches = 4 rows
  expect_equal(nrow(res), 4)
  expect_setequal(res$platform, c("linux", "macos"))
  expect_setequal(res$arch, c("x64", "aarch64"))
})

test_that("java_list_available memoization and force parameter work", {
  skip_on_cran()

  call_count <- 0
  impl_func <- function(p, a) {
    call_count <<- call_count + 1
    data.frame(
      backend = "native",
      vendor = "Temurin",
      major = 21L,
      version = "21",
      platform = p,
      arch = a,
      identifier = "id",
      checksum_available = TRUE,
      stringsAsFactors = FALSE
    )
  }

  # We need to mock the memoised function because java_list_available calls it
  # To test memoization, we'll create a local memoised function
  local_memoised_temurin <- memoise::memoise(impl_func)

  local_mocked_bindings(
    java_config = function(...) list(platforms = list(supported = "linux")),
    memoised_list_temurin = local_memoised_temurin,
    memoised_list_corretto = function(...) data.frame(),
    memoised_list_zulu = function(...) data.frame(),
    memoised_list_sdkman = function(...) data.frame()
  )

  # Reset call count
  call_count <- 0

  # First call
  java_list_available(
    platform = "linux",
    arch = "x64",
    backend = "native",
    quiet = TRUE
  )
  expect_equal(call_count, 1)

  # Second call (should be memoised)
  java_list_available(
    platform = "linux",
    arch = "x64",
    backend = "native",
    quiet = TRUE
  )
  expect_equal(call_count, 1)

  # Third call with force = TRUE
  # Note: java_list_available calls forget() on the memoised function it sees in its environment
  java_list_available(
    platform = "linux",
    arch = "x64",
    backend = "native",
    force = TRUE,
    quiet = TRUE
  )
  expect_equal(call_count, 2)
})
