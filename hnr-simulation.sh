#!/bin/bash

CPU=''
VM=''
VMBYTES=''
HDD=''
HDDOPS=''
TIMEOUT=''
CPU_VAL=''
VM_VAL=''
VMBYTES_VAL=''
TIMEOUT_VAL=''
HDD_VAL=''
HDDOPS_VAL=''
METRICS=''
AGENT_DISCONNECT=5m

for i in "$@"
do
case $i in
  --agent-disconnect=*)
  AGENT_DISCONNECT="${i#*=}"
  shift # past argument=value
  ;;
  --cpu=*)
  CPU=" --cpu "
  CPU_VAL="${i#*=}"
  shift # past argument=value
  ;;
  --hdd=*)
  HDD=" --hdd "
  HDD_VAL="${i#*=}"
  shift # past argument=value
  ;;
  --hdd-ops=*)
  HDDOPS=" --hdd-ops "
  HDDOPS_VAL="${i#*=}"
  shift # past argument=value
  ;;
  --metrics-brief)
  METRICS=" --metrics-brief "
  shift # past argument=value
  ;;
  --vm=*)
  VM=" --vm "
  VM_VAL="${i#*=}"
  shift # past argument=value
  ;;
  --vm-bytes=*)
  VMBYTES=" --vm-bytes "
  VMBYTES_VAL="${i#*=}"
  shift # past argument=value
  ;;
  --timeout=*)
  TIMEOUT=" --timeout "
  TIMEOUT_VAL="${i#*=}"
  shift # past argument=value
  ;;
esac
done
# sound-the-alarm --hdd=1 --hdd-ops=1000000 --vm=1 --vm-bytes=512M --timeout=240s --agent-disconnect=7s
echo ""
echo "stress-ng${CPU}${CPU_VAL}${HDD}${HDD_VAL}${HDDOPS}${HDDOPS_VAL}${VM}${VM_VAL}${VMBYTES}${VMBYTES_VAL} --timeout ${TIMEOUT_VAL} --metrics-brief"
if [ !  -z  $TIMEOUT_VAL ]; then
    echo -e "\e[1m\e[34mRunning alert stress test\e[0m\e[30m"
    echo ""
    stress-ng${CPU}${CPU_VAL}${HDD}${HDD_VAL}${HDDOPS}${HDDOPS_VAL}${VM}${VM_VAL}${VMBYTES}${VMBYTES_VAL}${TIMEOUT}${TIMEOUT_VAL}${METRICS}
    echo ""
    echo -e "\e[1m\e[92mStress completed\e[0m\e[30m"
else
    echo -e "\e[1m\e[92mStress test skipped - No timeout was provided\e[0m\e[30m"
fi
# # stress --cpu 8 --vm-bytes 1024M --timeout 240s
echo ""
echo -e "\e[1m\e[34mChecking Status of New Relic Infrastructure Agent\e[0m\e[30m"
sudo systemctl status newrelic-infra
echo ""
echo -e "\e[1m\e[31mStopping Agent\e[0m\e[30m"
sudo systemctl stop newrelic-infra
echo ""
echo -e "\e[1m\e[34mMaking sure New Relic Infrastructure Agent is stopped\e[0m\e[30m"
sudo systemctl status newrelic-infra
echo ""
echo -e "\e[1m\e[93mSleeping for ${AGENT_DISCONNECT} for HNR threshold to violate...\e[0m\e[30m"
sleep ${AGENT_DISCONNECT}
echo ""
echo -e "\e[1m\e[34mStarting New Relic Infrastructure Agent\e[0m\e[30m"
sudo systemctl start newrelic-infra
echo ""
echo -e "\e[1m\e[34mMaking sure New Relic Infrastructure Agent is running\e[0m\e[30m"
sudo systemctl status newrelic-infra
echo ""
echo -e "\e[1m\e[92mScript Complete\e[0m\e[30m"
