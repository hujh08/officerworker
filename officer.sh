#!/bin/bash

# accept multiply tasks from STDIN
# and re-send them one by one to workers

# setup for message queue
msgp=`absname $0`

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
        *) echo "unknown option: $1"; exit 1;;
    esac
done

if [ ! -f $msgp ]
then
    echo "file for msgQ '$msgp': not exist" >&2
    exit 1
fi

brcv=0  # msg queue id used to recieve message
bsnd=-1  # msg queue id used to send message
((widst=1))  # start id for worker

#number of worker
numw=0

msgworker=(`mrcvFrom --nowait -p $msgp $brcv`)
while [ x"${msgworker[0]}" == x"check-in" ]
do
    ((numw++))
    msgworker=(`mrcvFrom --nowait -p $msgp $brcv`)
done

if((numw==0))
then
    echo "no worker checks in."
    echo "waiting"
else
    echo "$numw workers checked in by until now."
fi

# give unique id to worker
for((i=0; i<$numw; i++))
do
    # msgQ id for worker to connect
    ((wid=$i+$widst))
    msendTo -p $msgp -- $bsnd $wid
done

# allocate task
totTask=0
echo
while read line
do
    # line: linetype taskname taskcode
    fields=($line)
    linetype=${fields[0]}
    if [ x"$linetype" != xtask ] || ((${#fields[*]}<3))
    then
        echo -e "${RED}unknown input: [$line]${NONE}"
        continue
    fi
    taskname=${fields[1]}

    taskStr="task $totTask $taskname"
    taskecho="appoint $taskStr to "
    tasklen=${#taskecho}
    echo -n "$taskecho"
    msgworker=(`mrcvFrom -p $msgp $brcv`)
    while [ x"${msgworker[0]}" != x"woker" ]
    do
        if [ x"${msgworker[0]}" == x"check-in" ]
        then
            ((wid=$numw+$widst))
            msendTo -p $msgp -- $bsnd $wid
            ((numw++))
            welcomstr="    worker $wid joins. now $numw workers"
            echo -ne "\r${GREEN}$welcomstr${NONE}"

            welclen=${#welcomstr}
            ((dlen=tasklen-welclen))
            for i in $(seq $dlen); do echo -n " "; done
            #perl -e "print ' 'x$dlen"
            echo
            echo -n "$taskecho"
        fi
        msgworker=(`mrcvFrom -p $msgp $brcv`)
    done

    wid=${msgworker[1]}
    echo "worker $wid"

    taskcode=${fields[*]:2}
    msendTo -p $msgp $wid "$taskStr $taskcode"
    ((totTask++))
done

# exit signal
echo
numwNow=$numw
echo "number of worker now: $numwNow"
echo 'begin to exit all:'
while :
do
    if(($numwNow<=0))
    then
        break
    fi

    echo -n '    exit '
    msgworker=(`mrcvFrom -p $msgp $brcv`)
    if [ x"${msgworker[0]}" == x"woker" ]
    then
        wid=${msgworker[1]}

        echo -n "worker $wid. "
        msendTo -p $msgp $wid "exit"
        ((numwNow--))
        echo "$numwNow workers survive"
    fi
done

if((totTask==0))
then
    echo "no task was done"
    exit 1
fi

# count the number of tasks finished by each worker
echo
echo "Statistic of task:"
echo "$totTask tasks done in total"
for((i=0; i<$numw; i++))
do
    ((wid=$i+$widst))
    numtask=`mrcvFrom -p $msgp $wid`
    partf=`perl -e "printf '%.2f%%', 100.*$numtask/$totTask"`
    echo "    worker ${wid}: $numtask tasks, $partf"
done