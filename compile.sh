#! /bin/bash
workspace=$(dirname $0)
shc -r -f $workspace/vue-init.sh -o $workspace/vue-init
rm $workspace/vue-init.sh.x.c
