#!/bin/bash

# #########################################################################################
# 1.0.0   20200420    MCz Initial
# 1.0.1   20200422    MCz refactored - reduced container names
# 1.0.3   20200426    MCz copied, renamed and redeveloped to just set up an existing container
# #########################################################################################

set -o pipefail
set -o errexit

traperr() {
  echo "ERROR: -------------------------------------------------"
  echo "ERROR: ${BASH_SOURCE[1]} at about ${BASH_LINENO[0]}"
  echo "ERROR: -------------------------------------------------"
}
set -o errtrace
trap traperr ERR

[[ ${libSourceMgmt} ]] || source ./libs/libSourceMgmt.sh "1.0.0"
[[ ${__env_GlobalConstants} ]] || source ./utils/__env_GlobalConstants.sh "1.0.0" || exit ${__FAILED}

declare -u _06_set_up_container_for_remote_dev="1.0.0"

# common environment variable values and utility functions
#
[[ ${fn__DockerGeneric} ]] || source ./utils/fn__DockerGeneric.sh "1.0.0" || exit ${__FAILED}
[[ ${__env_devcicd_net} ]] || source ./utils/__env_devcicd_net.sh "1.0.0" || exit ${__FAILED}
[[ ${fn__WSLPathToDOSandWSDPaths} ]] || source ./utils/fn__WSLPathToDOSandWSDPaths.sh "1.0.0" || exit ${__FAILED}
[[ ${fn__UtilityGeneric} ]] || source ./utils/fn__UtilityGeneric.sh "1.0.0" || exit ${__FAILED}
[[ ${fn__CreateWindowsShortcut} ]] || source ./utils/fn__CreateWindowsShortcut.sh "1.0.0" || exit ${__FAILED}
[[ ${_02_create_git_client_container_utils} ]] || source ./02_create_git_client_container_utils.sh "1.0.0" || exit ${__FAILED}
[[ ${_06_set_up_container_for_remote_dev_utils} ]] || source ./06_set_up_container_for_remote_dev_utils.sh "1.0.0" || exit ${__FAILED}



## ###############################################################################################
## ##################################################################################
## ##################################################################################
## expect directory structure like
## /mnt/x/dir1/dir2/..dirN/projectDir/_commonUtils/06_set_up_container_for_remote_dev.sh
## and working directory /mnt/x/dir1/dir2/..dirN/projectDir/_commonUtils
## ##################################################################################
## ##################################################################################

# confirm project directory
# /mnt/x/dir1/dir2/..dirn/projectDir/_commonUtils/06_set_up_container_for_remote_dev.sh
#
__DEBMIN_HOME=$(pwd)
readonly __CWD_NAME=$(basename ${__DEBMIN_HOME})
[[ "${__CWD_NAME}" == "${__SCRIPTS_DIRECTORY_NAME}" ]] || {
  echo "${0} must run from directory with name _commonUtils and will use the name of its parent directory as project directory"
  exit ${__NO}
}


fn__SetEnvironmentVariables ## && STS=${__SUCCESS} || STS=${__FAILED} # let it fail 


fn__ConfirmYN "Artefact location will be '${__DEBMIN_HOME}' - Is this correct?" && true || {
  echo -e "____ Aborting ...\n"
  exit ${__NO}
}

fn__ContainerExists \
    "${__DEBMIN_PPROJECT_NAME}" && STS=0 || STS=1
[[ $STS -eq ${__NO} ]] && {
    echo "____ Container '${__DEBMIN_PPROJECT_NAME} 'does not exist or is not running!"; 
    echo '____ Aborting ...'; 
    exit
} || {
    echo "____ Container '${__DEBMIN_PPROJECT_NAME}' exists and is running"; 
}

fn_SetUpProjectDirectoryOwnership && {
    echo "____ Set up startup project directory in remote environment"; 
} || {
    echo "____ Failed to set up startup project directory in remote environment"; 
    echo "____ Investigate the issue..."; 
    exit ${__FAILED}
}


fnCreateDotGitignore \
  && {
    echo "____ Created .gitignore in remote environment"; 
  } || {
    echo "____ Failed to create .gitignore in remote environment"; 
    echo "____ Investigate the issue..."; 
    exit ${__FAILED}
  }

if fn_GitIntegrationIsEnabledInContainer 
then

  fnInitClientContainerGitEnvironment \
    && {
      echo "____ Initialised git repository in remote environment"; 
    } || {
      echo "____ Failed to initialise git repository in remote environment"; 
      echo "____ Investigate the issue..."; 
      exit ${__FAILED}
    }

else 
  echo "____ Git integration NOT enabled in the container"
fi

fn__CreateWindowsShortcutsForShellInContainer \
  "${__DEBMIN_PPROJECT_NAME}" \
  "${__DEBMIN_HOME_DOS}" \
  "${__DEBMIN_SHELL}" && STS=${__DONE} || STS=${__FAILED}

echo '____ Container set up'; 
