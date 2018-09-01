#!/bin/bash
ODL_CONTAINER_PID=$1
COUNT=$2
INT_CPU_USAGE=$3
function generate_symbols() {
    export ODL_CONTAINER_PID
    runuser -u odl -- /bin/sh -c '(export JAVA_HOME=/lib/jvm/java-1.8.0-openjdk/; cd /opt/opendaylight/perf-map-agent/out; java -cp attach-main.jar:$JAVA_HOME/lib/tools.jar net.virtualvoid.perf.AttachOnce $ODL_CONTAINER_PID)'
}

function generate_jstack() {
    runuser -u odl -- /bin/sh -c '(jstack $ODL_CONTAINER_PID)' > /tmp/jstack_${COUNT}_${INT_CPU_USAGE}.txt 2>&1
}
function generate_jmap() {
    export ODL_CONTAINER_PID
    export COUNT
    export INT_CPU_USAGE
    runuser -u odl -- /bin/sh -c '(jmap -dump:format=b,file=/tmp/HeapDump_${COUNT}_${INT_CPU_USAGE}.hprof $ODL_CONTAINER_PID)'
}
generate_symbols
generate_jstack
generate_jmap
