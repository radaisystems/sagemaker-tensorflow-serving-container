#!/bin/bash
#
# Build the docker images.

set -euo pipefail

source scripts/shared.sh

parse_std_args "$@"

echo "pulling previous image for layer cache... "
$(aws ecr get-login --no-include-email --registry-id $aws_account) &>/dev/null || echo 'warning: ecr login failed'
docker pull $aws_account.dkr.ecr.$aws_region.amazonaws.com/sagemaker-tensorflow-serving:$full_version-$arch &>/dev/null || echo 'warning: pull failed'
docker logout https://$aws_account.dkr.ecr.$aws_region.amazonaws.com &>/dev/null

echo "building image... "
docker build \
    --cache-from $aws_account.dkr.ecr.$aws_region.amazonaws.com/sagemaker-tensorflow-serving:$app_name-$full_version-$arch \
    --build-arg TFS_VERSION=$full_version \
    --build-arg TFS_SHORT_VERSION=$short_version \
    --build-arg AWS_ACCESS_KEY_ID=$aws_access_key_id \
    --build-arg AWS_SECRET_ACCESS_KEY=$aws_secret_access_key \
    -f docker/Dockerfile.gpu \
    -t sagemaker-tensorflow-serving:$app_name-$full_version-$arch \
    -t sagemaker-tensorflow-serving:$app_name-$short_version-$arch .
