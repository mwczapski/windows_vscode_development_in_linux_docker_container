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
[[ ${__env_gitClientConstants} ]] || source ./utils/__env_gitClientConstants.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${fn__WSLPathToDOSandWSDPaths} ]] || source ./utils/fn__WSLPathToDOSandWSDPaths.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${fn__CreateWindowsShortcut} ]] || source ./utils/fn__CreateWindowsShortcut.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${fn__DockerGeneric} ]] || source ./utils/fn__DockerGeneric.sh "1.0.0" || exit ${__FAILED}
[[ ${_02_create_git_client_container_utils} ]] || source ./02_create_git_client_container_utils.sh "1.0.0" || exit ${__EXECUTION_ERROR}


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


declare lDerivedContainerName=$(fn__DeriveContainerName ${__DEBMIN_HOME}) && STS=$? || STS=$?
if [[ ${STS} -eq ${__FAILED} ]]
then
  return ${__FAILED}
fi


__DEBMIN_HOME=${__DEBMIN_HOME%%/${__SCRIPTS_DIRECTORY_NAME}} # strip _commonUtils
__DEBMIN_HOME_DOS=$(fn__WSLPathToRealDosPath ${__DEBMIN_HOME})


fn__ContainerExists \
    "${lDerivedContainerName}" && STS=0 || STS=1
[[ $STS -eq ${__NO} ]] && {
    echo "____ Container '${lDerivedContainerName} 'does not exist or is not running!"; 
    echo '____ Aborting ...'; 
    exit
} || {
    echo "____ Container '${lDerivedContainerName}' exists and is running"; 
}


fn__ExecCommandInContainer \
  ${lDerivedContainerName} \
  ${__GIT_CLIENT_USERNAME} \
  ${__GIT_CLIENT_SHELL} \
  "git config --global push.default current" \
    && echo "____ Updated remote .gitconfig" \
    || echo "____ Failed to opdated remote .gitconfig"


folderLines=$(grep '"folder": "vscode-remote' /mnt/c/Users/${USER}/AppData/Roaming/Code/storage.json) && STS=$? || STS=$?
if [[ ${STS} -ne ${__SUCCESS} ]]
then
  echo "_____ Cannot determine internal container id for use with vscode-remote"
  echo "_____ Start the container, if not running, use vscode to attach to the remote container and let it install what it wants"
  echo "_____ Keep the container running and re-run the script"
  exit ${__FAILED}
fi


folderUri=$(echo ${folderLines} | sed 's|^.*\"folder\": ||;s|,$||') && STS=$? || STS=$?
if [[ ${STS} -ne ${__SUCCESS} ]]; then
  echo "____ Error getting folderUri"
  echo "____ Have:"
  echo ${folderUri}
  echo "____ Investigate the issue then try getting Container Id again"
  exit ${__FAILED}
fi

# containerLongId=$(docker.exe inspect ${lDerivedContainerName} | grep Id | sed 's|^[[:space:]]*"Id": "||;s|".*$||') && STS=$? || STS=$?
# if [[ ${STS} -ne ${__SUCCESS} ]]
# then
#   echo "_____ Cannot determine internal container id for container '${lDerivedContainerName}' for use with vscode-remote"
#   echo "_____ Start the container, if not running, or create it, if it does not exist, and start it up"
#   echo "_____ Keep the container running and re-run the script"
#   exit ${__FAILED}
# fi

# echo "containerLongId:${containerLongId}"

# folderUri="vscode-remote://attached-container%2B${containerLongId}/home/gitclient"
# echo "folderUri:${folderUri}"


declare -r lrShellScriptPath="${__DEBMIN_HOME}/10_code_in_remote_container.sh"
echo "'/mnt/c/Program Files/Microsoft VS Code/Code.exe'" --folder-uri ${folderUri} > ${lrShellScriptPath}
chmod u+x ${lrShellScriptPath}


declare -r lrLinkDOSPath="${__DEBMIN_HOME_DOS}\\10 code in remote container.lnk"
fn__CreateWindowsShortcut \
  "${lrLinkDOSPath}" \
  "C:\Windows\System32\wsl.exe" \
  "%~dp0" \
  "${fn__CreateWindowsShortcut__RUN_MINIMISED}" \
  "C:\Program Files\Microsoft VS Code\Code.exe" \
  "${lrShellScriptPath}"


echo "____ Created/Updated script and windows shortcut to run VSCode with resources in the '${lDerivedContainerName}' container"

# '/mnt/c/Program Files/Microsoft VS Code/Code.exe' --folder-uri ${folderUri}
