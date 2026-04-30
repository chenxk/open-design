#!/usr/bin/env bash
if [ -z "${BASH_VERSION:-}" ]; then
  if command -v bash >/dev/null 2>&1; then
    exec bash "$0" "$@"
  fi
  echo "This script requires bash. Please run with: bash $0 <dockerhub_user> <version> ..."
  exit 1
fi

set -euo pipefail

# if [[ $# -lt 2 ]]; then
#   echo "Usage: $0 <dockerhub_user> <version> [image_name] [multiarch:true|false] [platforms] [dockerfile] [build_context] [build_name]"
#   echo "Example:"
#   echo "  $0 8216179140 1.0.0 knowmind-agent false"
#   echo "  $0 8216179140 1.0.0 knowmind-agent true linux/amd64,linux/arm64 projects/app/Dockerfile . app"
#   exit 1
# fi

DOCKERHUB_USER="${1:-8216179140}"
VERSION="${2:-v1.0.0}"
IMAGE_NAME="${3:-open-design}"
MULTIARCH="${4:-false}"
PLATFORMS="${5:-linux/amd64,linux/arm64}"
DOCKERFILE="${6:-Dockerfile}"
BUILD_CONTEXT="${7:-.}"
BUILD_NAME="${8:-open-design}"
REPO="${DOCKERHUB_USER}/${IMAGE_NAME}"

echo "==> Repo: ${REPO}"
echo "==> Version: ${VERSION}"
echo "==> Dockerfile: ${DOCKERFILE}"

if [[ ! -f "${DOCKERFILE}" ]]; then
  echo "Dockerfile not found: ${DOCKERFILE}"
  exit 1
fi

docker --version >/dev/null

if [[ "${MULTIARCH}" == "true" ]]; then
  echo "==> Building and pushing multi-arch image..."
  if ! docker buildx inspect multi-builder >/dev/null 2>&1; then
    docker buildx create --name multi-builder --use >/dev/null
  else
    docker buildx use multi-builder >/dev/null
  fi

  docker buildx inspect --bootstrap >/dev/null
  BUILD_ARGS=()
  if [[ -n "${BUILD_NAME}" ]]; then
    BUILD_ARGS+=(--build-arg "name=${BUILD_NAME}")
  fi

  docker buildx build \
    --platform "${PLATFORMS}" \
    -f "${DOCKERFILE}" \
    "${BUILD_ARGS[@]}" \
    -t "${REPO}:${VERSION}" \
    -t "${REPO}:latest" \
    --push "${BUILD_CONTEXT}"
else
  echo "==> Building local image..."
  BUILD_ARGS=()
  if [[ -n "${BUILD_NAME}" ]]; then
    BUILD_ARGS+=(--build-arg "name=${BUILD_NAME}")
  fi

  docker build \
    -f "${DOCKERFILE}" \
    "${BUILD_ARGS[@]}" \
    -t "${REPO}:${VERSION}" \
    -t "${REPO}:latest" \
    "${BUILD_CONTEXT}"

  echo "==> Pushing tags to Docker Hub..."
  docker push "${REPO}:${VERSION}"
  docker push "${REPO}:latest"
fi

echo "==> Done."
echo "Pushed: ${REPO}:${VERSION} and ${REPO}:latest"
