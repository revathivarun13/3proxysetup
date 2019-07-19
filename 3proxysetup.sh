#!/bin/bash

CONFIG_FILE="/etc/3proxy/conf/3proxy.cfg"

if [ "$#" -ne 2 ]
then
	echo "Run Script as"
	echo "sh $0 create 1024"
	echo "sh $0 delete 1024"
	exit 3
else
	echo ""
fi

PrintProxy()
{
	PORTLIST=`cat $CONFIG_FILE | grep ^proxy | awk '{print $2}' | cut -c3-`
	for I in $PORTLIST
	do
		echo "$PxyIP:$I:$Username:$Password"
	done
}

Restart3Proxy()
{
	service 3proxy restart
}

CreateProxy()
{
	CreateUser
	InitializeFile
	K=1
	PORT=3128
	while [ $K -le $1 ]
	do
		echo "proxy -p${PORT}" >> ${CONFIG_FILE}
		K=$((K+1))
		PORT=$((PORT+1))
	done
	CloseConfig
	sed -i '1inscache 65536\nnserver 8.8.8.8\nnserver 8.8.4.4\nconfig /conf/3proxy.cfg\nmonitor /conf/3proxy.cfg\nlog /logs/3proxy-%y%m%d.log D' ${CONFIG_FILE}
	Restart3Proxy
	PrintProxy
}

CreateUser()
{
	read -p "Enter Username: " Username
	read -p "Enter Password: " Password
	chmod +x /etc/3proxy/conf/add3proxyuser.sh
	/etc/3proxy/conf/add3proxyuser.sh $Username $Password
}
InitializeFile()
{
	echo 'nscache 65536' > ${CONFIG_FILE}
	echo 'nserver 8.8.8.8' >> ${CONFIG_FILE}
	echo 'nserver 8.8.4.4' >> ${CONFIG_FILE}

	echo 'config /conf/3proxy.cfg' >> ${CONFIG_FILE}
	echo 'monitor /conf/3proxy.cfg' >> ${CONFIG_FILE}

	echo 'log /logs/3proxy-%y%m%d.log D' >> ${CONFIG_FILE}
	echo 'rotate 60' > ${CONFIG_FILE}
	echo 'counter /count/3proxy.3cf' >> ${CONFIG_FILE}

	echo 'users $/conf/passwd' >> ${CONFIG_FILE}

	echo 'include /conf/counters' >> ${CONFIG_FILE}
	echo 'include /conf/bandlimiters' >> ${CONFIG_FILE}

	echo 'auth strong' >> ${CONFIG_FILE}
	echo 'deny * * 127.0.0.1' >> ${CONFIG_FILE}
	echo 'allow *' >> ${CONFIG_FILE}
}

CloseConfig()
{
	echo 'socks' >> ${CONFIG_FILE}
	echo 'flush' >> ${CONFIG_FILE}
	echo 'allow admin' >> ${CONFIG_FILE}
	echo >> ${CONFIG_FILE}
	echo 'admin -p8080' >> ${CONFIG_FILE}
}
DeleteProxy()
{
	> $CONFIG_FILE
	> /etc/3proxy/conf/passwd
	Restart3Proxy
}

read -p "Enter your Proxy IP address: " PxyIP
case "$1" in 
	create)
			CreateProxy "$2"
			;;
	delete)
			DeleteProxy
			;;
	print)
			PrintProxy
			;;
	*)
		echo "Wrong option selected"
		;;
esac
