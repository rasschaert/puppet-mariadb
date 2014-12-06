#!/bin/bash
# Description: Show the status or seqno of Galera.
# If the "status" option is passed, just give a short keyword indicating the
# status of Galera on this node, then exit Possible keywords:
# - stopped:       not running
# - duplicate:     the initiator script has been found to be running twice or more
# - initiating:    stopped, but initiator script is currently running
# - starting:      signs of starting up
# - started:       running, member of a cluster
# - bootstrapping: in progress of bootstrapping a new cluster
PATH=/usr/sbin:/usr/bin:/sbin:/bin
if [[ "$1" == "status" ]]; then
    # Can any instances of the galera-initiator.py script be found? 1 instance means initiating, 2 or more mean duplicates
    START_SCRIPT_COUNT=$(ps -ef 2>&1 | egrep 'python.+galera-initiator.py' | grep -vc grep)
    # print the code and get out before performing any further checks
    if [[ $START_SCRIPT_COUNT -gt 1 ]]; then
        echo "duplicate"
        exit
    fi

    # Is bootstrapping currently in progress?
    NEW_CLUSTER_COUNT=$(ps -ef 2>&1 | egrep 'sh.+mysql start --wsrep-new-cluster' | grep -vc grep)
    if [[ $NEW_CLUSTER_COUNT -ge 1 ]]; then
        echo "bootstrapping"
        exit
    fi

    # Is the service running? Capture the message and the exit code.
    SERVICE_MESSAGE=$(timeout 1s /etc/init.d/mysql status 2>&1) && SERVICE_RUNNING=true || SERVICE_RUNNING=false
    # print the code and get out before performing any further checks
    if [[ "$SERVICE_RUNNING" == true ]]; then
        echo "started"
        exit
    fi

    # Finding a socket file without having a fully started service could mean it's still starting up.
    # The error message "running but PID file could not be found" could also indicate that it's still starting up.
    echo "$SERVICE_MESSAGE" | grep -q "running but PID file could not be found"
    # print the code and get out before performing any further checks.
    if [[ $? -eq 0 ]]; then
        echo "starting"
        exit
    fi

    # Is galera-initiator in the process list?
    if [[ $START_SCRIPT_COUNT -eq 1  ]]; then
        echo "initiating"
        exit
    fi

    echo "stopped"

elif [[ "$1" == "seqno" ]]; then
    # The grastate.dat file holds the seqno
    GRASTATE="/var/lib/mysql/grastate.dat".
    if [[ -f "$GRASTATE" ]]; then
        # Parse uuid and seqno.
        UUID=$(awk '/uuid/ {print $NF}' < "$GRASTATE")
        SEQNO=$(awk '/seqno/ {print $NF}' < "$GRASTATE")
        # Has this node crashed?
        if [[ "$UUID" ==  "00000000-0000-0000-0000-000000000000" || "$SEQNO" != "-1" ]]; then
            # Try to get a more meaningful seqno than -1.
            /etc/init.d/mysql status >/dev/null 2>&1
            # Don't start
            if [[ $? -ne 0 ]]; then
                set -o pipefail
                RECOVERED_SEQNO=$(/usr/bin/mysqld_safe --wsrep-recover | awk -F : '/Recovered position/ {print $NF}')
                if [[ $? -eq 0 ]]; then
                    SEQNO="$RECOVERED_SEQNO"
                fi
            fi
        fi
    else
        # If the grastate.dat file doesn't exist, this node didn't get anywhere yet.
        echo "-1"
    fi

else
    echo "run this script either with the 'status' or the 'seqno' option."
fi
