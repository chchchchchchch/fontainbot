#!/bin/bash

# RUSSIAN ROULETTE: PULL THE TRIGGER, SHOT NOT EVERY TIME    #
# ---------------------------------------------------------- #
  SELF=`basename $0`

  if [ `ps a         | # LIST PROCESSES
        grep $SELF   | # LOOK FOR YOURSELF
        grep -v grep | # IGNORE THIS SEARCH
        wc -l` -ge 3 ]; then
        sleep 0
      # echo "STATUS: $SELF running -> exiting"
      # echo "TIME:   "`date "+%d.%m.%Y %T"`
  else
  if [ `echo $RANDOM | rev | cut -c 1` -ge 3 ]; then
        PROJECTROOT=`readlink -f $0   | # ABSOLUTE PATH
                     rev              | # REVERT
                     cut -d "/" -f 2- | # REMOVE FIRST FIELD
                     rev`               # REVERT
        cd $PROJECTROOT
        SLEEPTIME=`expr $((RANDOM%900+100)) \/ $((RANDOM%9+1))`
        echo "DELAY:  ${SLEEPTIME}s"
        sleep $SLEEPTIME
        echo "TIME:   "`date "+%d.%m.%Y %T"`

        TRIGGERTHIS=`ls ./1*.sh    | # LIST ALL SCRIPTS
                     grep -v $SELF | # IGNORE YOURSELF
                     shuf -n 1`      # SELECT ONE RANDOM
        echo "SCRIPT: "`basename $TRIGGERTHIS`
        $TRIGGERTHIS
        cd - > /dev/null 2>&1
        echo
  fi
  fi

exit 0;
