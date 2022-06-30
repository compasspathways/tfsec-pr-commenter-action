#!/bin/bash
set -xe

ARCH=$(uname -m)
if [ "${ARCH}" == "x86_64" ]; then
  ARCH="amd64"
fi

if [ "${ARCH}" == "aarch64" ] || [ "${ARCH}" == "arm64" ]; then
  ARCH="arm64"
fi

# default to latest
TFSEC_VERSION="latest"

# if INPUT_TFSEC_VERSION set and not latests
if [ -n "${INPUT_TFSEC_VERSION}" ] && [ "${INPUT_TFSEC_VERSION}" != "latest" ]; then
  TFSEC_VERSION="tags/${INPUT_TFSEC_VERSION}"
fi

# Pull https://api.github.com/repos/aquasecurity/tfsec/releases for the full list of releases. NOTE no trailing slash
wget -O - -q "$(wget -q https://api.github.com/repos/aquasecurity/tfsec/releases/${TFSEC_VERSION} -O - | grep -m 1 -o -E "https://.+?tfsec-linux-${ARCH}" | head -n1)" > "tfsec-linux-${ARCH}"
wget -O - -q "$(wget -q https://api.github.com/repos/aquasecurity/tfsec/releases/${TFSEC_VERSION} -O - | grep -m 1 -o -E "https://.+?tfsec_checksums.txt" | head -n1)" > tfsec.checksums

# pipe out the checksum and validate
grep "tfsec-linux-${ARCH}" tfsec.checksums > "tfsec-linux-${ARCH}.checksum"
sha256sum -c "tfsec-linux-${ARCH}.checksum"
install "tfsec-linux-${ARCH}" /usr/local/bin/tfsec

COMMENTER_VERSION="latest"
if [ "$INPUT_COMMENTER_VERSION" != "latest" ]; then
  COMMENTER_VERSION="tags/${INPUT_COMMENTER_VERSION}"
fi

wget -O - -q "$(wget -q https://api.github.com/repos/compasspathways/tfsec-pr-commenter-action/releases/${COMMENTER_VERSION} -O - | grep -o -E "https://.+?commenter-linux-${ARCH}")" > "commenter-linux-${ARCH}"
wget -O - -q "$(wget -q https://api.github.com/repos/compasspathways/tfsec-pr-commenter-action/releases/${COMMENTER_VERSION} -O - | grep -o -E "https://.+?checksums.txt")" > commenter.checksums

grep "commenter-linux-${ARCH}" commenter.checksums > "commenter-linux-${ARCH}.checksum"
sha256sum -c "commenter-linux-${ARCH}.checksum"
install "commenter-linux-${ARCH}" /usr/local/bin/commenter

if [ -n "${GITHUB_WORKSPACE}" ]; then
  cd "${GITHUB_WORKSPACE}" || exit
fi

if [ -n "${INPUT_TFSEC_ARGS}" ]; then
  TFSEC_ARGS_OPTION="${INPUT_TFSEC_ARGS}"
fi

TFSEC_FORMAT_OPTION="json"
TFSEC_OUT_OPTION="results.json"
if [ -n "${INPUT_TFSEC_FORMATS}" ]; then
  TFSEC_FORMAT_OPTION="${TFSEC_FORMAT_OPTION},${INPUT_TFSEC_FORMATS}"
  TFSEC_OUT_OPTION="${TFSEC_OUT_OPTION%.*}"
fi

tfsec --out=${TFSEC_OUT_OPTION} --format=${TFSEC_FORMAT_OPTION} --soft-fail ${TFSEC_ARGS_OPTION} "${INPUT_WORKING_DIRECTORY}"
commenter
