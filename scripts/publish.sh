#!/bin/bash
#
# Publish images to your ECR account.

set -euo pipefail

source scripts/shared.sh

parse_std_args "$@"

$(aws ecr get-login --no-include-email --registry-id $aws_account)
docker tag sagemaker-tensorflow-serving:$app_name-$full_version-$arch $aws_account.dkr.ecr.$aws_region.amazonaws.com/io-dev-demo:$app_name-$full_version-$arch
docker tag sagemaker-tensorflow-serving:$app_name-$full_version-$arch $aws_account.dkr.ecr.$aws_region.amazonaws.com/io-dev-demo:$app_name-$short_version-$arch
docker push $aws_account.dkr.ecr.$aws_region.amazonaws.com/io-dev-demo:$app_name-$full_version-$arch
docker push $aws_account.dkr.ecr.$aws_region.amazonaws.com/io-dev-demo:$app_name-$short_version-$arch
docker logout https://$aws_account.dkr.ecr.$aws_region.amazonaws.com
