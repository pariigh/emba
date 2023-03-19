#!/bin/bash -p

# EMBA - EMBEDDED LINUX ANALYZER
#
# Copyright 2020-2023 Siemens Energy AG
# Copyright 2020-2023 Siemens AG
#
# EMBA comes with ABSOLUTELY NO WARRANTY. This is free software, and you are
# welcome to redistribute it under the terms of the GNU General Public License.
# See LICENSE file for usage of this software.
#
# EMBA is licensed under GPLv3
#
# Author(s): Michael Messner, Pascal Eckmann

# Description: Sets default values for EMBA


set_defaults() {
  # if this is a release version set RELEASE to 1, add a banner to config/banner and name the banner with the version details
  export RELEASE=1
  export EMBA_VERSION="1.2.2"

  export CLEANED=0              # used for the final cleaner function for not running it multiple times
  export STRICT_MODE=0
  export DEBUG_SCRIPT=0
  export UPDATE=0
  export ARCH_CHECK=1
  export RTOS=0                 # Testing RTOS based OS
  export CWE_CHECKER=0
  export CONTAINER_EXTRACT=0
  export DEEP_EXTRACTOR=0
  export FACT_EXTRACTOR=0
  export FIRMWARE=0
  export FORCE=0
  export FORMAT_LOG=0
  export HTML=0
  export IN_DOCKER=0
  export USE_DOCKER=1
  export KERNEL=0
  export KERNEL_CONFIG=""
  export FIRMWARE_PATH=""
  export FW_VENDOR=""
  export FW_VERSION=""
  export FW_DEVICE=""
  export FW_NOTES=""
  export ARCH=""
  export EXLUDE=()
  export SELECT_MODULES=()
  export MODULES_EXPORTED=()
  export ROOT_PATH=()
  export FILE_ARR=()
  export LOG_GREP=0
  export MAX_MODS=0
  export MAX_MOD_THREADS=0
  export RESTART=0              # if we find an unfinished EMBA scan we try to only process not finished modules
  export FINAL_FW_RM=0          # remove the firmware working copy after testing (do not waste too much disk space)
  export ONLY_DEP=0             # test only dependency
  export PHP_CHECK=1
  export PRE_CHECK=0            # test and extract binary files with binwalk
                                # afterwards do a default EMBA scan
  export SKIP_PRE_CHECKERS=0    # we can set this to 1 to skip all further pre-checkers (WARNING: use this with caution!!!)
  export PYTHON_CHECK=1
  export QEMULATION=0
  export FULL_EMULATION=0
  # to get rid of all the running stuff we are going to kill it after RUNTIME
  export QRUNTIME="20s"

  export SHELLCHECK=1
  export SHORT_PATH=0           # short paths in cli output
  export THREADED=0             # 0 -> single thread
                                # 1 -> multi threaded
  export YARA=1
  export OVERWRITE_LOG=0        # automaticially overwrite log directory, if necessary
  export JUMP_OVER_CVESEARCH_CHECK=0 # ignore long CVEsearch check in dep check

  export MAX_EXT_SPACE=11000     # a useful value, could be adjusted if you deal with very big firmware images
  export LOG_DIR="$INVOCATION_PATH""/logs"
  export TMP_DIR="$LOG_DIR""/tmp"
  export CSV_DIR="$LOG_DIR""/csv_logs"
  export MAIN_LOG_FILE="emba.log"
  export CONFIG_DIR="$INVOCATION_PATH""/config"
  export EXT_DIR="$INVOCATION_PATH""/external"
  export HELP_DIR="$INVOCATION_PATH""/helpers"
  export MOD_DIR="$INVOCATION_PATH""/modules"
  export MOD_DIR_LOCAL="$INVOCATION_PATH""/modules_local"
  export PID_LOGGING=0
  # this will be in TMP_DIR/pid_notes.log
  export PID_LOG_FILE="pid_notes.log"
  export BASE_LINUX_FILES="$CONFIG_DIR""/linux_common_files.txt"
  export PATH_CVE_SEARCH="$EXT_DIR""/cve-search/bin/search.py"
  if [[ -f "$CONFIG_DIR"/known_exploited_vulnerabilities.csv ]]; then
    export KNOWN_EXP_CSV="$CONFIG_DIR"/known_exploited_vulnerabilities.csv
  fi
  if [[ -f "$CONFIG_DIR"/msf_cve-db.txt ]]; then
    export MSF_DB_PATH="$CONFIG_DIR"/msf_cve-db.txt
  fi
  if [[ -f "$CONFIG_DIR"/trickest_cve-db.txt ]]; then
    export TRICKEST_DB_PATH="$CONFIG_DIR"/trickest_cve-db.txt
  fi
  export GTFO_CFG="$CONFIG_DIR"/gtfobins_urls.cfg         # gtfo urls
  export DISABLE_STATUS_BAR=1
  # as we encounter issues with the status bar on other system we disable it for non Kali systems
  export DISABLE_NOTIFICATIONS=1    # disable notifications and further desktop experience
  if [[ -f "/etc/debian_version" ]] && grep -q kali-rolling /etc/debian_version; then
    export DISABLE_NOTIFICATIONS=0    # disable notifications and further desktop experience
  fi
  export NOTIFICATION_ID=0          # initial notification id - needed for notification overlay/replacement
  export EMBA_ICON=""
  EMBA_ICON=$(realpath "$HELP_DIR"/emba.svg)
  export WSL=0    # wsl environment detected
  export UNBLOB=1 # additional extraction with unblob - https://github.com/onekey-sec/unblob
                  # currently the extracted results are not further used. The current implementation
                  # is for evaluation purposes
  export CVE_BLACKLIST="$CONFIG_DIR"/cve-blacklist.txt  # include the blacklisted CVE values to this file
  export CVE_WHITELIST="$CONFIG_DIR"/cve-whitelist.txt  # include the whitelisted CVE values to this file
  export MODULE_BLACKLIST=()
  if [[ -f "$CONFIG_DIR"/module_blacklist.txt ]]; then
    readarray -t MODULE_BLACKLIST < "$CONFIG_DIR"/module_blacklist.txt
  fi
  # usually no memory limit is needed, but some modules/tools are wild and we need to protect our system
  export TOTAL_MEMORY=0
  TOTAL_MEMORY="$(grep MemTotal /proc/meminfo | awk '{print $2}' || true)"
}