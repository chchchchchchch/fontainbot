#!/bin/bash


#. 150704_single-letter.sh generates an image of a letter                     #
#. and posts it to a twitter account (COLOR VERSION)                          #

#.---------------------------------------------------------------------------.#
#. Copyright (C) 2015 LAFKON/Christoph Haag                                   #
#.                                                                            #
#. 150704_single-letter.sh is free software: you can redistribute it and/or   #
#. modify it under the terms of the GNU General Public License as published   #
#. by the Free Software Foundation, either version 3 of the License, or       #
#. (at your option) any later version.                                        #
#.                                                                            #
#. 150704_single-letter.sh is distributed in the hope that it will be useful, #
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
  FF=fontforge
  COLORS="EEEEEE|0ECCAA|888888|111111|DDDDDD"
  WORDS="lib/words/*/*.txt"
  BRK=$RANDOM
  TMPID=TMP$RANDOM
  HTML=$TMPDIR/$TMPID.html
  TMPTTF=$TMPDIR/$TMPID.ttf
  TMPSVG=$TMPDIR/$TMPID.svg
  ISFS="-inkscape-font-specification"
  ZW=`echo "&#8203;" | recode h0..utf-8`
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
  NAMLIST=$TMPDIR/$TMPID.nam
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

  function selectCharacter(){
  # CHARACTER=`cat $NAMLIST            | # ALL AVAILABLE
  #            grep -v 0020            | # IGNORE SPACE
  #            shuf -n 1`                # RANDOM ONE
    CHARACTER=`cat $NAMLIST            | # ALL AVAILABLE
               grep -v 0020            | # IGNORE SPACE
               shuf                    | # RANDOMIZE
               head -n $CNT            | # SHIFT THROUGH
               tail -n 1`                # SHIFT THROUGH
    NAME=${IDBASE}`echo $CHARACTER | md5sum | cut -c 1-4`
  }

# --------------------------------------------------------------------------- #
# MAKE SURE CHARACTER HAS NOT BEEN USED
# --------------------------------------------------------------------------- #
  CNT=1; while [ `ls FREEZE/${NAME}.* 2>/dev/null | wc -l` -gt 0 ] &&
               [ $CNT -le 1000 ]
   do
      selectCharacter
      CNT=`expr $CNT + 1`;
      if [ $CNT -eq 1000 ]; then
           echo "everthing used"
           exit 0;
      fi
  done

  echo "TRIED:  $((CNT - 1)) character(s)"

# --------------------------------------------------------------------------- #
# SELECT COLORS
# --------------------------------------------------------------------------- #
  C1=`echo $COLORS | sed 's/|/\n/g' | shuf -n 1`
  C2=`echo $COLORS | sed 's/|/\n/g' | grep -v $C1 | shuf -n 1`

# --------------------------------------------------------------------------- #
# WRITE HTML
# --------------------------------------------------------------------------- #
  echo "<html><head><style>"                                         >  $HTML
  echo "body { background-color:#$C1;"                               >> $HTML
  echo "margin: 0px 0px 0px 0px; }"                                  >> $HTML
  echo "@font-face  { font-family:'thefont';"                        >> $HTML
  echo "src:url('$TMPTTF')format('truetype');"                       >> $HTML
  echo "}table{width:100%;height:100%;"                              >> $HTML
  echo "font-family:'thefont';font-size:180px;"                      >> $HTML
  echo "color:#$C2;}"                                                >> $HTML
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
  UT8CHAR=`echo $CHARACTER     | # DISABLE CHARACTER
           recode u2/x2..utf-8`  # HEX TO UTF
  UTFCHAR=`echo $CHARACTER     | # DISABLE CHARACTER
           recode u2/x2..utf-8 | # HEX TO UTF
           sed "s/./&$ZW/g"`     # ADD ZERO WIDTH TO DISABLE TWITTER SHORTCUT
  CHARINFO=`echo $CHARACTER               | # SHOW CHARACTER
            recode u2/x2..dump-with-names | # GET INFO VIA RECODE
            tail -n 1                     | # SELECT LAST LINE
            tr -s ' '                     | # SQUEEZE CONSECUTIVE SPACES
            cut -d " " -f 3-              | # SELECT 3-X FIELD
            sed 's/(.*)//'`                 # REMOVE BETWEEN BRACKETS
  HASHINFO=`echo $CHARINFO | sed 's/^[ \t]*/#/' | sed 's/ / #/g'`
  HASHSPEC=`echo $FONTSPEC | sed 's/^[ \t]*/#/' | sed 's/ / #/g'`
  INFOPLUS=`grep  "${FONTFAMILY}:" README.txt`
    FHREF1="http://fontain.org"`echo $INFOPLUS | cut -d ":" -f 3`
     SHREF="http://"`echo $INFOPLUS | cut -d ":" -f 5`
    AUTHOR=`echo $INFOPLUS | cut -d ":" -f 4`
         A=`echo -e "→ \n[>]\n—\n|→ \n|\n//" | shuf -n 1`  

  WORD=`grep -h "^$UT8CHAR" $WORDS | # FIND WORD STARTING WITH CHARACTER
        sed -n '/^.\{4\}/p'        | # 4 OR LONGER
        sed '/^.\{12\}/d'          | # 12 OR SHORTER
        grep -v [0-9]              | # REMOVE IF THERE ARE NUMBERS
        grep -v [[:punct:]]        | # REMOVE IF THERE ARE NON LETTERS
        shuf -n 1`                   # SELECT RANDOM LINE

  if [ `echo $WORD | wc -c` -lt 1 ]; then
  WORD=`grep -h "$UT8CHAR" $WORDS | # FIND WORD CONTAINING CHARACTER
        sed -n '/^.\{4\}/p'       | # 4 OR LONGER
        sed '/^.\{12\}/d'         | # 12 OR SHORTER
        grep -v [0-9]             | # REMOVE IF THERE ARE NUMBERS
        grep -v [[:punct:]]       | # REMOVE IF THERE ARE NON LETTERS
        shuf -n 1`                  # SELECT RANDOM LINE
  else
   FHREF2="$FHREF1/#${WORD}"
   M4="${HASHSPEC} by $AUTHOR ($UTFCHAR)"
   M5="${UTFCHAR} like $WORD $A #librefont  $FONTSPEC"
   M6="${UTFCHAR} like #$WORD $A  $FONTSPEC $A $FHREF2"
  fi
  if [ `echo $WORD | wc -c` -gt 1 ]; then
   FHREF2="$FHREF1/#${WORD}"
  else
   if [ `echo $UTFCHAR | grep -v [[:punct:]] | wc -c` -gt 0 ]; then
   FHREF2="$FHREF1/#"`printf "$UTFCHAR%.0s" {1..20}`
   M5="${UTFCHAR}  $A   $FHREF2"
   M6="#${UTFCHAR} ($CHARINFO) $A $FHREF2"
   else
   FHREF2="${FHREF1}/#@"$((RANDOM%190+60))
   M4="$UTFCHAR $A #librefont ${FONTSPEC} by $AUTHOR ($SHREF)"
   M5=`printf "$UTFCHAR%.0s" {1..20}`" $A $HASHSPEC"
   M6=`printf "$UTFCHAR%.0s" {1..30}`" ($CHARINFO) $A $FONTSPEC"
   fi
  fi
  M1="${FONTSPEC} $A $UTFCHAR ($CHARINFO) $A $FHREF2"
  M2="$UTFCHAR ($HASHINFO) $A  $FONTSPEC"
  M3="$UTFCHAR $A $FONTSPEC $A  $FHREF2"

# --------------------------------------------------------------------------- #
# SELECT MESSAGE
# --------------------------------------------------------------------------- #
  MCHK=200; CNT=1
  while [ $MCHK -gt 116 ]; do
   MESSAGE=`echo ${M2}${BRK}${M3}${BRK}${M4}${BRK}${M5}${BRK}${M6}${BRK}${M1} | #
            sed "s/$BRK/\n/g"                           | # REBREAK
            shuf -n 1`                                    # SELECT RANDOM
   MCHK=`echo $MESSAGE                                  | # DISPLAY MESSAGE
         sed -e "s,http.\?://.* ,$URLFOO ,g"            | # REPLACE URL WITH FOO 
         wc -c`                                           # COUNT CHARACTERS
   CNT=`expr $CNT + 1`
  done
        echo "CHAR:   $UTFCHAR ($CHARINFO)"
        echo "FONT:   $FONTSPEC"
        echo "WORD:   $WORD"
        echo "TWEET:  ${MESSAGE};"
        echo "MEDIA:  ${FREEZE}.png"

# --------------------------------------------------------------------------- #
# UPLOAD
# --------------------------------------------------------------------------- #

  tweet $MESSAGE ${FREEZE}.png


# --------------------------------------------------------------------------- #
# CLEAN UP
# --------------------------------------------------------------------------- #
  rm $TMPDIR/$TMPID.*


exit 0;

