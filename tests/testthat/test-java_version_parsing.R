# Extract internal function for testing
._java_parse_version_output <- getFromNamespace(
  "._java_parse_version_output",
  "rJavaEnv"
)

test_that("._java_parse_version_output handles single-line standard output", {
  output <- c('openjdk version "21" 2023-09-19')
  expect_equal(._java_parse_version_output(output), "21")

  output <- c('java version "1.8.0_381"')
  expect_equal(._java_parse_version_output(output), "8")
})

test_that("._java_parse_version_output handles multi-line standard output", {
  output <- c(
    'openjdk version "21.0.1" 2023-10-17 LTS',
    'OpenJDK Runtime Environment Corretto-21.0.1.12.1 (build 21.0.1+12-LTS)',
    'OpenJDK 64-Bit Server VM Corretto-21.0.1.12.1 (build 21.0.1+12-LTS, mixed mode, sharing)'
  )
  expect_equal(._java_parse_version_output(output), "21")
})

test_that("._java_parse_version_output handles noisy first line (regression test)", {
  output <- c(
    'Picked up _JAVA_OPTIONS: -Djava.awt.headless=true',
    'openjdk version "21" 2023-09-19'
  )
  expect_equal(._java_parse_version_output(output), "21")
})

test_that("._java_parse_version_output handles timeout/error inputs", {
  expect_false(._java_parse_version_output(character(0)))
  expect_false(._java_parse_version_output(NULL))
})

test_that("._java_parse_version_output handles output with no version", {
  output <- c("Some random output", "No version here")
  expect_false(._java_parse_version_output(output))
})
test_that("._java_parse_version_output handles real-world SDKMAN outputs", {
  # 21.0.2-open (OpenJDK 21)
  expect_equal(
    ._java_parse_version_output(c(
      'openjdk version "21.0.8" 2025-07-15 LTS',
      'OpenJDK Runtime Environment Temurin-21.0.8+9 (build 21.0.8+9-LTS)',
      'OpenJDK 64-Bit Server VM Temurin-21.0.8+9 (build 21.0.8+9-LTS, mixed mode, sharing)'
    )),
    "21"
  )

  # 17.0.10-tem (Temurin 17)
  expect_equal(
    ._java_parse_version_output(c(
      'openjdk version "17.0.10" 2024-01-16',
      'OpenJDK Runtime Environment Temurin-17.0.10+7 (build 17.0.10+7)',
      'OpenJDK 64-Bit Server VM Temurin-17.0.10+7 (build 17.0.10+7, mixed mode)'
    )),
    "17"
  )

  # 8.0.402-amzn (Corretto 8)
  expect_equal(
    ._java_parse_version_output(c(
      'openjdk version "1.8.0_402"',
      'OpenJDK Runtime Environment Corretto-8.402.07.1 (build 1.8.0_402-b07)',
      'OpenJDK 64-Bit Server VM Corretto-8.402.07.1 (build 25.402-b07, mixed mode)'
    )),
    "8"
  )

  # 11.0.22-ms (Microsoft 11)
  expect_equal(
    ._java_parse_version_output(c(
      'openjdk version "11.0.22" 2024-01-16 LTS',
      'OpenJDK Runtime Environment Microsoft-8909545 (build 11.0.22+7-LTS)',
      'OpenJDK 64-Bit Server VM Microsoft-8909545 (build 11.0.22+7-LTS, mixed mode)'
    )),
    "11"
  )

  # 22-open (OpenJDK 22)
  expect_equal(
    ._java_parse_version_output(c(
      'openjdk version "22" 2024-03-19',
      'OpenJDK Runtime Environment (build 22+36-2370)',
      'OpenJDK 64-Bit Server VM (build 22+36-2370, mixed mode, sharing)'
    )),
    "22"
  )

  # 17.0.10-zulu (Zulu 17)
  expect_equal(
    ._java_parse_version_output(c(
      'openjdk version "17.0.10" 2024-01-16 LTS',
      'OpenJDK Runtime Environment Zulu17.48+15-CA (build 17.0.10+7-LTS)',
      'OpenJDK 64-Bit Server VM Zulu17.48+15-CA (build 17.0.10+7-LTS, mixed mode, sharing)'
    )),
    "17"
  )

  # Issue #81 Regression Case: OpenJDK 17 (2021 release) without minor version
  # "openjdk version \"17\" 2021-09-14"
  expect_equal(
    ._java_parse_version_output(c(
      'openjdk version "17" 2021-09-14',
      'OpenJDK Runtime Environment (build 17+35-2724)',
      'OpenJDK 64-Bit Server VM (build 17+35-2724, mixed mode, sharing)'
    )),
    "17"
  )

  # Amazon Corretto 8
  expect_equal(
    ._java_parse_version_output(c(
      'openjdk version "1.8.0_402"',
      'OpenJDK Runtime Environment Corretto-8.402.07.1 (build 1.8.0_402-b07)',
      'OpenJDK 64-Bit Server VM Corretto-8.402.07.1 (build 25.402-b07, mixed mode)'
    )),
    "8"
  )

  # Amazon Corretto 11 (simulated based on typical format)
  expect_equal(
    ._java_parse_version_output(c(
      'openjdk version "11.0.12" 2021-07-20 LTS',
      'OpenJDK Runtime Environment Corretto-11.0.12.7.1 (build 11.0.12+7-LTS)',
      'OpenJDK 64-Bit Server VM Corretto-11.0.12.7.1 (build 11.0.12+7-LTS, mixed mode)'
    )),
    "11"
  )
})
