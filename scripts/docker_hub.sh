#!/bin/bash

set -euo pipefail

source scripts/shared.sh

parse_std_args "$@"

[[ -z "${hub_user// }" ]] && error 'missing hub_user'

declare -a versions=("nightly" "1.13.0-rc1" "1.12.0" "1.11.1" "1.11.0")

for i in "${versions[@]}"
do
   full_version=$(get_full_version $i)
   short_version=$(get_short_version $i)

   echo "building ${arch} image with tf version ${full_version}."

   docker pull $hub_user/sagemaker-tensorflow-serving:$short_version-$arch &>/dev/null || echo 'warning: pull failed'

   docker build \
       --cache-from $hub_user/sagemaker-tensorflow-serving:$short_version-$arch \
       --build-arg TFS_VERSION=$full_version \
       --build-arg TFS_SHORT_VERSION=$short_version \
       -f docker/Dockerfile.$arch \
       -t $hub_user/sagemaker-tensorflow-serving:$full_version-$arch \
       -t $hub_user/sagemaker-tensorflow-serving:$short_version-$arch container

   if [ -n "$push" ]; then
     echo "publishing image $hub_user/sagemaker-tensorflow-serving:$full_version-$arch"
     docker push $hub_user/sagemaker-tensorflow-serving:$full_version-$arch
     echo "publishing image $hub_user/sagemaker-tensorflow-serving:$short_version-$arch"
     docker push $hub_user/sagemaker-tensorflow-serving:$short_version-$arch
   fi

done
