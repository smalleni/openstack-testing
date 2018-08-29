#!/bin/bash
function install_dependencies() {
    sudo yum install -y perf
    sudo yum install -y sysstat
    sudo yum install -y java-1.8.0-openjdk-devel
    sudo debuginfo-install -y java-1.8.0-openjdk

}
function setup_flame_graphs() {
    if [ ! -d FlameGraph ]; then
        git clone --depth=1 https://github.com/brendangregg/FlameGraph
    fi
}

COUNT=0
ODL_HOST_PID=$(pgrep java)
ODL_CONTAINER_PID=$(docker exec opendaylight_api pgrep java)
while true; do
    sudo docker cp install_containers.sh opendaylight_api:/usr/local/bin/
     if [ "$?" -eq 0 ]; then
                 break
     fi
     sleep 1
done
while true; do
    sudo docker cp perf-map-agent.sh opendaylight_api:/usr/local/bin/
    if [ "$?" -eq 0 ]; then
         break
     fi
    sleep 1
done
sudo docker exec --user root opendaylight_api install_containers.sh 
install_dependencies
setup_flame_graphs
while true
do
    top -b -n 1 > top.txt
    CPU_USAGE=$(cat top.txt | grep ${ODL_HOST_PID} | grep java | awk {'print$9'})
    INT_CPU_USAGE=${CPU_USAGE%.*}
    echo "cpu usage is $INT_CPU_USAGE"
    if [ "$INT_CPU_USAGE" -ge 500 ]; then
        echo "if"
        COUNT=$((COUNT+1))
        echo "capturing perf data $COUNT time"
        sudo perf record -F 99 -a -g -- sleep 5
        sudo docker exec --user root opendaylight_api perf-map-agent.sh $ODL_CONTAINER_PID $COUNT $INT_CPU_USAGE
        while true; do
            sudo docker cp opendaylight_api:/tmp/perf-${ODL_CONTAINER_PID}.map /tmp/
            if [ "$?" -eq 0 ]; then
                 break
            fi
            sleep 1
        done
        while true; do
            sudo docker cp opendaylight_api:jstack_${COUNT}_${INT_CPU_USAGE}.txt ..
            if [ "$?" -eq 0 ]; then
                 break
            fi
            sleep 1
        done
        mv /tmp/perf-${ODL_CONTAINER_PID}.map /tmp/perf-${ODL_HOST_PID}.map
        sudo chown root /tmp/perf-*.map
        DATE=$(date '+%Y-%m-%d_%H:%M:%S')
        sudo perf script | ./FlameGraph/stackcollapse-perf.pl | ./FlameGraph/flamegraph.pl --color=java --hash > "flamegraph_${COUNT}_${INT_CPU_USAGE}_${DATE}.svg"
    fi
    sleep 5
done

