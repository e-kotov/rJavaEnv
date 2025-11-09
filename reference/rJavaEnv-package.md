# rJavaEnv: 'Java' Environments for R Projects

Quickly install 'Java Development Kit (JDK)' without administrative
privileges and set environment variables in current R session or project
to solve common issues with 'Java' environment management in 'R'.
Recommended to users of 'Java'/'rJava'-dependent 'R' packages such as
'r5r', 'opentripplanner', 'xlsx', 'openNLP', 'rWeka', 'RJDBC',
'tabulapdf', and many more. 'rJavaEnv' prevents common problems like
'Java' not found, 'Java' version conflicts, missing 'Java'
installations, and the inability to install 'Java' due to lack of
administrative privileges. 'rJavaEnv' automates the download,
installation, and setup of the 'Java' on a per-project basis by setting
the relevant 'JAVA_HOME' in the current 'R' session or the current
working directory (via '.Rprofile', with the user's consent). Similar to
what 'renv' does for 'R' packages, 'rJavaEnv' allows different 'Java'
versions to be used across different projects, but can also be
configured to allow multiple versions within the same project (e.g. with
the help of 'targets' package). For users who need to install 'rJava' or
other 'Java'-dependent packages from source, 'rJavaEnv' will display a
message with instructions on how to run 'R CMD javareconf' to make the
'Java' configuration permanent, but also provides a function
'java_build_env_set' that sets the environment variables in the current
R session temporarily to allow installation of 'rJava' from source
without 'R CMD javareconf'. On 'Linux', in addition to setting
environment variables, 'rJavaEnv' also dynamically loads 'libjvm.so' to
ensure 'rJava' works correctly. See documentation for more details.

## See also

Useful links:

- <https://github.com/e-kotov/rJavaEnv>

- <https://www.ekotov.pro/rJavaEnv/>

- Report bugs at <https://github.com/e-kotov/rJavaEnv/issues>

## Author

**Maintainer**: Egor Kotov <kotov.egor@gmail.com>
([ORCID](https://orcid.org/0000-0001-6690-5345)) \[copyright holder\]

Authors:

- Chung-hong Chan <chainsawtiney@gmail.com>
  ([ORCID](https://orcid.org/0000-0002-6232-7530))

Other contributors:

- Mauricio Vargas <mavargas11@uc.cl>
  ([ORCID](https://orcid.org/0000-0003-1017-7574)) \[contributor\]

- Hadley Wickham <hadley@posit.co> (use_java feature suggestion and PR
  review) \[contributor\]

- Enrique Mondragon-Estrada <enriquemondragon@proton.me>
  ([ORCID](https://orcid.org/0009-0004-5592-1728)) \[contributor\]

- Jonas Lieth <jonas.lieth@gesis.org>
  ([ORCID](https://orcid.org/0000-0002-3451-3176)) \[contributor\]
