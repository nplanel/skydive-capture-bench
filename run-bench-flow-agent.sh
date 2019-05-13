#!/bin/bash


captureType=ebpf
replayPackets=5600000
replayPPS="-p 20000"

export GOMAXPROCS=1
export SKYDIVE_ANALYZERS=127.0.0.1:8082

taskset 01 sudo $(which skydive) allinone &
skydivepid=$!

sudo ip link add dev vmhost1 type veth peer name innervm1
sudo ip link set dev vmhost1 arp off
sudo ip link set dev vmhost1 multicast off
sudo ethtool -K vmhost1 tso off
sudo ethtool -K vmhost1 gso off
sudo ethtool -K vmhost1 gro off
sudo ethtool -K vmhost1 lro off
sudo ip link set dev vmhost1 up
sudo ip link set dev innervm1 arp off
sudo ip link set dev innervm1 multicast off
sudo ethtool -K innervm1 tso off
sudo ethtool -K innervm1 gso off
sudo ethtool -K innervm1 gro off
sudo ethtool -K innervm1 lro off
sudo ip link set dev innervm1 up

sleep 5
skydive client capture list
captureUUID=$(skydive client capture create --gremlin 'g.V().Has("Name","innervm1","Type","veth")' --type $captureType | jq '.UUID' | tr -d '"')

# sudo tcpdump -nn -U -K   -i innervm1 -w /dev/null
sleep 2

sudo tcpdump -l -n -i innervm1 "not ip" &
echo $!
sleep 0.5

taskset 04 sudo tcpreplay -L 5600000 $replayPPS -i vmhost1 out.pcap
#taskset 04 sudo tcpreplay --unique-ip --unique-ip-loops=1 -l 20000 $replayPPS -K -i vmhost1 ip.pcap


sleep 10
skydive client query 'g.V().Flows()' > flows.json
capturePackets=$((jq '.[].Metric.ABPackets' flows.json; jq '.[].Metric.BAPackets' flows.json) | awk '{ c=c+$1 } END {print c}')
captureFlows=$(grep LayersPath flows.json | wc -l)
captureFlowsTCP=$(grep -e "LayersPath.*IPv4/TCP" flows.json | wc -l)
captureFlowsUDP=$(grep -e "LayersPath.*IPv4/UDP" flows.json | wc -l)

skydive client capture delete $captureUUID
sudo ip link del dev vmhost1
sudo killall skydive


set +x
sleep 0.5
echo
echo "captureType,replayPackets,replayPPS,capturePackets,captureFlows,captureFlowsTCP,captureFlowsUDP"
echo "$captureType,$replayPackets,$replayPPS,$capturePackets,$captureFlows,$captureFlowsTCP,$captureFlowsUDP"
