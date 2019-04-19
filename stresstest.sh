stress --cpu 4 --io 4 --vm 2 --vm-bytes 256M --hdd 4 --timeout 240s
sudo stress-ng --cpu 4 --io 4 --vm 1 --vm-bytes 512M --hdd 2 --hdd-ops 100000 --timeout 240s --metrics-brief
sudo stress-ng --io 8 --vm 1 --vm-bytes 512M --hdd 2 --hdd-ops 100000 --timeout 240s --metrics-brief

CPU, Disk Used, Total Used, Read/Write Bytes
sudo stress-ng --hdd 6 --hdd-ops 1000000 --timeout 240s --metrics-brief

sudo stress-ng --vm 1 --vm-bytes 512M --timeout 240s --metrics-brief
