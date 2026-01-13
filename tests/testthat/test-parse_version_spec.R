test_that("is_sdkman_identifier detects known vendor identifiers", {
  # Known vendors
  expect_true(is_sdkman_identifier("25.0.1-amzn"))
  expect_true(is_sdkman_identifier("24.0.2-open"))
  expect_true(is_sdkman_identifier("26.ea.13-graal"))
  expect_true(is_sdkman_identifier("23.1.9.r21-nik"))
  expect_true(is_sdkman_identifier("22.1.0.1.r17-gln"))
  expect_true(is_sdkman_identifier("25.0.1.fx-zulu"))
  expect_true(is_sdkman_identifier("21.0.9-tem"))
  expect_true(is_sdkman_identifier("17.0.17-librca"))
  expect_true(is_sdkman_identifier("11.0.29-ms"))
  expect_true(is_sdkman_identifier("8.0.472-kona"))
})

test_that("is_sdkman_identifier rejects non-identifiers", {
  # Major versions
  expect_false(is_sdkman_identifier("21"))
  expect_false(is_sdkman_identifier("17"))
  expect_false(is_sdkman_identifier("11"))

  # Specific versions without suffix
  expect_false(is_sdkman_identifier("21.0.9"))
  expect_false(is_sdkman_identifier("17.0.12"))
  expect_false(is_sdkman_identifier("11.0.29"))

  # Native backend version formats (uppercase suffix)
  expect_false(is_sdkman_identifier("21.0.9+10-LTS"))
  expect_false(is_sdkman_identifier("25.0.1+8.0.LTS"))
  expect_false(is_sdkman_identifier("17.0.9+9-LTS"))

  # No hyphen
  expect_false(is_sdkman_identifier("21.0.9.8.1"))
})

test_that("is_sdkman_identifier handles fallback regex for unknown vendors", {
  # Should match pattern even if vendor unknown
  expect_true(is_sdkman_identifier("25.0.1-newvendor"))
  expect_true(is_sdkman_identifier("21.0.9-xyz"))

  # Should reject malformed patterns
  expect_false(is_sdkman_identifier("not-a-version"))
  expect_false(is_sdkman_identifier("ABC-vendor"))
})

test_that("sdkman_vendor_code extracts vendor suffix", {
  expect_equal(sdkman_vendor_code("25.0.1-amzn"), "amzn")
  expect_equal(sdkman_vendor_code("24.0.2-open"), "open")
  expect_equal(sdkman_vendor_code("26.ea.13-graal"), "graal")
  expect_equal(sdkman_vendor_code("23.1.9.r21-nik"), "nik")
})

test_that("sdkman_vendor_to_distribution maps known vendors", {
  expect_equal(sdkman_vendor_to_distribution("amzn"), "Corretto")
  expect_equal(sdkman_vendor_to_distribution("tem"), "Temurin")
  expect_equal(sdkman_vendor_to_distribution("zulu"), "Zulu")
  expect_equal(sdkman_vendor_to_distribution("open"), "OpenJDK")
  expect_equal(sdkman_vendor_to_distribution("graal"), "GraalVM")
  expect_equal(sdkman_vendor_to_distribution("librca"), "Liberica")
  expect_equal(sdkman_vendor_to_distribution("nik"), "Liberica NIK")
  expect_equal(sdkman_vendor_to_distribution("oracle"), "Oracle")
  expect_equal(sdkman_vendor_to_distribution("ms"), "Microsoft")
  expect_equal(sdkman_vendor_to_distribution("sapmchn"), "SAP Machine")
  expect_equal(sdkman_vendor_to_distribution("sem"), "Semeru")
  expect_equal(sdkman_vendor_to_distribution("jbr"), "JetBrains")
  expect_equal(sdkman_vendor_to_distribution("kona"), "Tencent Kona")
  expect_equal(sdkman_vendor_to_distribution("gln"), "Gluon")
  expect_equal(sdkman_vendor_to_distribution("mandrel"), "Mandrel")
  expect_equal(sdkman_vendor_to_distribution("albba"), "Alibaba Dragonwell")
  expect_equal(sdkman_vendor_to_distribution("bisheng"), "Huawei Bisheng")
  expect_equal(sdkman_vendor_to_distribution("trava"), "Trava")
  expect_equal(sdkman_vendor_to_distribution("graalce"), "GraalVM CE")
})

test_that("sdkman_vendor_to_distribution warns for unknown vendors", {
  expect_warning(
    result <- sdkman_vendor_to_distribution("unknownvendor"),
    "Unknown SDKMAN vendor"
  )
  expect_equal(result, "unknownvendor")

  expect_warning(
    result <- sdkman_vendor_to_distribution("xyz"),
    "Unknown SDKMAN vendor"
  )
  expect_equal(result, "xyz")
})

test_that("known_sdkman_vendors returns complete list", {
  vendors <- known_sdkman_vendors()
  expect_type(vendors, "character")
  expect_true(length(vendors) >= 19) # At least 19 from our CSV
  expect_true("amzn" %in% vendors)
  expect_true("tem" %in% vendors)
  expect_true("zulu" %in% vendors)
  expect_true("open" %in% vendors)
  expect_true("graal" %in% vendors)
})
