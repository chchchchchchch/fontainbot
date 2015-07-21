#!/bin/bash


# --------------------------------------------------------------------------- #
# PARSE INPUT FROM THE COMMAND LINE
# --------------------------------------------------------------------------- #
  RPNM=$1 ; RPID=$2
  TEXT=`cat $3              | #
        sed 's/\\\u200b//g' | #
        recode h0..utf-8`     #
  OTXT=`echo -e "$TEXT"`
  TEXT=`echo -e "$TEXT "                 | # START WITH TEXT
        sed -e "s,.\?\?http.\?://.* ,,g" | # REMOVE URLS
        sed 's/^[ \t]*//'                | # REMOVE LEADING BLANKS
        sed 's/[ \t]$//'`                  # REMOVE CLOSING BLANKS

  if [ `echo "$TEXT" | wc -c` -gt 13 ] ||
     [ `echo "$TEXT" | grep "[.?!]$" | wc -l` -gt 0 ]
  then PAD=" "; else PAD=""; fi
  CNT=0;while [ $CNT -lt 120 ];do
    TEXT="$TEXT$PAD$TEXT";CNT=`echo "$TEXT" | wc -c`;done 
  TEXT=`echo "$TEXT" | cut -c 1-120`


# --------------------------------------------------------------------------- #
# GENERAL STUFF
# --------------------------------------------------------------------------- #
  source lib/sh/twitter.functions
  source lib/sh/prepress.functions
  source lib/sh/ftp.functions

  SOURCE=EDIT/150710_letterset.svg
  TMPDIR=. ; TMPID=$TMPDIR/TMP${RANDOM%9}
  TARGET=${TMPID}.svg
  SPACEFOO=S${RANDOM}P
  FF=fontforge
  ISFS="-inkscape-font-specification"
  BRK=$RANDOM
  FURL="freeze.sh/_/2015/fontainbot/o/150710"
  A=`echo -e "→ \n[>]\n|→ \n//" | shuf -n 1`
  IDBASE=`echo $RPID | # DISPLAY FONT SPECIFICATION
          md5sum     | # MAKE MD5SUM
          cut -c 1-4``basename $0     | # DISPLAY BASENAME OF SCRIPT
                      cut -d "_" -f 2 | # SELECT TYPE NOT DATE
                      cut -d "." -f 1 | # REMOVE EXTENSION
                      md5sum          | # MAKE MD5SUM
                      cut -c 1-4`       # CUT 1 CHARACTERS
  NAME=${IDBASE}`date +%y%m`
# --------------------------------------------------------------------------- #


  if [ `ls FREEZE/${IDBASE}* 2>/dev/null | wc -l` -gt 0 ]; then
       #echo "export for ${IDBASE} exists";
        sleep 0
  else
# --------------------------------------------------------------------------- #
# COLLECT INPUT
# --------------------------------------------------------------------------- #
  cp $SOURCE $TARGET
  ALLINFO=`identify -list font           | # LIST ALL FONTS
           sed ":a;N;\\$!ba;s/\n/$BRK/g" | # REMOVE ALL LINEBREAKS
           sed 's/Font:/\n&/g'           | # PUT ON SEPARATE LINES
           grep ".fonts/fontain"`          # SELECT FONTAIN FONTS
  TEXTCOUNT=`echo "$TEXT" | sed 's/./c/g' | wc -c`
  TEXT=`echo "$TEXT" | sed "s/ /$SPACEFOO/g"`
 
# --------------------------------------------------------------------------- #
# PREPARE SVG TO APPEND STUFF AS NEW LAYER
# --------------------------------------------------------------------------- #
  LAYERNAME=`date +%Y%m%d-%H%M%S`;ID=`echo $LAYERNAME | md5sum | cut -c 1-5`
  sed -i 's,</svg>,,g' $TARGET
  echo "<g style=\"display:inline\"  \
        id=\"${ID}01\"               \
        inkscape:groupmode=\"layer\"  \
        inkscape:label=\"$LAYERNAME\">"| #
  tr -s ' '                                 >> $TARGET

  DESCRIPTIONSTYLE=`echo "font-size:8px;         \
                          text-align:center;      \
                          line-height:100%;        \
                          writing-mode:lr-tb;       \
                          text-anchor:middle;        \
                          fill:#000000;               \
                          font-family:Source Code Pro; \
                         -inkscape-font-specification:Source Code Pro Medium" | #
                    sed 's/;[ \t]*/;/g'`
# --------------------------------------------------------------------------- #
# SET START VALUES
# --------------------------------------------------------------------------- #
  XSHIFT="39";YSHIFT="70";X1="31";Y1="38";XPOS="$X1";YPOS="$Y1"

# --------------------------------------------------------------------------- #
# START LOOP
# --------------------------------------------------------------------------- #

 COUNT=1;SUPERFAIL=0
 while [ $COUNT -le 108 ]     && 
       [ $SUPERFAIL -lt 500 ] &&
       [ $COUNT -lt $TEXTCOUNT ]
  do
      LETTER=`echo "$TEXT"                | #
              sed "s/$SPACEFOO/\n&\n/g"   | #
              sed "/$SPACEFOO/!s/./\n&/g" | #
              sed '/^ *$/d'               | #
              head -n $COUNT | tail -n 1`

  if [ "X$LETTER" != "X$SPACEFOO" ]; then

   # echo -n "$LETTER"

# --------------------------------------------------------------------------- #
# COLLECT FONT INFORMATION
# --------------------------------------------------------------------------- #
     FONTINFO=`echo $ALLINFO      | # DISPLAY ALL INFO (= 1 LONG LINE)
               sed 's/Font:/\n&/g'| # MOVE FONT DEFINITIONS ON SEPARATE LINES
               sed '/^ *$/d'      | # REMOVE EMPTY LINES
               shuf -n 1`           # SELECT RANDOM ONE
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
                     font-style:$FONTSTYLE;font-family:$FONTFAMILY;" | #
               sed "s/ //g" | tr [:upper:] [:lower:]`$ISFS:$FONTSPEC

# --------------------------------------------------------------------------- #
# MAKE A LIST OF AVAILABLE CHARACTERS (IF STILL NECESSARY
# --------------------------------------------------------------------------- #
  NAMLIST=$TMPID`echo $FONTSRC | md5sum | cut -c 1-16`.nam
  if [ ! -f $NAMLIST ]; then
  python -c "import $FF;$FF.open(\"$FONTSRC\").saveNamelist(\"$NAMLIST\")" \
  > /dev/null 2>&1
  fi
  if [ `grep "\`echo $LETTER       | #
                recode utf8..u2/x2 | #
                cut -d "," -f 1\`" $NAMLIST | wc -l` -lt 1 ]; then
      # echo "$LETTER not available within $FONTFAMILY"
        CHARAVAILABLE="not"
        COUNT=`expr $COUNT - 1`
        SUPERFAIL=`expr $SUPERFAIL + 1` # PREVENT ENDLESS LOOP
  else
        CHARAVAILABLE="yes"
  fi

  if [ $CHARAVAILABLE = "yes" ]; then
# --------------------------------------------------------------------------- #
# WRITE SVG CONTENT (APPEND)
# --------------------------------------------------------------------------- #
  LETTER=`echo "$LETTER" | recode utf-8..h0`
  DESCRIPTION=`echo $FONTFAMILY | recode utf-8..h0`
  LETTERSTYLE=`echo "font-size:80px;   \
                     text-align:center; \
                     writing-mode:lr-tb; \
                     text-anchor:middle;  \
                     fill:#000000;         \
                     $SVGFONTDEF" | #
                sed 's/;[ \t]*/;/g'`
  ID=`echo $RANDOM | md5sum | cut -c 1-3`
  echo "<g transform=\"translate($XPOS,$YPOS) scale(0.5)\" \
         id=\"${ID}02\">" | #
  tr -s ' '   >> $TARGET
  echo "<flowRoot xml:space=\"preserve\" id=\"${ID}03\"           \
         style=\"$LETTERSTYLE\"><flowRegion id=\"${ID}03\">        \
        <rect id=\"${ID}04\" width=\"100\" height=\"100\" x=\"0\" y=\"0\"\
         style=\"$LETTERSTYLE\" /></flowRegion>                      \
        <flowPara id=\"${ID}05\">$LETTER</flowPara></flowRoot>        \
        <path style=\"fill:none;\" d=\"m 10,94 80,0 0,40 -80,0 z\"     \
         id=\"${ID}06\" inkscape:connector-curvature=\"0\" />           \
        <flowRoot xml:space=\"preserve\" id=\"${ID}07\"                  \
         style=\"$DESCRIPTIONSTYLE\"><flowRegion id=\"${ID}08\">          \
        <rect id=\"${ID}09\" width=\"76\" height=\"45\" x=\"12\" y=\"120\" \
         style=\"$DESCRIPTIONSTYLE\" /></flowRegion><flowPara               \
         id=\"${ID}10\">$DESCRIPTION</flowPara></flowRoot>" | #
   tr -s ' ' | sed 's/>[ \t]*</></g'     >> $TARGET
   echo "</g>"                           >> $TARGET
  fi
  else
    sleep 0; # echo -n " "
  fi
    if [ X$CHARAVAILABLE = "Xyes" ] ||
       [ "X$LETTER" = "X$SPACEFOO" ]; then
    XPOS=`expr $XPOS + $XSHIFT`
    ROW=`expr $ROW + 1`
    if [ $ROW -eq 12 ]; then
         XPOS=$X1
         YPOS=`expr $YPOS + $YSHIFT`
          ROW="0"
    fi
    fi
    COUNT=`expr $COUNT + 1`
  done; # echo -e "\n"
  echo "</g>"                             >> $TARGET
  echo "</svg>"                           >> $TARGET

# --------------------------------------------------------------------------- #
# SUPERFAIL EXIT AND CLEAN UP
# --------------------------------------------------------------------------- #
  if [ $SUPERFAIL -ge 500 ]; then
       rm ${TMPID}*
       echo -e "\nSUPERFAIL!"
       exit 1;
  fi

# --------------------------------------------------------------------------- #
# EXPORT (PNG/PDF/SVG)
# --------------------------------------------------------------------------- #
  FREEZE=FREEZE/${NAME}
  MHO=`echo -e "@${RPNM}: ""$OTXT" | #
       recode utf-8..h0            | #
       sed 's/&/\\\\&/g'           | #
       sed 's/\\//\\\\\//g'`         #

  sed -i "s/REPLYTO/$MHO/g" $TARGET

  inkscape --export-png=${FREEZE}.png \
           --export-area=12:12:533:753 \
           --export-width=1024 \
           --export-background=FFFFFF \
           $TARGET > /dev/null 2>&1
  inkscape --export-pdf=${FREEZE}.pdf \
           --export-text-to-path  \
           $TARGET > /dev/null 2>&1

  pdfxgs ${FREEZE}.pdf
  mv $TARGET ${FREEZE}.svg

# --------------------------------------------------------------------------- #
# TWITTER UPLOAD
# --------------------------------------------------------------------------- #
  INFO=`identify -format "%wx%h" "${FREEZE}.png"[0]`
     W=`echo $INFO | cut -d "x" -f 1`
     H=`echo $INFO | cut -d "x" -f 2`
  convert ${FREEZE}.png \
         -stroke black -strokewidth 3 \
         -fill none \
         -draw "rectangle 0,0 $W,$H" \
         ${FREEZE}.gif

  if [ `echo "$OTXT" | wc -w` -gt 3 ];then
  REPLY=`echo -e "$OTXT "                 | # 
         sed -e "s,.\?\?http.\?://.* ,,g" | #
         fold -s -w 6                     | # SPLIT AT & CHARACTERS
         shuf                             | # SHUFFLE
         sed ':a;N;$!ba;s/\n/ /g'         | # REMOVE ALL LINEBREAKS
         fold -s -w 85                    | # SPLIT AT 85 CHARACTERS
         head -n 1                        | # SELECT FIRST LINE
         tr -s ' '                        | # SQUEEZE SPACES
         tr [[:upper:]] [[:lower:]]       | # ALL LOWER CASE
         sed 's/[ \t]$//'`                  # REMOVE SPACES AT END
  elif [ `echo "$OTXT" | wc -c` -le 2 ];then
  REPLY=`echo -e "$TEXT"                  | # WITH SPACE AT END (URL RM HACK)
         sed "s/./& $A /g"                | # SPACES TO ARROWS
         fold -s -w 85                    | # SPLIT AT 85 CHARACTERS
         head -n 1                        | # SELECT FIRST LINE
         sed 's/[ \t]$//'                 | # REMOVE SPACES AT END
         sed "s/ ${A}$//"`                  # REMOVE LAST ARROW
  else
# REPLY=`echo -e "$OTXT "                 | # WITH SPACE AT END (URL RM HACK)
#        sed -e "s,.\?\?http.\?://.* ,,g" | #
#        sed "s/ //g"                     | # REMOVE SPACES
#        sed "s/./& /g"                   | # ADD SPACES AFTER EACH CHARACTER
#        fold -s -w 4                     | # BREAK AFTER EACH CHARACTER
#        shuf                             | # SELECT FIRST LINE
#        sed ':a;N;$!ba;s/\n/ /g'         | # REMOVE ALL LINEBREAKS
#        cut -c 1-40                      | #
#        tr -s ' '                        | #
#        sed 's/[ \t]$//'                 | # REMOVE SPACES AT END
#        tee`
  REPLY=`echo -e "$OTXT "                 | # WITH SPACE AT END (URL RM HACK)
         cut -c 1-40                      | #
         tr -s ' '                        | #
         sed 's/[ \t]$//'                 | # REMOVE SPACES AT END
         tee`
 fi
   REPLY=`echo -e "$REPLY"    | #
          sed 's/./&\n/g'     | #
          grep -v [[:punct:]] | #
          sed ':a;N;$!ba;s/\n//g'`
   REPLY=`echo -e "@${RPNM}: ""$REPLY"`


  OPTIONSPLUS="&in_reply_to_status_id=$RPID"
  MESSAGE="$REPLY … $A ${FURL}#${NAME}"

# echo  "$MESSAGE" ${FREEZE}.gif
  tweet "$MESSAGE" ${FREEZE}.gif

# --------------------------------------------------------------------------- #
# FREEZE UPLOAD
# --------------------------------------------------------------------------- #
  IMG=FREEZE/${NAME}.png
  IID='<!-- ADD HERE -->'
  OLDHTML="http://freeze.sh/_/2015/fontainbot/o/150710.html"
  TMPHTML=$TMPID.html
  NEWHTML=$TMPDIR/150710.html
  wget --no-check-certificate \
       -O $TMPHTML             \
       $OLDHTML > /dev/null 2>&1

# --------------------------------------------------------------------------- #
# UPDATE HTML
# --------------------------------------------------------------------------- #
# WRITE EVERYTHING ABOVE INJECTION ID
# --------------------------------------------------------------------------- #
  tac $TMPHTML        | # REVERSE
  sed -n "/$IID/,\$p" | # PRINT FROM REGEX TO START
  tac                 | # REVERSE
  sed "s/$IID//g"     | # REMOVE INJECTION ID
  sed '/./,/^$/!d'    | # REMOVE CONSECUTIVE BLANK LINES
  tee                                   >  $NEWHTML
# --------------------------------------------------------------------------- #
# ADD NEW IMAGE
# --------------------------------------------------------------------------- #
  CLO=`echo -e "l\nc\nr\nl\nr" | shuf -n 1`
  CLS=`echo -e "sa\nsb\nsc\nsd" | shuf -n 1`
  CLASSDEF="class=\"g $CLS $CLO\""
  HSVG=${NAME}.svg;HPDF=${NAME}.pdf;HIMG=`basename $IMG`
  echo "<table $CLASSDEF id=\"${NAME}\"><tr><td colspan=\"2\"> \
        <a href=\"$HPDF\"><img src=\"$HIMG\"/></a></td></tr><tr> \
        <td class=\"t l\"><tt>.<a href=\"$HSVG\">svg</a> (EDITABLE TEXT)
        </tt></td><td class=\"t r\"><tt>.<a href=\"$HPDF\">pdf</a> 
        (OUTLINED TEXT)</tt></td></tr></table>" | #
  tr -s ' ' | sed 's/>[ \t]*</></g' | fold -s -w 60 >> $NEWHTML
# --------------------------------------------------------------------------- #
# RESTORE INJECTION ID
# --------------------------------------------------------------------------- #
  echo                                  >> $NEWHTML
  echo $IID                             >> $NEWHTML
# --------------------------------------------------------------------------- #
# WRITE EVERYTHING BENEATH INJECTION ID
# --------------------------------------------------------------------------- #
  cat $TMPHTML        | # USELESS USE OF CAT
  sed -n "/$IID/,\$p" | # PRINT FROM REGEX TO START
  sed "s/$IID//g"     | # REMOVE INJECTION ID
  sed '/./,/^$/!d'    | # REMOVE CONSECUTIVE BLANK LINES
  tee     >> $NEWHTML   # WRITE TO FILE
# --------------------------------------------------------------------------- #
# UPLOAD!
# --------------------------------------------------------------------------- #
  if [ "X$TWTRPRT" == "Xerror" ]; then
        echo "There was an error, do not upload"
  else
  ftpUpload $IMG $NEWHTML ${FREEZE}.pdf ${FREEZE}.svg
  fi

# --------------------------------------------------------------------------- #
# FOR THE LOGS
# --------------------------------------------------------------------------- #
  echo "TIME:   "`date "+%d.%m.%Y %T"`
  echo "SCRIPT: $0"
  echo "RE TO:  $RPID"
  echo "TWEET:  ${MESSAGE}"
  echo "MEDIA:  ${FREEZE}.png"
  echo "----------------------------"

  touch tweet.yes

# --------------------------------------------------------------------------- #
# CLEAN UP
# --------------------------------------------------------------------------- #
  rm ${TMPID}* $NEWHTML
  fi


exit 0;
