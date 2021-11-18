#!/bin/sh

GCP_PROJECT_ID=$1
GCP_REGION=$2
GCP_SA=$3
REPOSITORY_NAME=$(basename ${GITHUB_REPOSITORY} | sed -e 's/[^[:alnum:]]/-/g' | tr -s '-' | tr A-Z a-z)
SERVICE_NAME=$(basename ${GITHUB_REPOSITORY} | sed -e 's/[^[:alnum:]]/-/g' | tr -s '-' | tr A-Z a-z)


DOCKER_TAG=${GITHUB_REF#refs/tags/}
if [[ $DOCKER_TAG != v* ]] ;
then
  DOCKER_TAG=${GITHUB_SHA::7}
fi
echo "TAG: ${DOCKER_TAG}"
DOCKER_IMAGE="${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${REPOSITORY_NAME}/${SERVICE_NAME}:${DOCKER_TAG}"
DOCKER_IMAGE_LATEST="${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${REPOSITORY_NAME}/${SERVICE_NAME}:latest"
echo "TARGETS:\n\t${DOCKER_IMAGE}\n\t${DOCKER_IMAGE_LATEST}"

# copy the gcp sa first.
mkdir -p /gcp
echo "${GCP_SA}" | base64 -d > /gcp/sa.json

# setup gcloud sdk.
export GOOGLE_APPLICATION_CREDENTIALS=/gcp/sa.json
echo "Activating service account..."
gcloud auth activate-service-account --key-file=/gcp/sa.json

echo "Setting default project..."
gcloud config set project "${GCP_PROJECT_ID}"

# setup docker credentials for us-central1-docker.pkg.dev.
echo "Setting docker credentials..."
gcloud --quiet auth configure-docker
echo "Setting docker credentials for artifact registry..."
gcloud --quiet auth configure-docker "${GCP_REGION}-docker.pkg.dev"

# build and tag the docker image.
echo "Building docker image..."
docker build --tag "$DOCKER_IMAGE" .
docker tag "${DOCKER_IMAGE}" "${DOCKER_IMAGE_LATEST}"

# push the docker images.
echo "Pushing docker image..."
docker push "${DOCKER_IMAGE}"
docker push "${DOCKER_IMAGE_LATEST}"

echo "::set-output name=pushed_image::${DOCKER_IMAGE}"
