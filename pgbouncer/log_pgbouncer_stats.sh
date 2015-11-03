#!/bin/bash

# take number of minutes as parameter; otherwise
# run for 1 hour
NUMMIN=${1:-60}
NUMMIN=$(($NUMMIN * 2 + 10))
CURMIN=0

# If you want to hard-code these, uncomment them.
# Otherwise just set these variables in your
# shell before running this command, using the
# same three lines listed below.
#
# If you need to set a password, use ~/.pgpass:
# http://www.postgresql.org/docs/9.3/static/libpq-pgpass.html

#export PGUSER=pgbouncer
#export PGDATABASE=pgbouncer
#export PGPORT=6542

PSFILE="ps-scratch.txt"
STOPFILE="./stopfile"
clean_up_and_exit() {
    echo 'Caught interrupt; exiting'
    rm $PSFILE
    rm -f "$STOPFILE"
    exit $?
}
trap "echo 'Caught interrupt; exiting'; clean_up_and_exit" SIGINT


log_resource_usage() {
    ps -eo pid,pcpu,pmem,rss,vsz,args > $PSFILE
    grep '/usr/lib/postgresql/9.3/bin/postgres -D' $PSFILE | adddate >> ps.log
    grep '/usr/sbin/pgbouncer' $PSFILE | adddate >> ps.log
}

adddate() {
    DTSTAMP=$(date +"%Y-%m-%d %H:%M:%S %z")
    while IFS= read -r line; do
        echo "$DTSTAMP $line"
    done
}

while [ $CURMIN -lt $NUMMIN  ]
do

    psql -q -A -t -F " " -c "show pools" | adddate >> pools.log
    psql -q -A -t -F " " -c "show stats" | adddate >> stats.log
    psql -q -A -t -F " " -c "show clients" | adddate >> clients.log

    log_resource_usage

    if [[ -e "$STOPFILE" ]]; then
        echo "Exiting; detected '$STOPFILE'"
        clean_up_and_exit
    else
        #cycle twice per minute
	sleep 30
	let CURMIN=CURMIN+1
    fi 
done

clean_up_and_exit
