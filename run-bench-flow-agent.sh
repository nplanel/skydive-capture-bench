#!/bin/bash


captureType=afpacket
replayPackets=681771
replayPPS="-p 95000"

export GOMAXPROCS=1
export SKYDIVE_ANALYZERS=127.0.0.1:8082

taskset 01 sudo $(which skydive) allinone &
skydivepid=$!

sudo ip link add dev vmhost1 type veth peer name innervm1
sudo ip link set dev vmhost1 arp off
sudo ip link set dev vmhost1 multicast off
sudo ip link set dev vmhost1 up
sudo ip link set dev innervm1 arp off
sudo ip link set dev innervm1 multicast off
sudo ip link set dev innervm1 up

sleep 5
skydive client capture list
captureUUID=$(skydive client capture create --gremlin 'g.V().Has("Name","innervm1","Type","veth")' --type $captureType | jq '.UUID' | tr -d '"')

# sudo tcpdump -nn -U -K   -i innervm1 -w /dev/null
sleep 2

taskset 04 sudo tcpreplay --unique-ip --unique-ip-loops=1 -l 20000 $replayPPS -K -i vmhost1 ip.pcap


sleep 5
skydive client query 'g.V().Flows()' > flows.json
capturePackets=$(grep Packets\" flows.json | awk -F ':' '{ sub(",","",$2); c=c+$2 } END {print c}')
captureFlows=$(grep ABPackets flows.json | wc -l)

skydive client capture delete $captureUUID
sudo ip link del dev vmhost1
sudo killall skydive


set +x
sleep 0.5
echo
echo "captureType,replayPackets,replayPPS,capturePackets,captureFlows"
echo "$captureType,$replayPackets,$replayPPS,$capturePackets,$captureFlows"
