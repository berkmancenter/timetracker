#!/bin/bash

docker build -t timetracker -f docker/Dockerfile --no-cache .
image_id=$(docker images | grep timetracker | awk '{print $3}' | tail -n 1)
docker tag $image_id berkmancenter/timetracker:$1
docker tag $image_id berkmancenter/timetracker:latest
docker push berkmancenter/timetracker:$1
docker push berkmancenter/timetracker:latest
