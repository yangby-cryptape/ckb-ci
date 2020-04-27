### Scripts to setup a Jenkins Server for benchmarking CKB

**Requirements: docker**

- Build a docker, install tools into it then run the Jenkins server.

  ```bash
  bin/ckb-ci-benchmark env build
  bin/ckb-ci-benchmark env run

  # Show the initial admin password
  bin/ckb-ci-benchmark jenkins show-init-pswd
  ```

- Then, login Jenkins from a browser, and install two plugins:

  - GitHub Pull Request Builder

    Using [THIS FORK](https://github.com/yangby-cryptape/ghprb-plugin/tree/customized) can prevent asking for testing phrase in pull requests.

  - Credentials Binding

    For all passwords and tokens which are used in the build script.

- Setup Jenkins and GitHub.

  The details are omitted, please read documents of Jenkins and GitHub.

- Create a new project and setup it.

  - [Click ME for the build script](benchmark/etc/jenkins/scripts/benchmark-ckb.sh)
