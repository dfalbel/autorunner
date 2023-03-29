#! /bin/bash

PREEMPTED=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/preempted" -H "Metadata-Flavor: Google")

echo "Preempred: $PREEMPTED"

DIR="/home/actions/actions-runner/"

# if the VM is shutdown because it was preempted
if [ -d "$DIR" ]
then
REQ=$(curl -X POST "https://autorunner-task-scheduler-fzwjxdcwoq-uc.a.run.app/preemptible?instance_id=<instance_id>&labels=<labels>&gpu=<gpu>&actions=1" -H "accept: */*" -d "")
else
REQ=$(curl -X POST "https://autorunner-task-scheduler-fzwjxdcwoq-uc.a.run.app/preemptible?instance_id=<instance_id>&labels=<labels>&gpu=<gpu>&actions=0" -H "accept: */*" -d "")
fi

echo $REQ
