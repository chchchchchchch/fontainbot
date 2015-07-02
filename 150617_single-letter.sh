#!/bin/bash

# --------------------------------------------------------------------------- #
# GENERAL ...
# --------------------------------------------------------------------------- #
  source lib/sh/twitter.functions
  source lib/sh/headless.functions

  TMPDIR=.
  HTML=$TMPDIR/tmp.html
  FF=fontforge
  BRK=$RANDOM
  TMPTTF=$TMPDIR/tmp.ttf
  TMPSVG=$TMPDIR/tmp.svg
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
      FONTSRC=`echo $FONTINFO | sed "s/$BRK/\n/g" | #
               grep "glyphs:" | cut -d ":" -f 2   | #
               sed 's/ //g'`                        #
     FONTSPEC=`echo $FONTINFO | sed "s/$BRK/\n/g" | #
               grep "Font:"   | cut -d ":" -f 2   | #
               sed 's/ //g'   | sed 's/-/ /g'`      #
   FONTFAMILY=`echo $FONTINFO | sed "s/$BRK/\n/g" | # DISPLAY + RESTORE BREAKS
               grep "family:" | cut -d ":" -f 2   | # FIND + CUT FIELD
               sed 's/^[ \t]*//'`                   # REMOVE LEADING BLANKS
    FONTSTYLE=`echo $FONTINFO | sed "s/$BRK/\n/g" | #
               grep "style:"  | cut -d ":" -f 2`    #
   FONTWEIGHT=`echo $FONTINFO | sed "s/$BRK/\n/g" | #
               grep "weight:" | cut -d ":" -f 2`    #
  FONTSTRETCH=`echo $FONTINFO | sed "s/$BRK/\n/g" | #
               grep "stretch:"| cut -d ":" -f 2`    #

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
  IDBASE=`echo $FONTSPEC | md5sum | cut -c 1-4``echo $0 | md5sum | cut -c 1-4`
  CNT=1
  function selectCharacter(){
    CHARACTER=`cat $NAMLIST            | # ALL AVAILABLE
               grep -v 0020            | # NO SPACE
               grep "x[0-9][0-9][0-9]" | # CERTAIN RANGE ONLY
               shuf -n 1`                # RANDOM ONE
    NAME=${IDBASE}`echo $CHARACTER | md5sum | cut -c 1-4`
  }

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
  CHARINFO=`echo $CHARACTER               | #
            recode u2/x2..dump-with-names | # 
            tail -n 1                     | #
            tr -s ' '                     | #
            cut -d " " -f 3-`
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
          MESSAGE=`echo ${M2}${BRK}${M3}${BRK}${M4}${BRK}${M5} | #
                   sed "s/$BRK/\n/g"                           | #
                   awk '{ print length($0) " " $0; }'          | #
                   sort -r -n                                  | #
                   cut -d ' ' -f 2-                            | #
                   head -n $CNT | tail -n 1`                     # SELECT NEXT
          MCHK=`echo $MESSAGE                       | #
                sed -e "s,http.\?://.* ,$URLFOO ,g" | #
                wc -c`
          CNT=`expr $CNT + 1`
          echo $MESSAGE
          echo $MCHK
  done

# --------------------------------------------------------------------------- #
# UPLOAD
# --------------------------------------------------------------------------- #

  tweet $MESSAGE ${FREEZE}.png


# --------------------------------------------------------------------------- #
# CLEAN UP
# --------------------------------------------------------------------------- #
  rm $TMPDIR/tmp.*


exit 0;

