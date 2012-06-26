#!/bin/bash

# Checks whether a drive on my NAS is spinning or not.

devices=(ada0 ada1 ada2);

while [ 1 ]
do

    for device in "${devices[@]}"
    do
        CM=$(camcontrol cmd $device -a "E5 00 00 00 00 00 00 00 00 00 00 00" -r - | awk '{print $10}')
    if [ "$CM" = "FF" ] ; then
        echo "$device: SPINNING"
    elif [ "$CM" = "00" ] ; then
        echo "$device: IDLE"
    else
        echo "$device: UNKNOWN"
    fi
    done

sleep 60
done
