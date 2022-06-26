#!/bin/sh

set -euo pipefail
IFS=$(printf ' \n\t')

debug() {
  if [ "${ACTIONS_RUNNER_DEBUG:-}" = "true" ]; then
    echo "DEBUG: :: $*" >&2
  fi
}

if [ -n "${INPUT_AWS_ACCESS_KEY_ID:-}" ]; then
  export AWS_ACCESS_KEY_ID="${INPUT_AWS_ACCESS_KEY_ID}"
fi

if [ -n "${INPUT_AWS_SECRET_ACCESS_KEY:-}" ]; then
  export AWS_SECRET_ACCESS_KEY="${INPUT_AWS_SECRET_ACCESS_KEY}"
fi

if [ -n "${INPUT_AWS_REGION:-}" ]; then
  export AWS_DEFAULT_REGION="${INPUT_AWS_REGION}"
fi

if [ -n "${INPUT_MANIFESTS_FILE:-}" ] && [ -n "${INPUT_IMAGE:-}" ]; then
#   # export AWS_DEFAULT_REGION="${INPUT_AWS_REGION}"
  sed -i "s#image:.*#image: ${INPUT_IMAGE}#g" ${INPUT_MANIFESTS_FILE}
fi

echo "aws version"

aws --version

echo "Attempting to update kubeconfig for aws"

if [ -n "${INPUT_EKS_ROLE_ARN}" ]; then
  aws eks update-kubeconfig --name "${INPUT_CLUSTER_NAME}" --role-arn "${INPUT_EKS_ROLE_ARN}"
else 
  aws eks update-kubeconfig --name "${INPUT_CLUSTER_NAME}"
fi
cat ${INPUT_MANIFESTS_FILE}
echo "----"
kubectl --kubeconfig=/github/home/.kube/config apply -f ${INPUT_MANIFESTS_FILE}
# sed -i "s#image:.*#image: ${INPUT_IMAGE}#g" ${INPUT_MANIFESTS_FILE}
debug "Starting kubectl collecting output"
output=$( kubectl "$@" )
debug "${output}"
echo ::set-output name=kubectl-out::"${output}"
