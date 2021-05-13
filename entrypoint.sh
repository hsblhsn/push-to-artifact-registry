#!/bin/sh

GCP_PROJECT_ID=$1
GCP_REGION=$2
GCP_SA=$3
DEPLOYMENT_NAMESPACE=$4


DOCKER_IMAGE="${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${DEPLOYMENT_NAMESPACE}/${GITHUB_REPOSITORY}:${GITHUB_SHA}"
echo "TARGET: ${DOCKER_IMAGE}"

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
gcloud --quiet auth configure-docker us-central1-docker.pkg.dev

# build the docker image.
echo "Building docker image..."
docker build --tag "$DOCKER_IMAGE" .

# push the docker image.
echo "Pushing docker image..."
docker push "$DOCKER_IMAGE"

echo "::set-output name=pushed_image::$DOCKER_IMAGE"