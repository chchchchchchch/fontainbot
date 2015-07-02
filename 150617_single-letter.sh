#!/bin/bash


#. 150617_single-letter.sh generates an image of a letter                     #
#. and posts it to a twitter account                                          #

#.---------------------------------------------------------------------------.#
#. Copyright (C) 2015 LAFKON/Christoph Haag                                   #
#.                                                                            #
#. 150617_single-letter.sh is free software: you can redistribute it and/or   #
#. modify it under the terms of the GNU General Public License as published   #
#. by the Free Software Foundation, either version 3 of the License, or       #
#. (at your option) any later version.                                        #
#.                                                                            #
#. 150617_single-letter.sh is distributed in the hope that it will be useful, #
#. but WITHOUT ANY WARRANTY; without even the implied warranty of             #
#. MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                       #
#. See the GNU General Public License for more details.                       #
#.                                                                            #
#.---------------------------------------------------------------------------.

# --------------------------------------------------------------------------- #
# GENERAL ...
# --------------------------------------------------------------------------- #
  source lib/sh/twitter.functions
  source lib/sh/headless.functions

  TMPDIR=.
  TMPID=$RANDOM
  HTML=$TMPDIR/$TMPID.html
  FF=fontforge
  BRK=$RANDOM
  TMPTTF=$TMPDIR/$TMPID.ttf
  TMPSVG=$TMPDIR/$TMPID.svg
  ISFS="-inkscape-font-specification"
  URLFOO=XXXXXXXXXXXXXXXXXXXXXX

# --------------------------------------------------------------------------- #
# SELECT A FONT
# --------------------------------------------------------------------------- #
     FONTINFO=`identify -list font           | # LIST ALL FONTS
               sed ":a;N;\\$!ba;s/\n/$BRK/g" | # REMOVE ALL LINEBREAKS
               sed 's/Font:/\n&/g'           | # PUT ON SEPARATE LINES
               grep ".fonts/fontain"         | # SELECT FONTAIN FONTS
               shuf -n 1`                      # SELECT RANDOM LINE

# --------------------------------------------------------------------------- #
# COLLECT FONT DATA 
# --------------------------------------------------------------------------- #
      FONTSRC=`echo $FONTINFO | sed "s/$BRK/\n/g" | # DISPLAY INFO / REBREAK
               grep "glyphs:" | cut -d ":" -f 2   | # SELECT SRC PATH
               sed 's/ //g'`                        # REMOVE SPACES
     FONTSPEC=`echo $FONTINFO | sed "s/$BRK/\n/g" | # DISPLAY INFO / REBREAK
               grep "Font:"   | cut -d ":" -f 2   | # SELECT SPEC FIELD
               sed 's/ //g'   | sed 's/-/ /g'`      # FORMATTING
   FONTFAMILY=`echo $FONTINFO | sed "s/$BRK/\n/g" | # DISPLAY + RESTORE BREAKS
               grep "family:" | cut -d ":" -f 2   | # SELECT FAMILY FIELD
               sed 's/^[ \t]*//'`                   # REMOVE LEADING BLANKS
    FONTSTYLE=`echo $FONTINFO | sed "s/$BRK/\n/g" | # DISPLAY INFO / REBREAK
               grep "style:"  | cut -d ":" -f 2`    # SELECT STYLE FIELD
   FONTWEIGHT=`echo $FONTINFO | sed "s/$BRK/\n/g" | # DISPLAY INFO / REBREAK
               grep "weight:" | cut -d ":" -f 2`    # SELECT WEIGHT FIELD
  FONTSTRETCH=`echo $FONTINFO | sed "s/$BRK/\n/g" | # DISPLAY INFO / REBREAK
               grep "stretch:"| cut -d ":" -f 2`    # SELECT STRETCH FIELD

   SVGFONTDEF=`echo "font-weight:$FONTWEIGHT;font-stretch:$FONTSTRETCH;\
                     font-style:$FONTSTYLE;" | #
               sed "s/ //g" | tr [:upper:] [:lower:]`$ISFS:$FONTSPEC 

# --------------------------------------------------------------------------- #
# CONVERT WHATEVER TO TTF (TMP)
# --------------------------------------------------------------------------- #
  python -c "import $FF;$FF.open(\"$FONTSRC\").generate(\"$TMPTTF\")" \
  > /dev/null 2>&1

# --------------------------------------------------------------------------- #
# MAKE A LIST OF AVAILABLE CHARACTERS
# --------------------------------------------------------------------------- #
  NAMLIST=$TMPDIR/tmp.nam
  python -c "import $FF;$FF.open(\"$FONTSRC\").saveNamelist(\"$NAMLIST\")" \
  > /dev/null 2>&1
  
# --------------------------------------------------------------------------- #
# SELECT A CHARACTER (IF EXPORT EXISTS, TRY AGAIN)
# --------------------------------------------------------------------------- #
  IDBASE=`echo $FONTSPEC | # DISPLAY FONT SPECIFICATION
          md5sum         | # MAKE MD5SUM
          cut -c 1-4``basename $0     | # DISPLAY BASENAME OF SCRIPT
                      cut -d "_" -f 2 | # SELECT TYPE NOT DATE
                      cut -d "." -f 1 | # REMOVE EXTENSION
                      md5sum          | # MAKE MD5SUM
                      cut -c 1-4`       # CUT 1 CHARACTERS
  CNT=1
  function selectCharacter(){
    CHARACTER=`cat $NAMLIST            | # ALL AVAILABLE
               grep -v 0020            | # NO SPACE
               grep "x[0-9][0-9][0-9]" | # CERTAIN RANGE ONLY
               shuf -n 1`                # RANDOM ONE
    NAME=${IDBASE}`echo $CHARACTER | md5sum | cut -c 1-4`
  }

# MAKE SURE CHARACTER HAS NOT BEEN USED
# --------------------------------------------------------------------------- #
  while [ `ls FREEZE/${NAME}.* 2>/dev/null | wc -l` -gt 0 ] &&
        [ $CNT -le 10 ]
   do
      selectCharacter
      CNT=`expr $CNT + 1`; if [ $CNT -eq 10 ]; then exit 0; fi
  done


# --------------------------------------------------------------------------- #
# WRITE HTML
# --------------------------------------------------------------------------- #
  echo "<html><head><style>"                                         >  $HTML
  echo "body { background-color:#DDDDDD;"                            >> $HTML
  echo "margin: 0px 0px 0px 0px;"                                    >> $HTML
  echo "border-left:  2px solid #000000;"                            >> $HTML
  echo "border-right: 2px solid #000000;}"                           >> $HTML
  echo "@font-face  { font-family:'thefont';"                        >> $HTML
  echo "src:url('$TMPTTF')format('truetype');"                       >> $HTML
  echo "}table{width:100%;height:100%;"                              >> $HTML
  echo "font-family:'thefont';font-size:180px;}"                     >> $HTML
  echo "table.letter{height:0px;}"                                   >> $HTML
  echo "</style></head><body><table><tr>"                            >> $HTML
  echo "<td valign=\"middle\">"                                      >> $HTML
  echo "<table class=\"letter\"><tr>"                                >> $HTML
  echo "<td align=\"center\">"                                       >> $HTML
  echo $CHARACTER | recode u2/x2..h0                                 >> $HTML
  echo "</td></tr></table>"                                          >> $HTML
  echo "</td></tr></table></body></html>"                            >> $HTML

# --------------------------------------------------------------------------- #
# MAKE IMAGE
# --------------------------------------------------------------------------- #
  FREEZE=FREEZE/${NAME}
  W=1024 ; H=512

  cutycapt --url=file:`readlink -f $HTML` \
           --min-width=$W \
           --min-height=$H \
           --out=$TMPSVG 2> /dev/null
  inkscape --export-plain-svg=tmp.2.svg \
           $TMPSVG  > /dev/null 2>&1
  mv tmp.2.svg $TMPSVG

  sed -i "s/width=\"[^\"]*\"/width=\"$W\"/g"   $TMPSVG
  sed -i "s/height=\"[^\"]*\"/height=\"$H\"/g" $TMPSVG
  sed -i "s/font-family:/${SVGFONTDEF};&/g"    $TMPSVG

  inkscape --export-png=${FREEZE}.png \
           $TMPSVG  > /dev/null 2>&1

# --------------------------------------------------------------------------- #
# COMPOSE MESSAGE
# --------------------------------------------------------------------------- #
  UTFCHAR=`echo $CHARACTER | recode u2/x2..utf-8`
  CHARINFO=`echo $CHARACTER               | # SHOW CHARACTER
            recode u2/x2..dump-with-names | # GET INFO VIA RECODE
            tail -n 1                     | # SELECT LAST LINE
            tr -s ' '                     | # SQUEEZE CONSECUTIVE SPACES
            cut -d " " -f 3-`               # SELECT 3-X FIELD
  INFOPLUS=`grep  "${FONTFAMILY}:" README.txt`
      ATTW=`echo $INFOPLUS | cut -d ":" -f 2`
      if [ `echo $ATTW | wc -c` -gt 1 ]; then
            ATTW="#librefont $FONTSPEC by $ATTW"; fi
     FHREF="→ http://fontain.org"`echo $INFOPLUS | cut -d ":" -f 3`

  M1="$UTFCHAR ( $CHARINFO ) →  $ATTW $FHREF"
  M2="$UTFCHAR →  $ATTW $FHREF"
  M3="$UTFCHAR ( $CHARINFO ) $FHREF"
  M4="${FHREF}"
  M5="$ATTW"
  MESSAGE=$M1
  MCHK=`echo $MESSAGE                       | #
        sed -e "s,http.\?://.* ,$URLFOO ,g" | #
        wc -c`
  CNT=1
  while [ $MCHK -gt 116 ]; do
    MESSAGE=`echo ${M2}${BRK}${M3}${BRK}${M4}${BRK}${M5} | # DISPLAY ALL
             sed "s/$BRK/\n/g"                           | # REBREAK
             awk '{ print length($0) " " $0; }'          | # SHOW LINE LENGTH
             sort -r -n                                  | # SORT ACCORDING TO LENGTH
             cut -d ' ' -f 2-                            | # REMOVE LINE INFO
             head -n $CNT | tail -n 1`                     # SELECT NEXT
    MCHK=`echo $MESSAGE                                  | # DISPLAY MESSAGE
          sed -e "s,http.\?://.* ,$URLFOO ,g"            | # REPLACE URL WITH FOO 
          wc -c`                                           # COUNT CHARACTERS
    CNT=`expr $CNT + 1`
  done
        echo $MESSAGE
        # echo $MCHK

# --------------------------------------------------------------------------- #
# UPLOAD
# --------------------------------------------------------------------------- #

  tweet $MESSAGE ${FREEZE}.png


# --------------------------------------------------------------------------- #
# CLEAN UP
# --------------------------------------------------------------------------- #
  rm $TMPDIR/$TMPID.*


exit 0;

