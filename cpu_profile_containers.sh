function install_dependencies() {
    yum install -y perf
    yum install -y sysstat
}
function setup_flame_graphs() {
    git clone --depth=1 https://github.com/brendangregg/FlameGraph
}

COUNT=0
ODL_HOST_PID=$(ps aux | grep opendaylight | awk 'FNR == 2 {print$2}')
ODL_CONTAINER_PID=$(docker exec opendaylight_api ps aux | grep opendaylight | awk 'FNR == 2 {print$2}')
sudo docker exec opendaylight_api install_containers.sh 
install_dependencies
setup_flame_graphs
while true
do
    pidstat -p ${ODL_HOST_PID} 1 2 > output.txt 2>&1
    CPU_USAGE=$(cat output.txt | awk 'FNR == 6 {print$4}')
    INT_CPU_USAGE=${CPU_USAGE%.*}
    echo "cpu usage is $INT_CPU_USAGE"
    if [ "$INT_CPU_USAGE" -eq 100 ]; then
        COUNT=$((COUNT+1))
        echo "capturing perf data $COUNT time"
        sudo perf record -F 99 -a -g -- sleep 30
        while true; do
             sudo docker exec opendaylight_api perf-map-agent.sh
             if [ "$?" -eq 0 ]; then
                 break
             fi
             sleep 5
        done
        sudo docker cp /tmp/perf-${ODL_CONTAINER_PID}.map /tmp/
        mv /tmp/perf-${ODL_CONTAINER_PID}.map /tmp/perf-${ODL_HOST_PID}.map
        sudo chown root /tmp/perf-*.map
        sudo perf script | ./FlameGraph/stackcollapse-perf.pl | ./FlameGraph/flamegraph.pl --color=java --hash > flamegraph_${COUNT}_${INT_CPU_USAGE}-$(date '+%Y-%m-%d %H:%M:%S').svg
    fi
    sleep 5
done

