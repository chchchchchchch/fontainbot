#!/bin/bash

# RUSSIAN ROULETTE: PULL THE TRIGGER, SHOT NOT EVERY TIME #
# ------------------------------------------------------- #

 if [ `echo $RANDOM | rev | cut -c 1` -ge 3 ]; then

       SLEEPTIME=`expr \`echo $RANDOM | cut -c 1-3\` \/ 2`
       echo "powernap for $SLEEPTIME seconds"
       sleep $SLEEPTIME
       TRIGGERTHIS=`ls ./*.sh     | #
                    grep -v "$0"  | #
                    shuf -n 1`      #
       $TRIGGERTHIS
 fi

exit 0;
