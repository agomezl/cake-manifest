#!/bin/bash

BUILD_DATE=$(date +%d%m%y)
DOCKERHUB_USER=agomezl
DOCKERHUB_REPO=cakeml
DOCKERHUB_TAG=${DOCKERHUB_USER}/${DOCKERHUB_REPO}

#Move to script dir
cd "$(dirname -- "${0}")"

docker build -t ${DOCKERHUB_TAG} -f cakeml.dockerfile .
docker run --name cakeml-reg ${DOCKERHUB_TAG} true
docker cp cakeml-reg:/home/cake/latest.xml ../latest.xml
docker cp cakeml-reg:/home/cake/latest.xml ../versions/${BUILD_DATE}.xml
docker tag ${DOCKERHUB_TAG}:latest ${DOCKERHUB_TAG}:${BUILD_DATE}
docker push ${DOCKERHUB_TAG}:latest
docker push ${DOCKERHUB_TAG}:${BUILD_DATE}
