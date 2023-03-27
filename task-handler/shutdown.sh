#!/bin/bash

PREEMPTED=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/preempted" -H "Metadata-Flavor: Google")

# if the VM is shutdown because it was preempted
if [ "$PREEMPTED" == "TRUE" ]
# if the machine is turned off, we send a request to the API with the information
# necessary to re-create the VM
curl -X POST "https://autorunner-task-scheduler-fzwjxdcwoq-uc.a.run.app/preemptible" \
     -H 'Content-Type: application/json' \
     -d '{"instance_id":"<instance_id>","labels": "<labels>", gpu: "<gpu>"}'
fi
