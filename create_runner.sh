#!/usr/bin/env bash
RESOURCE_NAME=$1
gcloud --project $2 compute instances create "$RESOURCE_NAME" \
--image-family "debian-9" --image-project "debian-cloud" \
--machine-type "g1-small" --network "default" --maintenance-policy "MIGRATE" \
--service-account "$5" \
--scopes "https://www.googleapis.com/auth/devstorage.read_write","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/compute" \
--tags "http-server","https-server","gitlab-runner" \
--boot-disk-size "10" --boot-disk-type "pd-standard" --boot-disk-device-name "$RESOURCE_NAME" \
--metadata register_token=$3,config_bucket=gitlab_config,runner_name=${RESOURCE_NAME},gitlab_uri=$4,runner_tags=backend \
--metadata-from-file "startup-script=startup-scripts/prepare-runner.sh"