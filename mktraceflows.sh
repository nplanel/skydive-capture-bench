#!/bin/bash

# 4 flows / 56 packets
TraceSource=ip.pcap
# multiply flows by
MultFlowsBy=100000

echo "Trace info : $TraceSource"
capinfos $TraceSource | grep 'Number of packets:'
nbFlows=$(tshark -q -r $TraceSource -z conv,tcp -z conv,udp | grep '<->' | wc -l)
echo "nbFlows: $nbFlows"

# cleanup
find . -maxdepth 1 -name "out-*.pcap" -o -name "out2-*.pcap" | xargs rm -f
rm -f out.pcap

for i in $(seq $MultFlowsBy); do
    #cp pcapsave/out-$i.pcap .
    tcprewrite -i $TraceSource -s $i -o out-$i.pcap

    if [[ $(($i % 100)) == 0 ]]; then
        echo "trace generated : $i / $MultFlowsBy"
        find . -maxdepth 1 -name "out-*.pcap" | xargs -n 100 mergecap -a -w out2-$i.pcap -F pcap
        find . -maxdepth 1 -name "out-*.pcap" | xargs rm -f
    fi
done

find . -maxdepth 1 -name "out-*.pcap" | xargs -r -n 100 mergecap -a -w out2-end.pcap -F pcap
find . -maxdepth 1 -name "out-*.pcap" | xargs -r rm -f
find . -maxdepth 1 -name "out2-*.pcap" | xargs mergecap -a -w out.pcap -F pcap 
find . -maxdepth 1 -name "out2-*.pcap" | xargs rm -f

