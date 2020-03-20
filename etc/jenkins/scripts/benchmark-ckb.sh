#!/usr/bin/env bash

set -euo pipefail

currdir="$(pwd)"
workdir="${currdir}/workdir"

HAS_LOGS=false

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
    set +e
    if [ -d "${workdir}" ]; then
        cd "${workdir}"
        if [ "${HAS_LOGS}" = "true" ]; then
            ./bin/ckb-ci bench logs
        fi
        ./bin/ckb-ci free
        rm etc/terraform/terraform.tfvars
        if [ -d "ckb-logs" ]; then
            local timestamp=$(date +"%Y%m%d%H%M%S")
            local version=$(echo "${CKB_VERSION}" | cut -c 1-7)
            local log_id="ckb-logs-${version}-${timestamp}"
            mv "ckb-logs" "${log_id}"
            tar -czvf "${log_id}.tgz" "${log_id}"
            rm -rf "${log_id}"
            mkdir -p "${currdir}/ckb-logs"
            mv "${log_id}.tgz" "${currdir}/ckb-logs/"
        fi
    fi
}

trap exit_func EXIT

function main () {
    cd "${currdir}"

    if [ -n "${ghprbActualCommit}" ]; then
        CKB_VERSION="${ghprbActualCommit}"
    fi
    if [ -n "${ghprbAuthorRepoGitUrl}" ]; then
        CKB_GHREPO="${ghprbAuthorRepoGitUrl}"
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
    echo "[INFO] CKB Logger Filter = [${CKB_LOGGER_FILTER}]"

    export CKB_CI_NOCOLOR=true

    if [ -d "${workdir}" ]; then
        rm -rfv "${workdir}"
    fi

    mkdir -p "${workdir}"
    cd "${workdir}"

    cp -r /mnt/workdir/bin ./
    cp -r /mnt/workdir/etc ./

    local terraform_tfvars="etc/terraform/terraform.tfvars"
    local instances_count=$((INSTANCES_COUNT - 1))
    echo "access_key      = \"${AWS_ACCESS_KEY}\"" >  "${terraform_tfvars}"
    echo "secret_key      = \"${AWS_SECRET_KEY}\"" >> "${terraform_tfvars}"
    echo "instances_count = ${instances_count}"    >> "${terraform_tfvars}"
    echo "instance_type   = \"${INSTANCE_TYPE}\""  >> "${terraform_tfvars}"

    ./bin/ckb-ci bench init

    local ansible_hosts="etc/ansible/hosts"
    echo "[all:vars]"                                       >> "${ansible_hosts}"
    echo "ckb_ghrepo=${CKB_GHREPO}"                         >> "${ansible_hosts}"
    echo "ckb_version=${CKB_VERSION}"                       >> "${ansible_hosts}"
    echo "bench_type=${BENCH_TYPE}"                         >> "${ansible_hosts}"
    echo "expected_samples_count=${EXPECTED_SAMPLES_COUNT}" >> "${ansible_hosts}"
    echo "ckb_logger_filter=${CKB_LOGGER_FILTER}"           >> "${ansible_hosts}"

    echo "[INFO] Review the ansible hosts file:"
    cat "${ansible_hosts}"

    ./bin/ckb-ci bench setup

    HAS_LOGS=true

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

    local result="#### Benchmark Result"
    result="${result}\\r  - TPS: ${tps}"
    result="${result}\\r  - Samples Count: ${count}"
    result="${result}\\r  - CKB Version: ${CKB_VERSION}"
    result="${result}\\r  - Instance Type: ${INSTANCE_TYPE}"
    result="${result}\\r  - Instances Count: ${INSTANCES_COUNT}"
    result="${result}\\r  - Bench Type: ${BENCH_TYPE}"
    result="${result}\\r  - CKB Logger Filter: ${CKB_LOGGER_FILTER}"
    echo "[INFO] ${result}"
    github_comment "${result}"
}

main "$@"
