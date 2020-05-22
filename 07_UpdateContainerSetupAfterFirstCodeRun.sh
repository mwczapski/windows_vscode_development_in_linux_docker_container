#!/bin/bash

set -o pipefail
set -o errexit

traperr() {
  echo "ERROR: ------------------------------------------------"
  echo "ERROR: ${BASH_SOURCE[1]} at about ${BASH_LINENO[0]}"
  echo "ERROR: ------------------------------------------------"
}
set -o errtrace
trap traperr ERR

[[ ${libSourceMgmt} ]] || source ./libs/libSourceMgmt.sh "1.0.0"
[[ ${__env_GlobalConstants} ]] || source ./utils/__env_GlobalConstants.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${fn__WSLPathToDOSandWSDPaths} ]] || source ./utils/fn__WSLPathToDOSandWSDPaths.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${fn__CreateWindowsShortcut} ]] || source ./utils/fn__CreateWindowsShortcut.sh "1.0.0" || exit ${__EXECUTION_ERROR}


## ##################################################################################
## ##################################################################################
## expect directory structure like
## /mnt/x/dir1/dir2/..dirN/projectDir/_commonUtils/02_create_node13131_container
## and working directory /mnt/x/dir1/dir2/..dirN/projectDir/_commonUtils
## ##################################################################################
## ##################################################################################


__DEBMIN_HOME=$(pwd)
readonly __CWD_NAME=$(basename ${__DEBMIN_HOME})
[[ "${__CWD_NAME}" == "${__SCRIPTS_DIRECTORY_NAME}" ]] || {
  echo "${0} must run from directory with name _commonUtils and will use the name of its parent directory as project directory"
  exit ${__FAILED}
}

cd ${__DEBMIN_HOME}


__DEBMIN_HOME=${__DEBMIN_HOME%%/${__SCRIPTS_DIRECTORY_NAME}} # strip _commonUtils
__DEBMIN_HOME_DOS=$(fn__WSLPathToRealDosPath ${__DEBMIN_HOME})


folderLines=$(grep '"folder": "vscode-remote' /mnt/c/Users/${USER}/AppData/Roaming/Code/storage.json) && STS=$? || STS=$?
if [[ ${STS} -ne ${__SUCCESS} ]]
then
  echo "____________Cannot determine internal container id for use with vscode-remote"
  echo "____________Start the container, if not running, use vscode to attach to the remote container and let it install what it wants"
  echo "____________Keep the container running and re-run the script"
  exit ${__FAILED}
fi


folderUri=$(echo ${folderLines} | sed 's|^.*\"folder\": ||;s|,$||') && STS=$? || STS=$?
if [[ ${STS} -ne ${__SUCCESS} ]]; then
  echo "____________Error getting folderUri"
  echo "____________Have:"
  echo ${folderUri}
  echo "____________Investigate the issue then try getting Container Id again"
  exit ${__FAILED}
fi


declare -r lrShellScriptPath="${__DEBMIN_HOME}/${__SCRIPTS_DIRECTORY_NAME}/10_code_in_remote_container.sh"
echo "'/mnt/c/Program Files/Microsoft VS Code/Code.exe'" --folder-uri ${folderUri} > ${lrShellScriptPath}
chmod u+x ${lrShellScriptPath}


declare -r lrLinkDOSPath="${__DEBMIN_HOME_DOS}\\${__SCRIPTS_DIRECTORY_NAME}\\10 code in remote container.lnk"


powershell.exe "
  \$s=(New-Object -COM WScript.Shell).CreateShortcut('${lrLinkDOSPath}');\
  \$s.TargetPath='wsl.exe';\
  \$s.WorkingDirectory='%~dp0';\
  \$s.Arguments=' ${lrShellScriptPath} ';\
  \$s.WindowStyle=${fn__CreateWindowsShortcut__RUN_MINIMISED};\
  \$s.IconLocation='C:\Program Files\Microsoft VS Code\Code.exe';\
  \$s.Save()
"


echo "____________Created/Updated Container Id and Links to Remote Development"
