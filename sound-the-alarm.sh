#!/bin/bash

STRESS=''
AGENT_DISCONNECT=''

for i in "$@"
do
case $i in
  -d | --agent-disconnect=*)
  AGENT_DISCONNECT="${i#*=}"
  shift # past argument=value
  ;;
  -s | --stress-ng=*)
  STRESS="${i#*=}"
  shift # past argument=value
  ;;
esac
done
# sound-the-alarm --hdd=1 --hdd-ops=1000000 --vm=1 --vm-bytes=512M --timeout=240s --agent-disconnect=7s
echo ""
# echo "stress-ng${CPU}${CPU_VAL}${HDD}${HDD_VAL}${HDDOPS}${HDDOPS_VAL}${VM}${VM_VAL}${VMBYTES}${VMBYTES_VAL} --timeout ${TIMEOUT_VAL} --metrics-brief"
if [ !  -z  "$STRESS" ]; then
  echo -e "\e[1m\e[34mRunning alert stress test. You can skip it by pressing 'CTRL+C'!\e[0m\e[30m"
  echo ""
  stress-ng ${STRESS}
  echo ""
  echo -e "\e[1m\e[92mStress completed\e[0m\e[30m"
else
  echo -e "\e[1m\e[31mStress test skipped - No parameters provided\e[0m\e[30m"
  echo ""
fi
# # stress --cpu 8 --vm-bytes 1024M --timeout 240s
echo ""
if [ ! -z $AGENT_DISCONNECT ]; then
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
else
  echo -e "\e[1m\e[31mAgent Disconnect skipped - No parameters provided\e[0m\e[30m"
  echo ""
fi

echo -e "\e[1m\e[92mScript Complete\e[0m\e[30m"
