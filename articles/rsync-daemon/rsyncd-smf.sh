#!/usr/bin/bash
set -e

# /lib/svc/method/rsync: start and stop the RSYNC daemon

# Copyright 2008 Marcelo Leal, http://www.eall.com.br/blog/?p=111
# Modded for OpenSolaris rsync (SUNWrsync) (C) 2009 by Jim Klimov

SMF_EXIT_ERR_CONFIG=96
SMF_EXIT_OK=0
[ -f /lib/svc/share/smf_include.sh ] && . /lib/svc/share/smf_include.sh

DAEMON=/usr/bin/rsync
RSYNC_ENABLE=false
RSYNC_OPTS=''
RSYNC_DEFAULTS_FILE=/etc/default/rsync
RSYNC_CONFIG_FILE=/etc/rsyncd.conf
PIDFILE=/var/run/rsyncd.pid

if [ ! -x "$DAEMON" ]; then
    echo "rsync binary not found (as $DAEMON)"
    exit $SMF_EXIT_ERR_CONFIG
fi

if [ -s $RSYNC_DEFAULTS_FILE ]; then
    . $RSYNC_DEFAULTS_FILE
    case "x$RSYNC_ENABLE" in
        xtrue|xfalse)   ;;
        xinetd)         exit $SMF_EXIT_OK
                        ;;
        *)              echo "Value of RSYNC_ENABLE in $RSYNC_DEFAULTS_FILE must be either 'true' or 'false';"
                        echo "not starting rsync daemon."
                        exit $SMF_EXIT_ERR_CONFIG
                        ;;
    esac
fi

export PATH="${PATH:+$PATH:}/usr/local/bin:/usr/sbin:/sbin"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}/usr/local/lib:/usr/lib:/lib"

case "$1" in
  start)
	if "$RSYNC_ENABLE"; then
            echo -n "Starting rsync daemon: rsync"
	    if [ -s $PIDFILE ] && kill -0 $(cat $PIDFILE) >/dev/null 2>&1; then
	    	echo " apparently already running."
		exit $SMF_EXIT_OK
	    fi
            if [ ! -s "$RSYNC_CONFIG_FILE" ]; then
                echo " missing or empty config file $RSYNC_CONFIG_FILE"
                exit $SMF_EXIT_ERR_CONFIG
            fi
               $DAEMON --daemon --config="$RSYNC_CONFIG_FILE" $RSYNC_OPTS
            echo "."
        else
            if [ -s "$RSYNC_CONFIG_FILE" ]; then
                echo "rsync daemon not enabled in /etc/default/rsync"
	    else
		echo "rsync daemon not enabled in /etc/default/rsync and missing or empty config file $RSYNC_CONFIG_FILE"
            fi
	    exit $SMF_EXIT_ERR_CONFIG
        fi
	;;
  stop)
        if [ -s $PIDFILE ] && kill -0 $(cat $PIDFILE) >/dev/null 2>&1; then
         echo -n "Stopping rsync daemon: rsync"
         /usr/bin/kill -TERM `/usr/bin/cat $PIDFILE`
	 rm -f $PIDFILE 
         echo "."
        fi
	;;

  reload|force-reload)
        echo "Reloading rsync daemon: not needed, as the daemon"
        echo "re-reads the config file whenever a client connects."
	;;

  restart)
	# set +e
        if $RSYNC_ENABLE; then
            echo -n "Restarting rsync daemon: "
	    if [ -s $PIDFILE ] && kill -0 $(cat $PIDFILE) >/dev/null 2>&1; then
                /usr/bin/kill -TERM `/usr/bin/cat $PIDFILE`
	    	rm -f $PIDFILE
                echo -n "."
	    fi
            if [ ! -s "$RSYNC_CONFIG_FILE" ]; then
                echo " missing or empty config file $RSYNC_CONFIG_FILE"
                exit $SMF_EXIT_ERR_CONFIG
            fi
            sleep 5
            $DAEMON --daemon --config="$RSYNC_CONFIG_FILE" $RSYNC_OPTS
            if [ $? -ne 0 ]; then
	    	echo "start failed? $?"
		rm -f $PIDFILE 
	    else  
                echo "."
            fi
        else
            if [ -s "$RSYNC_CONFIG_FILE" ]; then
                echo "rsync daemon not enabled in /etc/default/rsync"
	    else
		echo "rsync daemon not enabled in /etc/default/rsync and missing or empty config file $RSYNC_CONFIG_FILE"
            fi
	    exit $SMF_EXIT_ERR_CONFIG
        fi
	;;

  *)
	echo "Usage: /etc/init.d/rsync {start|stop|reload|force-reload|restart}"
	exit $SMF_EXIT_ERR_CONFIG
esac

exit $SMF_EXIT_OK


