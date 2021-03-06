#!/bin/bash

set -euo pipefail

# Keep in order to prevent older versions from overwriting when given the "short version" tag.
declare -a versions=("nightly" "1.11.0" "1.11.1" "1.12.0" "1.13.0")
push=0 # arbitrary assignment
function get_full_version() {
    echo $1 | sed 's#^\([0-9][0-9]*\.[0-9][0-9]*\)$#\1.0#'
}

function get_short_version() {
    echo $1 | sed 's#\([0-9][0-9]*\.[0-9][0-9]*\)\.[0-9][0-9]*#\1#'
}

function error() {
    >&2 echo $1
    >&2 echo "usage: $0 [--arch (cpu*|gpu)] [--hub_user <DOCKER_HUB_USER>] [--push]"
    exit 1
}

function parse_std_args() {
    # defaults
    arch='cpu'

    while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -a|--arch)
        arch="$2"
        shift
        shift
        ;;
        -h|--hub_user)
        hub_user="$2"
        shift
        shift
        ;;
        -p|--push)
        push=1
        shift
        ;;
        *) # unknown option
        error "unknown option: $1"
        shift
        ;;
    esac
    done

    [[ "$arch" =~ ^(cpu|gpu|eia)$ ]] || error "invalid arch: $arch"
    [[ -z "${hub_user// }" ]] && error 'missing hub_user'

    true
}

parse_std_args "$@"

for i in "${versions[@]}"
do
   full_version=$(get_full_version $i)
   short_version=$(get_short_version $i)
   version_check="$(echo $short_version |tr -d '.' )"

   if [[ "$version_check" == nightly* ]] || [[ $version_check -ge 113 ]]; then
     cuda_version=10.0
     cuda_version_dash=10-0
     nccl_version=2.4.2
     cudnn_version=7.3.0.29
     tf_tensorrt_version=5.0.2
     libnvinfer_version=5
     libnvinfer_tf_tensorrt_version=5.0.2
   else
     cuda_version=9.0
     cuda_version_dash=9-0
     nccl_version=2.2.13
     cudnn_version=7.2.1.38
     tf_tensorrt_version=5.0.2
     libnvinfer_version=5
     libnvinfer_tf_tensorrt_version=5.0.2
   fi

   echo -e "\n\n\n\n"
   echo -e "\033[0;32mbuilding ${arch} image with tf version ${full_version}.\033[0m"

   docker pull $hub_user/sagemaker-tensorflow-serving:$short_version-$arch &>/dev/null || echo 'warning: pull failed'

   docker build \
       --cache-from $hub_user/sagemaker-tensorflow-serving:$short_version-$arch \
       --build-arg TFS_VERSION=$full_version \
       --build-arg TFS_SHORT_VERSION=$short_version \
       --build-arg CUDA_VERSION_IMAGE=$cuda_version \
       --build-arg CUDA_VERSION_PACKAGES=$cuda_version \
       --build-arg CUDA_VERSION_DASH=$cuda_version_dash \
       --build-arg NCCL_VERSION=$nccl_version \
       --build-arg CUDNN_VERSION=$cudnn_version \
       --build-arg TF_TENSORRT_VERSION=$tf_tensorrt_version \
       --build-arg LIBNVINFER_VERSION=$libnvinfer_version \
       --build-arg LIBNVINFER_TF_TENSORRT_VERSION=$libnvinfer_tf_tensorrt_version \
       -f docker/Dockerfile.$arch \
       -t $hub_user/sagemaker-tensorflow-serving:$full_version-$arch \
       -t $hub_user/sagemaker-tensorflow-serving:$short_version-$arch container

   if [ $push == '1' ]; then
     echo "publishing image $hub_user/sagemaker-tensorflow-serving:$full_version-$arch"
     docker push $hub_user/sagemaker-tensorflow-serving:$full_version-$arch
     echo "publishing image $hub_user/sagemaker-tensorflow-serving:$short_version-$arch"
     docker push $hub_user/sagemaker-tensorflow-serving:$short_version-$arch
   fi

done
