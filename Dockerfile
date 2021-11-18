FROM docker:stable
RUN apk add --update \
    python3 \
    curl \
    which \
    bash

ENV CLOUDSDK_INSTALL_DIR /usr/local/gcloud/
# Downloading gcloud package
RUN curl -sSL https://sdk.cloud.google.com | bash
# Adding the package path to local
ENV PATH $PATH:/usr/local/gcloud/google-cloud-sdk/bin

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x entrypoint.sh
ENTRYPOINT ["bash", "/entrypoint.sh"]
