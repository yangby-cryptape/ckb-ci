# CKB CI

[![License]](#license)

A Collection of several deployment scripts, which are used to deploy CI
servers for testing [CKB].

## Contents

- [Scripts to setup a Jenkins Server for benchmarking CKB.](bin/ckb-ci-benchmark)

- [Scripts to setup a 24\*7 Service for running CKB integration tests continuously.](bin/ckb-ci-it-24x7)

  **Requirements: docker**

  ```bash
  # Build a docker and install tools into it
  bin/ckb-ci-it-24x7 env build

  # Set credentials
  bin/ckb-ci-it-24x7 setup "${REMOTE_USER}" "${REMOTE_HOST}" \
      "${PATH_TO_THE_SSHKEY}" "${SENTRY_DSN}"

  # Deploy and start the tests
  bin/ckb-ci-it-24x7 deploy

  # Remove all secret files
  bin/ckb-ci-it-24x7 clean

  # Remove the docker
  bin/ckb-ci-it-24x7 env remove
  ```

[License]: https://img.shields.io/badge/License-Apache--2.0%20OR%20MIT-blue.svg

## License

Licensed under either of [Apache License, Version 2.0] or [MIT License], at
your option.

[Apache License, Version 2.0]: LICENSE-APACHE
[MIT License]: LICENSE-MIT

[CKB]: https://github.com/nervosnetwork/ckb
