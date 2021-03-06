#!/bin/bash
#
# Build the docker images.

set -euo pipefail

source scripts/shared.sh

parse_std_args "$@"

if [ $arch = 'eia' ]; then
    get_tfs_executable
fi

echo "pulling previous image for layer cache... "
$(aws ecr get-login --no-include-email --registry-id $aws_account) &>/dev/null || echo 'warning: ecr login failed'
docker pull $aws_account.dkr.ecr.$aws_region.amazonaws.com/$repository:$full_version-$device &>/dev/null || echo 'warning: pull failed'
docker logout https://$aws_account.dkr.ecr.$aws_region.amazonaws.com &>/dev/null

echo "building image... "
docker build \
    --cache-from $aws_account.dkr.ecr.$aws_region.amazonaws.com/$repository:$full_version-$device \
    --build-arg TFS_VERSION=$full_version \
    --build-arg TFS_SHORT_VERSION=$short_version \
    --build-arg CUDA_VERSION_IMAGE=$cuda_version \
	--build-arg CUDA_VERSION_PACKAGES=$cuda_version \
	--build-arg CUDA_VERSION_DASH=$cuda_version_dash \
	--build-arg NCCL_VERSION=$nccl_version \
	--build-arg CUDNN_VERSION=$cudnn_version \
	--build-arg TF_TENSORRT_VERSION=$tf_tensorrt_version \
	--build-arg LIBNVINFER_VERSION=$libnvinfer_version \
    -f docker/Dockerfile.$arch \
    -t $repository:$full_version-$device \
    -t $repository:$short_version-$device container
