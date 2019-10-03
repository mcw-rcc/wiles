#!/bin/bash
#
# health-check.sh - checks for nodes
#
# This script is called by Torque at job start, job end,
# and at some interval of the polling interval.
#
# If any check fails the node is offlined with a note.
#

unhealthy=0
note=""
expecteddimms=10
expecteddimms1=6
expecteddimms2=4
expectedsize1=16384
expectedsize2=8192
expectedspeed=2133

function check_status(){
    # $1 = expected value
    # $2 = status
    # $3 = message if different

    if [[ "$1" != "$2" ]] ; then
        unhealthy=1
	    if [[ -z $note ]] ; then
            note=$3
	    else
            note="$note; $3"
	    fi
    fi
}

# Check 1 - Memory
dimmcount=$(/usr/sbin/dmidecode -t 17 | /bin/grep 'Configured Clock.*MHz' | /usr/bin/wc | /bin/awk '{print $1}')
speedcount=$(/usr/sbin/dmidecode -t 17 | /bin/grep 'Configured Clock.*MHz' | /bin/grep $expectedspeed | /usr/bin/wc | /bin/awk '{print $1}')
sizecount1=$(/usr/sbin/dmidecode -t 17 | /bin/grep 'Size.*MB' | /bin/grep $expectedsize1 | /usr/bin/wc | /bin/awk '{print $1}')
sizecount2=$(/usr/sbin/dmidecode -t 17 | /bin/grep 'Size.*MB' | /bin/grep $expectedsize2 | /usr/bin/wc | /bin/awk '{print $1}')
if [ "$dimmcount" -ne "$expecteddimms" ]; then
    check_status 0 $? "Memory problems, not the expected DIMM count."
fi
if [ "$speedcount" -ne "$expecteddimms" ]; then
    check_status 0 $? "Memory problems, not the expected speed."
fi
if [ "$sizecount1" -ne "$expecteddimms1" ]; then
    check_status 0 $? "Memory problems, not the expected size."
fi
if [ "$sizecount2" -ne "$expecteddimms2" ]; then
    check_status 0 $? "Memory problems, not the expected size."
fi


# Check 2 - Check CPUs
cpu_count=$(/bin/grep processor /proc/cpuinfo | /usr/bin/wc -l)
check_status 20 $cpu_count "processor count off"

# Check 3 - Check automount
/etc/init.d/autofs status > /dev/null 2>&1
if [[ "$?" -ne 0 ]] ; then
    /etc/init.d/autofs restart > /dev/null 2>&1
    check_status 0 $? "automount not running"
fi

# Check 4 - Check ypbind
/etc/init.d/ypbind status > /dev/null 2>&1
if [[ "$?" -ne 0 ]] ; then
    /etc/init.d/ypbind restart > /dev/null 2>&1
    ypbind_status=$?
    check_status 0 $ypbind_status "ypbind not started"
    # if ypbind is bounced and is OK, need to restart autofs
    if [[ "$ypbind_status" -eq 0 ]] ; then
        /etc/init.d/autofs restart
    fi
fi

# Check 5 - Check if apps mounted
/bin/grep '/share/apps nfs rw' /etc/mtab >/dev/null 2>&1
check_status 0 $? "shared apps not mounted"

# Check 6 - Check local disk usage
percent_disk_used=$( /bin/df /local | /usr/bin/tail -n 1 | /bin/awk '{print $4}' | /usr/bin/tr -d '%' )
check_status 0 $(( $percent_disk_used > 90 )) "local disk full"

# Check 7 - test local scratch file system
if [ -d "/local" ] ; then
    test_file_name=$(/usr/bin/uuidgen)
    /bin/touch /local/.$test_file_name
    check_status 0 $? "/local file system problems"
    /bin/rm -f /local/.$test_file_name
fi

# Check 8 - test global scratch file system
if [ -d "/share/apps/scratch" ] ; then
    test_file_name=$(/usr/bin/uuidgen)
    /bin/touch /share/apps/scratch/.$test_file_name
    check_status 0 $? "Global scratch file system problems"
    /bin/rm -f /share/apps/scratch/.$test_file_name
fi

# Report if any checks fail
if [[ "$unhealthy" -ne 0 ]] ; then
    echo "ERROR $note"
    exit -1
fi

exit 0
