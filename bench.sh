#!/bin/bash

set -x

for capture in pcap afpacket ebpf ; do
    for pps in $(seq 10000 10000 130000) ; do
        ./run-bench-flow-agent.sh $capture $pps
    done
done
