function install_dependencies() {
    yum groupinstall -y "Development Tools"
    yum install -y java-1.8.0-openjdk-devel
    yum install -y perf
    yum install -y cmake
    yum install -y sysstat
}

function setup_perf_map_agent() {
    pushd /opt/opendaylight
    git clone --depth=1 https://github.com/jvm-profiling-tools/perf-map-agent
    pushd perf-map-agent
    cmake .
    make
    popd
    popd
}

function setup_flame_graphs() {
    git clone --depth=1 https://github.com/brendangregg/FlameGraph
}


function generate_symbols() {
    ODL_PID=$1
    export ODL_PID
    runuser -u odl -- /bin/sh -c '(export JAVA_HOME=/lib/jvm/java-1.8.0-openjdk/; cd /opt/opendaylight/perf-map-agent/out; java -cp attach-main.jar:$JAVA_HOME/lib/tools.jar net.virtualvoid.perf.AttachOnce $ODL_PID)'
}

COUNT=0
ODL_PID=$(pgrep java)
install_dependencies
setup_perf_map_agent
setup_flame_graphs
while true
do
    pidstat -p ${ODL_PID} 1 2 > output.txt 2>&1
    CPU_USAGE=$(cat output.txt | awk 'FNR == 6 {print$4}')
    INT_CPU_USAGE=${CPU_USAGE%.*}
    echo "cpu usage is $INT_CPU_USAGE"
    if [ "$INT_CPU_USAGE" -eq 100 ]; then
        COUNT=$((COUNT+1))
        echo "capturing perf data $COUNT time"
        runuser -u odl -- /bin/sh -c '(jstack $ODL_PID)' > jstack_${COUNT}_${INT_CPU_USAGE}.txt 2>&1
        sudo perf record -F 99 -a -g -- sleep 30
        generate_symbols $ODL_PID
        sudo chown root /tmp/perf-*.map
        sudo perf script | ./FlameGraph/stackcollapse-perf.pl | ./FlameGraph/flamegraph.pl --color=java --hash > "flamegraph_${COUNT}_${INT_CPU_USAGE}_${DATE}.svg"
    fi
    sleep 5
done

