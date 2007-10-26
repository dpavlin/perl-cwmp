
if [ -z "$1" ] ; then
	eth=eth0
#	eth=ath0:0
else
	eth=$1
fi

sudo ifconfig $eth 192.168.1.90 up
sudo route add -host 192.168.1.254 dev $eth
echo "Setup of $eth to 192.168.1.90 ready"
