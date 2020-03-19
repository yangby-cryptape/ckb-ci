#!/usr/bin/env bash

set -euo pipefail

currdir="$(pwd)"
workdir="${currdir}/workdir"

function github_comment () {
    local message="${1}"
    if [ -n "${ghprbPullId}" ] && [ -n "${ghprbGhRepository}" ]; then
        curl -s -X POST \
            -H "Authorization: token ${GITHUB_API_TOKEN}" \
            -d "{\"body\": \"${message}\"}" \
            "https://api.github.com/repos/${ghprbGhRepository}/issues/${ghprbPullId}/comments"
    fi
}

function exit_func () {
    if [ -d "${workdir}" ]; then
        cd "${workdir}"
        ./bin/ckb-ci free
        rm etc/terraform/terraform.tfvars
    fi
}

trap exit_func EXIT

function main () {
    cd "${currdir}"

    if [ -n "${ghprbActualCommit}" ]; then
        CKB_VERSION="${ghprbActualCommit}"
    fi
    if [ -n "${ghprbGhRepository}" ]; then
        CKB_GHREPO="${ghprbGhRepository}"
    fi

    # example: branch-name, tag, commit-id
    echo "[INFO] CKB Version = [${CKB_VERSION}]"
    echo "[INFO] CKB GitHub Repository = [${CKB_GHREPO}]"
    # example: c5.xlarge
    echo "[INFO] Instance Type = [${INSTANCE_TYPE}]"
    echo "[INFO] Instances Count = [${INSTANCES_COUNT}]"
    # example: 2in2out, mixed
    echo "[INFO] Bench Type = [${BENCH_TYPE}]"
    echo "[INFO] Expected Samples Count = [${EXPECTED_SAMPLES_COUNT}]"

    export CKB_CI_NOCOLOR=true

    if [ -d "${workdir}" ]; then
        rm -rfv "${workdir}"
    fi

    mkdir -p "${workdir}"
    cd "${workdir}"

    cp -r /mnt/workdir/bin ./
    cp -r /mnt/workdir/etc ./

    local instances_count=$((INSTANCES_COUNT - 1))
    echo "access_key      = \"${AWS_ACCESS_KEY}\"" >  etc/terraform/terraform.tfvars
    echo "secret_key      = \"${AWS_SECRET_KEY}\"" >> etc/terraform/terraform.tfvars
    echo "instances_count = ${instances_count}"    >> etc/terraform/terraform.tfvars
    echo "instance_type   = \"${INSTANCE_TYPE}\""  >> etc/terraform/terraform.tfvars

    ./bin/ckb-ci bench init

    echo "[all:vars]"                                       >> etc/ansible/hosts
    echo "ckb_ghrepo=${CKB_GHREPO}"                         >> etc/ansible/hosts
    echo "ckb_version=${CKB_VERSION}"                       >> etc/ansible/hosts
    echo "bench_type=${BENCH_TYPE}"                         >> etc/ansible/hosts
    echo "expected_samples_count=${EXPECTED_SAMPLES_COUNT}" >> etc/ansible/hosts

    ./bin/ckb-ci bench setup
    ./bin/ckb-ci bench prepare
    ./bin/ckb-ci bench run
    ./bin/ckb-ci bench result

    find . -type f -name "bench.result" -exec cat {} \; > result.log
    rm -rf bench.result
    cat result.log
    local count=$(wc -l result.log | awk -F' ' '{ printf $1 }')
    local tps_sum_tmp=$(\
        cat result.log \
        | awk -F'TPS:' '{ print $2 }' \
        | awk -F',' '{ print $1 }' \
        | tr -d ' ' \
        | paste -sd+\
    )
    local tps=$(echo "scale=2; (${tps_sum_tmp}) / ${count}" | bc)
    local result=$(printf "#### Benchmark Result\\\\r  - TPS = %s\\\\r  - Samples Count = %s\\\\r  - CKB Version = %s\\\\r  - Instance Type = %s\\\\r  - Instances Count = %s\\\\r  - Bench Type = %s\\\\r" \
        "${tps}" "${count}" "${CKB_VERSION}" "${INSTANCE_TYPE}" "${INSTANCES_COUNT}" "${BENCH_TYPE}")
    echo "[INFO] ${result}"
    github_comment "${result}"
}

main "$@"
