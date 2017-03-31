#!/bin/bash

msgp=$(dirname $(absname $0))/officer.sh

TEMP=`getopt -o p:\
             --long "path:"\
             -n $0 -- "$@"`
[ $? != 0 ] && exit 1
eval set -- "$TEMP"

while :
do
    case $1 in
        -p|--path) msgp=$2; shift 2;;
        --) shift; break;;
        *) echo "unknown option: $1" >&2; exit 1;;
    esac
done

if [ ! -f $msgp ]
then
    echo "file for msgQ '$msgp': not exist" >&2
    exit 1
fi

brcv=0  # msg queue id used to recieve message
bsnd=-1 # msg queue id used to send message

msendTo -p $msgp $brcv "check-in"

echo 'waiting to check in'
wid=`mrcvFrom -p $msgp -- $bsnd`

echo "yes Sir. I'm woker $wid"

numtask=0
# work now
echo
while :
do
    msendTo -p $msgp $brcv "woker $wid ready"

    # accept task
    taskmsg=(`mrcvFrom -p $msgp $wid`)

    if [ x"${taskmsg[0]}" == x"task" ]
    then
        taskid=${taskmsg[1]}
        taskname=${taskmsg[2]}
        taskcode=${taskmsg[*]:3}
    elif [ x"${taskmsg[0]}" == x"exit" ]
    then
        break
    else
        echo "unkown message: ${taskmsg[*]}"
        continue
    fi

    echo '--------------------------------'
    echo "task $taskid accepted: $taskname"
    eval $taskcode
    #$taskcode

    echo "task $taskid finish"
    ((numtask++))
done
echo '--------------------------------'

echo
echo "Wow! job's gone"
echo "number of tasks done: $numtask"

# send number of finished task
msendTo -p $msgp $wid "$numtask"