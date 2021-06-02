#!/bin/bash
# shellcheck disable=SC2001

# emba - EMBEDDED LINUX ANALYZER
#
# Copyright 2020-2021 Siemens AG
# Copyright 2020-2021 Siemens Energy AG
#
# emba comes with ABSOLUTELY NO WARRANTY. This is free software, and you are
# welcome to redistribute it under the terms of the GNU General Public License.
# See LICENSE file for usage of this software.
#
# emba is licensed under GPLv3
#
# Author(s): Michael Messner, Pascal Eckmann, Stefan Haboeck

INDEX_FILE="index.html"
MAIN_LOG="./emba.txt"
STYLE_PATH="/style"
TEMP_PATH="/tmp"

# variables for html style
P_START="<pre>"
P_END="</pre>"
SPAN_RED="<span class=\"red\">"
SPAN_GREEN="<span class=\"green\">"
SPAN_ORANGE="<span class=\"orange\">"
SPAN_BLUE="<span class=\"blue\">"
SPAN_MAGENTA="<span class=\"magenta\">"
SPAN_CYAN="<span class=\"cyan\">"
SPAN_BOLD="<span class=\"bold\">"
SPAN_ITALIC="<span class=\"italic\">"
SPAN_END="</span>"
HR_MONO="<hr class=\"mono\" />"
HR_DOUBLE="<hr class=\"double\" />"
BR="<br />"
LINK="<a href=\"LINK\" target=\"\_blank\" >"
LOCAL_LINK="<a class=\"local\" href=\"LINK\">"
REFERENCE_LINK="<a class=\"reference\" href=\"LINK\">"
REFERENCE_MODUL_LINK="<a class=\"refmodul\" href=\"LINK\">"
EXPLOIT_LINK="<a href=\"https://www.exploit-db.com/exploits/LINK\" target=\"\_blank\" >"
CVE_LINK="<a href=\"https://cve.mitre.org/cgi-bin/cvename.cgi?name=LINK\" target=\"\_blank\" >"
MODUL_LINK="<a class=\"modul\" href=\"LINK\">"
MODUL_INDEX_LINK="<a class=\"modul CLASS\" data=\"DATA\" href=\"LINK\">"
SUBMODUL_LINK="<a class=\"submodul\" href=\"LINK\">"
ANCHOR="<a id=\"ANCHOR\">"
LINK_END="</a>"
IMAGE="<img class=\"image\" src=\".$STYLE_PATH/PICTURE\">"

add_color_tags()
{
  COLOR_FILE="$1"
  sed -i -E \
    -e 's/\x1b\[/;/g ; s/;[0-9]{0};/;00;/g ; s/;([0-9]{1});/;0\1;/g ; s/;([0-9]{2});/;\1;/g ' \
    -e 's/;([0-9]{0})(m){1}/;00/g ; s/;([0-9]{1})(m){1}/;0\1/g ; s/;([0-9]{2})(m){1}/;\1/g ' \
    -e "s/;31/$SPAN_RED/g ; s/;32/$SPAN_GREEN/g ; s/;33/$SPAN_ORANGE/g" \
    -e "s/;34/$SPAN_BLUE/g ; s/;35/$SPAN_MAGENTA/g ; s/;36/$SPAN_CYAN/g" \
    -e "s/;01/$SPAN_BOLD/g ; s/;03/$SPAN_ITALIC/g ; s@;00@$SPAN_END@g" \
    -e "s@;[0-9]{2}@@g ; s@$P_START$P_END@$BR@g" "$COLOR_FILE"
}

add_link_tags() {
  local LINK_FILE
  LINK_FILE="$1"
  local BACK_LINK
  BACK_LINK="$2"

  # web links
  if ( grep -q -E '(https?|ftp|file):\/\/' "$LINK_FILE" ) ; then
    readarray -t WEB_LINKS < <( grep -o -E '(\b(https?|ftp|file):\/\/) ?[-A-Za-z0-9+&@#\/%?=~_|!:,.;]+[-A-Za-z0-9+&@#\/%=~a_|]' "$LINK_FILE" | sort -u)
    for WEB_LINK in "${WEB_LINKS[@]}" ; do
      if [[ -n "$WEB_LINK" ]] ; then
        HTML_LINK="$(echo "$LINK" | sed -e "s@LINK@$WEB_LINK@g")""$WEB_LINK""$LINK_END"
        sed -i "s@$WEB_LINK@$HTML_LINK@g" "$LINK_FILE"
      fi
    done
  fi

  # [REF] anchor 
  if ( grep -q -E '\[REF\]' "$LINK_FILE" ) ; then
    readarray -t REF_LINKS < <(grep -o -E '\[REF\].*' "$LINK_FILE" | cut -c7- | cut -d'<' -f1)
    for REF_LINK in "${REF_LINKS[@]}" ; do
      if [[ -f "$REF_LINK" ]] ; then
        if [[ "${REF_LINK: -4}" == ".txt" ]] ; then
          # generate reference file
          generate_info_file "$REF_LINK" "$BACK_LINK"
          LINE_NUMBER_INFO_PREV="$(grep -n -m 1 -E "\[REF\] ""$REF_LINK" "$LINK_FILE" | cut -d":" -f1)"
          LINE_NUMBER_INFO_PREV_O=$(( LINE_NUMBER_INFO_PREV ))
          HTML_LINK="$(echo "$REFERENCE_LINK" | sed -e "s@LINK@./$(echo "$BACK_LINK" | cut -d"_" -f1)/$(basename "${REF_LINK%.txt}").html@")"
          while [[ ("$(sed "$(( LINE_NUMBER_INFO_PREV - 1 ))q;d" "$LINK_FILE")" == "$P_START$SPAN_END$P_END") || ("$(sed "$(( LINE_NUMBER_INFO_PREV - 1 ))q;d" "$LINK_FILE")" == "$BR" ) ]] ; do 
            LINE_NUMBER_INFO_PREV=$(( LINE_NUMBER_INFO_PREV - 1 ))
          done
          sed -i -E -e "$(( LINE_NUMBER_INFO_PREV - 1 ))s@(.*)@$HTML_LINK\1$LINK_END@ ; $LINE_NUMBER_INFO_PREV_O""d" "$LINK_FILE"
        elif [[ "${REF_LINK: -4}" == ".png" ]] ; then
          # add linked image
          LINE_NUMBER_INFO_PREV="$(grep -n -m 1 -E "\[REF\] ""$REF_LINK" "$LINK_FILE" | cut -d":" -f1)"
          cp "$REF_LINK" "$ABS_HTML_PATH$STYLE_PATH""/""$(basename "$REF_LINK")"
          IMAGE_LINK="$(echo "$IMAGE" | sed -e "s@PICTURE@$(basename "$REF_LINK")@")"
          sed -i -E -e "$LINE_NUMBER_INFO_PREV""i""$IMAGE_LINK" -e "$LINE_NUMBER_INFO_PREV""d" "$LINK_FILE"
        fi
      elif [[ "$REF_LINK" =~ ^(p|r|s|f){1}[0-9]{2,3}$ ]] ; then
        # link modules
        LINE_NUMBER_INFO_PREV="$(grep -n -m 1 -E "\[REF\] ""$REF_LINK" "$LINK_FILE" | cut -d":" -f1)"
        LINE_NUMBER_INFO_PREV_O=$(( LINE_NUMBER_INFO_PREV ))
        readarray -t MODUL_ARR_LINK < <( find . -iname "$REF_LINK""_*" )
        if [[ "${#MODUL_ARR_LINK[@]}" -gt 0 ]] ; then
          MODUL_ARR_LINK_E="$(echo "${MODUL_ARR_LINK[0]}" | tr '[:upper:]' '[:lower:]')"
          HTML_LINK="$(echo "$REFERENCE_MODUL_LINK" | sed -e "s@LINK@./$(basename "${MODUL_ARR_LINK_E%.sh}").html@")"
          while [[ "$(sed "$(( LINE_NUMBER_INFO_PREV - 1 ))q;d" "$LINK_FILE")" == "$P_START$SPAN_END$P_END" ]] ; do 
            LINE_NUMBER_INFO_PREV=$(( LINE_NUMBER_INFO_PREV - 1 ))
          done
          sed -i -E -e "$(( LINE_NUMBER_INFO_PREV - 1 ))s@(.*)@$HTML_LINK\1$LINK_END@" "$LINK_FILE"
        fi
        sed -i -E -e "$LINE_NUMBER_INFO_PREV_O""d" "$LINK_FILE"
      else
        LINE_NUMBER_INFO_PREV="$(grep -n -E "\[REF\] ""$REF_LINK" "$LINK_FILE" | cut -d":" -f1)"
        sed -i -E -e "$LINE_NUMBER_INFO_PREV""d" "$LINK_FILE"
      fi
    done
  fi

  # Exploit links and additional files
  if ( grep -q -E '(Exploit|exploit)' "$LINK_FILE" ) ; then
    readarray -t EXPLOITS_IDS_F < <( sed -n -e 's/^.*Exploit database ID //p' "$LINK_FILE" | sed 's/[^0-9\ ]//g' | sort -u)
    readarray -t EXPLOITS_IDS_S < <( sed -n -e 's/^.*exploit-db: //p' "$LINK_FILE" | sed 's/[^0-9\ ]//g' | sort -u)
    EXPLOITS_IDS=( "${EXPLOITS_IDS_F[@]}" "${EXPLOITS_IDS_S[@]}" )
    for EXPLOIT_ID in "${EXPLOITS_IDS[@]}" ; do
      if [[ -n "$EXPLOIT_ID" ]] ; then
        EXPLOIT_FILE="$LOG_DIR""/aggregator/exploit/""$EXPLOIT_ID"".txt"
        if [[ -f "$EXPLOIT_FILE" ]] ; then
          # generate exploit file
          generate_info_file "$EXPLOIT_FILE" "$BACK_LINK"
          HTML_LINK="$(echo "$LOCAL_LINK" | sed -e "s@LINK@./info/$EXPLOIT_ID.html@g")""$EXPLOIT_ID""$LINK_END"
          sed -i -E "s@((Exploit database ID )|(exploit-db: ))$EXPLOIT_ID([^[:digit:]]{1})@\1$HTML_LINK\4@g" "$LINK_FILE"
        else
          HTML_LINK="$(echo "$EXPLOIT_LINK" | sed -e "s@LINK@$EXPLOIT_ID@g")""$EXPLOIT_ID""$LINK_END"
          sed -i -E "s@((Exploit database ID )|(exploit-db: ))$EXPLOIT_ID([^[:digit:]]{1})@\1$HTML_LINK\4@g" "$LINK_FILE"
        fi
      fi
    done
  fi

  # CVE links
  if ( grep -q -E '(CVE)' "$LINK_FILE" ) ; then
    readarray -t CVE_IDS < <( grep -E -o 'CVE-[0-9]{4}-[0-9]{4,7}' "$LINK_FILE" | sort -u)
    for CVE_ID in "${CVE_IDS[@]}" ; do
      if [[ -n "$CVE_ID" ]] ; then
        HTML_LINK="$(echo "$CVE_LINK" | sed -e "s@LINK@$CVE_ID@g")""$CVE_ID""$LINK_END"
        sed -i -E "s@$CVE_ID([^[:digit:]]{1})@$HTML_LINK\1@g" "$LINK_FILE"
      fi
    done
  fi
}

strip_color_tags()
{
  echo "$1" | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\000-\010\013\014\016-\037'
}

# often we have additional information, like exploits or cve's
generate_info_file()
{
  INFO_FILE=$1
  SRC_FILE=$2

  INFO_HTML_FILE="$(basename "${INFO_FILE%.txt}"".html")"
  INFO_PATH="$ABS_HTML_PATH""/""$(echo "$SRC_FILE" | cut -d"." -f1 | cut -d"_" -f1 )"
  RES_PATH="$INFO_PATH""/res"

  if ! [[ -d "$INFO_PATH" ]] ; then mkdir "$INFO_PATH" ; fi

  if ! [[ -f "$INFO_PATH""/""$INFO_HTML_FILE" ]] && [[ -f "$INFO_FILE" ]] ; then
    cp "./helpers/base.html" "$INFO_PATH""/""$INFO_HTML_FILE"
    sed -i -e "s:\.\/:\.\/\.\.\/:g" "$INFO_PATH""/""$INFO_HTML_FILE"
    TMP_INFO_FILE="$ABS_HTML_PATH""$TEMP_PATH""/""$INFO_HTML_FILE"

    # add back Link anchor to navigation
    LINE_NUMBER_INFO_NAV=$(grep -n "navigation start" "$INFO_PATH""/""$INFO_HTML_FILE" | cut -d":" -f1)
    NAV_INFO_BACK_LINK="$(echo "$MODUL_LINK" | sed -e "s@LINK@./../$SRC_FILE@g")"
    sed -i "$LINE_NUMBER_INFO_NAV""i""$NAV_INFO_BACK_LINK""&laquo; Back to ""$(basename "${SRC_FILE%.html}")""$LINK_END" "$INFO_PATH""/""$INFO_HTML_FILE"

    cp "$INFO_FILE" "$TMP_INFO_FILE"
    sed -i -e 's/&/\&amp;/g ; s/</\&lt;/g ; s/>/\&gt;/g' "$TMP_INFO_FILE"
    sed -i -e '/\[\*\]\ Statistics/d' "$TMP_INFO_FILE"

    sed -i -e "s:^:$P_START: ; s:$:$P_END:" "$TMP_INFO_FILE"
    # add html tags for style
    add_color_tags "$TMP_INFO_FILE"
    sed -i -e "s:[=]{65}:$HR_DOUBLE:g ; s:^[-]{65}$:$HR_MONO:g" "$TMP_INFO_FILE"
    
    # add link tags to links/generate info files and link to them and write line to tmp file
    add_link_tags "$TMP_INFO_FILE" "$INFO_HTML_FILE"

    readarray -t EXPLOITS_IDS_INFO < <( grep 'Exploit DB Id:' "$INFO_FILE" | sed -e 's/[^0-9\ ]//g ; s/\ //g' | sort -u )
    for EXPLOIT_ID in "${EXPLOITS_IDS_INFO[@]}" ; do
      ONLINE="$(echo "$EXPLOIT_LINK" | sed -e "s@LINK@$EXPLOIT_ID@g")""$EXPLOIT_ID""$LINK_END"
      printf "%s%sOnline: %s%s\n" "$HR_MONO" "$P_START" "$ONLINE" "$P_END" >> "$TMP_INFO_FILE"
    done

    readarray -t EXPLOIT_FILES < <(grep "File: " "$INFO_FILE" | cut -d ":" -f 2 | sed 's/^\ //' | sort -u)
    for E_PATH in "${EXPLOIT_FILES[@]}" ; do
      if [[ -f "$E_PATH" ]] ; then
        if ! [[ -d "$RES_PATH" ]] ; then mkdir "$RES_PATH" ; fi
        cp "$E_PATH" "$RES_PATH""/""$(basename "$E_PATH")"
        E_HTML_LINK="$(echo "$LOCAL_LINK" | sed -e "s@LINK@./$(echo "$SRC_FILE" | cut -d"_" -f1 )/$(basename "$E_PATH")@g")""$(basename "$E_PATH")""$LINK_END"
        printf "%s%sFile: %s%s\n" "$HR_MONO" "$P_START" "$E_HTML_LINK" "$P_END" >> "$TMP_INFO_FILE"
      fi
    done

    # add content of temporary html into template
    sed -i "/content start/ r $TMP_INFO_FILE" "$INFO_PATH""/""$INFO_HTML_FILE"
  fi
}

generate_report_file()
{
  REPORT_FILE=$1

  if ! ( grep -o -i -q "$(basename "${REPORT_FILE%.txt}")"" nothing reported" "$REPORT_FILE" ) ; then
    HTML_FILE="$(basename "${REPORT_FILE%.txt}"".html")"
    cp "./helpers/base.html" "$ABS_HTML_PATH""/""$HTML_FILE"
    TMP_FILE="$ABS_HTML_PATH""$TEMP_PATH""/""$HTML_FILE"
    MODUL_NAME=""

    # parse log content and add to html file
    LINE_NUMBER_REP_NAV=$(grep -n "navigation start" "$ABS_HTML_PATH""/""$HTML_FILE" | cut -d":" -f1)

    cp "$REPORT_FILE" "$TMP_FILE"
    sed -i -e 's/&/\&amp;/g ; s/</\&lt;/g ; s/>/\&gt;/g' "$TMP_FILE"
    sed -i '/\[\*\]\ Statistics/d' "$TMP_FILE"

    # module title anchor links
    if ( grep -q -E '[=]{65}' "$TMP_FILE" ) ; then
      MODUL_NAME="$( strip_color_tags "$(grep -E -B 1 '[=]{65}' "$TMP_FILE" | head -n 1)" | cut -d" " -f2- )"
      if [[ -n "$MODUL_NAME" ]] ; then
        # add anchor to file
        A_MODUL_NAME="$(echo "$MODUL_NAME" | sed -e "s/\ /_/g" | tr "[:upper:]" "[:lower:]")"
        LINE="$(echo "$ANCHOR" | sed -e "s@ANCHOR@$A_MODUL_NAME@g")""$MODUL_NAME""$LINK_END"
        sed -i -E "s@$MODUL_NAME@$LINE@" "$TMP_FILE"
        # add link to index navigation
        add_link_to_index "$HTML_FILE" "$MODUL_NAME"
        # add module anchor to navigation
        NAV_LINK="$(echo "$MODUL_LINK" | sed -e "s@LINK@#$A_MODUL_NAME@g")"
        sed -i "$LINE_NUMBER_REP_NAV""i""$NAV_LINK""$MODUL_NAME""$LINK_END" "$ABS_HTML_PATH""/""$HTML_FILE"
        ((LINE_NUMBER_REP_NAV++))
      fi
    fi

    # submodule title anchor links
    if ( grep -q -E '^[-]{65}$' "$TMP_FILE" ) ; then
      readarray -t SUBMODUL_NAMES < <( grep -E -B 1 '^[-]{65}$' "$TMP_FILE" | sed -E '/[-]{65}/d' | grep -v "^--")
      for SUBMODUL_NAME in "${SUBMODUL_NAMES[@]}" ; do
        if [[ -n "$SUBMODUL_NAME" ]] ; then
          SUBMODUL_NAME="$( strip_color_tags "$SUBMODUL_NAME" | cut -d" " -f 2- )"
          A_SUBMODUL_NAME="$(echo "$SUBMODUL_NAME" | sed -e "s/[^a-zA-Z0-9]//g" | tr "[:upper:]" "[:lower:]")"
          LINE="$(echo "$ANCHOR" | sed -e "s@ANCHOR@$A_SUBMODUL_NAME@g")""$SUBMODUL_NAME""$LINK_END"
          sed -i -E "s@$SUBMODUL_NAME@$LINE@" "$TMP_FILE"
          # Add anchor to file
          SUB_NAV_LINK="$(echo "$SUBMODUL_LINK" | sed -e "s@LINK@#$A_SUBMODUL_NAME@g")"
          sed -i "$LINE_NUMBER_REP_NAV""i""$SUB_NAV_LINK""$SUBMODUL_NAME""$LINK_END" "$ABS_HTML_PATH""/""$HTML_FILE"
          ((LINE_NUMBER_REP_NAV++))
        fi
      done
    fi

    sed -i -E -e "s:[=]{65}:$HR_DOUBLE:g ; s:^[-]{65}$:$HR_MONO:g" "$TMP_FILE"
    sed -i -e "s:^:$P_START: ; s:$:$P_END:" "$TMP_FILE"
    
    # add html tags for style
    add_color_tags "$TMP_FILE"

    # add link tags to links/generate info files and link to them and write line to tmp file
    # also parsing for [REF] anchor and generate linked files and link it
    add_link_tags "$TMP_FILE" "$HTML_FILE"

    # add content of temporary html into template
    sed -i "/content start/ r $TMP_FILE" "$ABS_HTML_PATH""/""$HTML_FILE"
    # add aggregator lines to index page
    if [[ "$HTML_FILE" == "f50"* ]] ; then
      sed -i "/content start/ r $TMP_FILE" "$ABS_HTML_PATH""/""$INDEX_FILE"
    fi
  fi
}

add_link_to_index() {

  insert_line() {
    SEARCH_VAL="$1"
    MODUL_NAME="$2"
    LINE_NUMBER_NAV=$(grep -n "$SEARCH_VAL" "$ABS_HTML_PATH""/""$INDEX_FILE" | cut -d ":" -f 1)
    REP_NAV_LINK="$(echo "$MODUL_INDEX_LINK" | sed -e "s@LINK@./$HTML_FILE@g" | sed -e "s@CLASS@$CLASS@g" | sed -e "s@DATA@$DATA@g")"
    sed -i "$LINE_NUMBER_NAV""i""$REP_NAV_LINK""$MODUL_NAME""$LINK_END" "$ABS_HTML_PATH""/""$INDEX_FILE"
  }

  HTML_FILE="$1"
  MODUL_NAME="$2"
  DATA="$( echo "$HTML_FILE" | cut -d "_" -f 1)"
  CLASS="${DATA:0:1}"
  C_NUMBER="$(echo "${DATA:1}" | sed -E 's/^0*//g')"

  readarray -t INDEX_NAV_ARR < <(sed -n -e '/navigation start/,/navigation end/p' "$ABS_HTML_PATH""/""$INDEX_FILE" | sed -e '1d;$d' | grep -P -o '(?<=data=\").*?(?=\")')
  readarray -t INDEX_NAV_GROUP_ARR < <(printf -- '%s\n' "${INDEX_NAV_ARR[@]}" | grep "$CLASS" )

  if [[ ${#INDEX_NAV_GROUP_ARR[@]} -eq 0 ]] ; then
    # due the design of emba, which are already groups the modules (even threaded), it isn't necessary to check - 
    # insert new entry at bottom of the navigation
    insert_line "navigation end" "$MODUL_NAME"
  else
    for (( COUNT=0; COUNT<=${#INDEX_NAV_GROUP_ARR[@]}; COUNT++ )) ; do
      if [[ $COUNT -eq 0 ]] && [[ $C_NUMBER -lt $( echo "${INDEX_NAV_GROUP_ARR[$COUNT]:1}" | sed -E 's/^0*//g' ) ]] ; then
        insert_line "${INDEX_NAV_GROUP_ARR[$COUNT]}" "$MODUL_NAME"
      elif [[ $C_NUMBER -gt $( echo "${INDEX_NAV_GROUP_ARR[$COUNT]:1}" | sed -E 's/^0*//g' ) ]] && [[ $C_NUMBER -lt $( echo "${INDEX_NAV_GROUP_ARR[$((COUNT+1))]:1}" | sed -E 's/^0*//g' ) ]] ; then
        insert_line "${INDEX_NAV_GROUP_ARR[$((COUNT+1))]}" "$MODUL_NAME"
      elif [[ $COUNT -eq $(( ${#INDEX_NAV_GROUP_ARR[@]}-1 )) ]] && [[ $C_NUMBER -gt $( echo "${INDEX_NAV_GROUP_ARR[$COUNT]:1}" | sed -E 's/^0*//g' ) ]] ; then
        insert_line "navigation end" "$MODUL_NAME"
      fi
    done
  fi
}

update_index()
{
  # add emba.log to webreport
  generate_report_file "$MAIN_LOG"
  sed -i -E -e "s@(id=\"buttonTime\")@\1 style=\"visibility: visible\"@ ; s@TIMELINK@.\/$(basename "${MAIN_LOG%.txt}"".html")@" "$ABS_HTML_PATH""/""$INDEX_FILE"
  # remove tempory files from web report
  rm -R "$ABS_HTML_PATH$TEMP_PATH"
}

prepare_report()
{
  ABS_HTML_PATH="$(abs_path "$HTML_PATH")"
  
  if [ ! -d "$ABS_HTML_PATH$STYLE_PATH" ] ; then
    mkdir "$ABS_HTML_PATH$STYLE_PATH"
    cp "$HELP_DIR/style.css" "$ABS_HTML_PATH$STYLE_PATH/style.css"
    cp "$HELP_DIR/emba.svg" "$ABS_HTML_PATH$STYLE_PATH/emba.svg"
  fi
  if [ ! -d "$ABS_HTML_PATH$TEMP_PATH" ] ; then
    mkdir "$ABS_HTML_PATH$TEMP_PATH"
  fi

  cp "./helpers/base.html" "$ABS_HTML_PATH""/""$INDEX_FILE"
  sed -i 's/back/back hidden/g' "$ABS_HTML_PATH""/""$INDEX_FILE"
}