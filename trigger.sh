#!/bin/bash

# RUSSIAN ROULETTE: PULL THE TRIGGER, SHOT NOT EVERY TIME    #
# ---------------------------------------------------------- #

 if [ `echo $RANDOM | rev | cut -c 1` -ge 3 ]; then

       PROJECTROOT=`readlink -f $0   | # ABSOLUTE PATH
                    rev              | # REVERT
                    cut -d "/" -f 2- | # REMOVE FIRST FIELD
                    rev`               # REVERT
       cd $PROJECTROOT
       SLEEPTIME=`expr \`echo $RANDOM | # DISPLAY RANDOM NUM
                  cut -c 1-3\` \/ 3`    # 3 DIGITS, DIVIDE
       TIME=`date "+%d.%m.%Y %T"`
       echo "It's $TIME. Powernap for $SLEEPTIME seconds"
       sleep $SLEEPTIME
       SELF=`basename $0`
       TRIGGERTHIS=`ls ./*.sh     | # LIST ALL SCRIPTS
                    grep -v $SELF | # IGNORE YOURSELF
                    shuf -n 1`      # SELECT ONE RANDOM
       echo $TRIGGERTHIS
       $TRIGGERTHIS
       cd - > /dev/null 2>&1
       echo
 fi

exit 0;
