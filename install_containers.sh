#!/bin/bash
function install_dependencies() {
    yum groupinstall -y "Development Tools"
    yum install -y java-1.8.0-openjdk-devel
    debuginfo-install -y java-1.8.0-openjdk
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


install_dependencies
setup_perf_map_agent

