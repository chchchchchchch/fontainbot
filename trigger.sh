#!/bin/bash

# RUSSIAN ROULETTE: PULL THE TRIGGER, SHOT NOT EVERY TIME #
# ------------------------------------------------------- #

 if [ `echo $RANDOM | rev | cut -c 1` -ge 3 ]; then

       PROJECTROOT=`readlink -f $0   | #
                    rev              | #
                    cut -d "/" -f 2- | #
                    rev`
       cd $PROJECTROOT
       SLEEPTIME=`expr \`echo $RANDOM | cut -c 1-3\` \/ 3`
       echo "powernap for $SLEEPTIME seconds"
     # sleep $SLEEPTIME
       TRIGGERTHIS=`ls ./*.sh     | #
                    grep -v "$0"  | #
                    shuf -n 1`      #
       echo $TRIGGERTHIS
     # $TRIGGERTHIS
       cd - > /dev/null 2>&1
 fi

exit 0;
