test_that("bad java_distrib_path", {
  bad_path <- tempfile()
  expect_error(java_unpack(bad_path))

  bad_path <- "/home/johndoe/.cache/R/rJavaEnv/distrib/amazon-corretto-21-x64-linux-jdk.tar.7z"
  expect_error(java_unpack(fake_path, "Unsupported file format"))

  bad_path <- "/home/johndoe/.cache/R/rJavaEnv/distrib/amazon-corretto-x64-linux-jdk.tar.zip"
  expect_error(java_unpack(fake_path, "Java version"))

  bad_path <- "/home/johndoe/.cache/R/rJavaEnv/distrib/amazon-corretto-linux-jdk.tar.zip"
  expect_error(java_unpack(fake_path, "architecture"))

  bad_path <- "/home/johndoe/.cache/R/rJavaEnv/distrib/amazon-corretto-21-x64-msdos-jdk.tar.zip"
  expect_error(java_unpack(fake_path, "platform"))

})
