function install_dependencies() {
    yum groupinstall -y "Development Tools" 
    yum install -y java-1.8.0-openjdk-devel
    yum install -y cmake
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
    su - odl
    export JAVA_HOME=/lib/jvm/java-1.8.0-openjdk/
    pushd /opt/opendaylight/perf-map-agent/out
    java -cp attach-main.jar:$JAVA_HOME/lib/tools.jar net.virtualvoid.perf.AttachOnce $1
    popd
    logout
}

COUNT=0
ODL_PID=$(ps aux | grep opendaylight | awk 'FNR == 1 {print$2}')
install_dependencies
setup_perf_map_agent
setup_flame_graphs
while true
do
    CPU_USAGE=$(pidstat | grep ${ODL_PID} | awk '{print$5}')
    if [ $CPU_USAGE > 200 ]; then
        COUNT=$((COUNT+1))
        generate_symbols $ODL_PID
        sudo perf record -F 99 -a -g -- sleep 60
        sudo chown root /tmp/perf-*.map
        sudo perf script | ./FlameGraph/stackcollapse-perf.pl | ./FlameGraph/flamegraph.pl --color=java --hash > flamegraph_${COUNT}.svg
    fi
    sleep 30
done





