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
                  rev                 | # FROM BACK
                  cut -c 1-4\` \/ 20`   # 4 DIGITS, DIVIDE

       echo "Powernap for $SLEEPTIME seconds."
       sleep $SLEEPTIME
       TIME=`date "+%d.%m.%Y %T"`
       echo $TIME
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
