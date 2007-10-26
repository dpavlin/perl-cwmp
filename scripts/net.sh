
if [ -z "$1" ] ; then
	eth=eth0
#	eth=ath0:0
else
	eth=$1
fi

# new 192.168.1.240/28 network

sudo ifconfig $eth down
sudo ifconfig $eth 192.168.1.241 up
# backup network (thompson 10.0.0.138)
sudo ifconfig $eth:10 10.0.0.1 up
sudo route add -net 192.168.1.240/28 dev $eth
echo "Setup of $eth to 192.168.1.90 ready"
