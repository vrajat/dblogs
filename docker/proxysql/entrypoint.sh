#!/bin/bash
set -e

## ProxySQL entrypoint
## ===================
##
## Supported environment variable:
##
## MONITOR_CONFIG_CHANGE={true|false}
## - Monitor /etc/proxysql.cnf for any changes and reload ProxySQL automatically

# If command has arguments, prepend proxysql

CONFIG=/etc/proxysql/proxysql.cnf
if [ "${1:0:1}" = '-' ]; then
	CMDARG="$@"
fi

if [ $MONITOR_CONFIG_CHANGE ]; then

	echo 'Env MONITOR_CONFIG_CHANGE=true'
	oldcksum=$(cksum ${CONFIG})

	# Start ProxySQL in the background
	proxysql --reload -f $CMDARG &

	echo "Monitoring $CONFIG for changes.."
	inotifywait -e modify,move,create,delete -m --timefmt '%d/%m/%y %H:%M' --format '%T' ${CONFIG} | \
	while read date time; do
		newcksum=$(cksum ${CONFIG})
		if [ "$newcksum" != "$oldcksum" ]; then
			echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			echo "At ${time} on ${date}, ${CONFIG} update detected."
			echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			oldcksum=$newcksum
			echo "Reloading ProxySQL.."
		        killall -15 proxysql
			proxysql --initial --reload -f $CMDARG
		fi
	done
fi

# Start ProxySQL with PID 1
ls -l /etc/
ls -l /etc/proxysql/
ls -l /etc/proxysql/proxysql.cnf
cat /etc/proxysql.cnf
exec proxysql -f $CMDARG -c $CONFIG
