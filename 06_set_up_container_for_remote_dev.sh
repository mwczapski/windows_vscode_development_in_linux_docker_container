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

declare -u _06_set_up_container_for_remote_dev="SOURCED"

# common environment variable values and utility functions
#
[[ ${__env_GlobalConstants} ]] || source ./utils/__env_GlobalConstants.sh
[[ ${fn__DockerGeneric} ]] || source ./utils/fn__DockerGeneric.sh
[[ ${__env_devcicd_net} ]] || source ./utils/__env_devcicd_net.sh
# [[ ${__env_gitserverConstants} ]] || source ./utils/__env_gitserverConstants.sh
[[ ${fn__WSLPathToDOSandWSDPaths} ]] || source ./utils/fn__WSLPathToDOSandWSDPaths.sh
[[ ${fn__UtilityGeneric} ]] || source ./utils/fn__UtilityGeneric.sh
# [[ ${fn__GitserverGeneric} ]] || source ./utils/fn__GitserverGeneric.sh
[[ ${fn__CreateWindowsShortcut} ]] || source ./utils/fn__CreateWindowsShortcut.sh
[[ ${_02_create_git_client_container_utils} ]] || source ./02_create_git_client_container_utils.sh

# functions specific to this script - separated to facilitate  unit testing 
#
# [[ ${_01_create_git_client_baseline_image_utils} ]] || source ./01_create_git_client_baseline_image_utils.sh



function fn__SetEnvironmentVariables() {

  # set environment
  #
  cd ${__DEBMIN_HOME}

  declare lProjectName="${__DEBMIN_HOME}"
  fn__GetProjectName \
     "lProjectName" || {
        echo "${0}:${LINENO} must run from directory with name _commonUtils and will use the name of its parent directory as project directory."
        return ${__FAILED}
  }
  __DEBMIN_PPROJECT_NAME="${lProjectName}"

  __DEBMIN_HOME=${__DEBMIN_HOME%%/${__SCRIPTS_DIRECTORY_NAME}} # strip _commonUtils
  __DEBMIN_HOME_DOS=$(fn__WSLPathToRealDosPath ${__DEBMIN_HOME})
  __DEBMIN_HOME_WSD=$(fn__WSLPathToWSDPath ${__DEBMIN_HOME})

  # reduce project name to no more than __MaxNameLen__ characters
  local -ri __MaxNameLen__=${__IDENTIFIER_MAX_LEN}
  local -ri nameLen=${#__DEBMIN_PPROJECT_NAME}
  local startPos=$((${nameLen}-${__MaxNameLen__})) 
  startPos=${startPos//-*/0} 
  __DEBMIN_PPROJECT_NAME=${__DEBMIN_PPROJECT_NAME:${startPos}}

  readonly __DEBMIN_USERNAME=gitclient
  readonly __DEBMIN_GUEST_HOME=/home/${__DEBMIN_USERNAME}

  readonly __DEBMIN_SHELL="/bin/bash"

  readonly __CONTAINER_NAME="${__DEBMIN_PPROJECT_NAME}"
  readonly __HOST_NAME="${__DEBMIN_PPROJECT_NAME}"

#   __PORT_MAPPINGS[0]=127.0.0.1:3101:3100/tcp
#   __PORT_MAPPINGS[1]=127.0.0.1:5001:5000/tcp
#   __PORT_MAPPINGS[2]=127.0.0.1:48080:8080/tcp

  readonly __GIT_REMOTE_REPO_NAME=${__DEBMIN_PPROJECT_NAME}

}

## ###############################################################################################
## local functions
## ###############################################################################################

function fn_SetUpProjectDirectoryOwnership() {
  lCommand="
    cd ${__DEBMIN_GUEST_HOME}
    chown -R ${__DEBMIN_USERNAME}:${__DEBMIN_USERNAME} ${__DEBMIN_GUEST_HOME}
  "
  fn__ExecCommandInContainer \
    ${__CONTAINER_NAME} \
    "root" \
    ${__GIT_CLIENT_SHELL} \
    "${lCommand}" \
      && STS=${__DONE} \
      || STS=${__FAILED}

  return ${STS}
}


function fnCreateDotGitignore() {
  lCommand="
    cat <<-EOF > ${__DEBMIN_GUEST_HOME}/.gitignore
# disallow what's below
_*
Downloads
*.tar.gz
*.7z
~*
*.tgz
*.zip
*.lnk
dist
logs
.vscode-server
out
.cache
/.pnp
.pnp.js
/coverage
/build
 
# local env files
.DS_Store
.env.local
.env.development.local
.env.test.local
.env.production.local
 
# Log files
npm-debug.log*
yarn-debug.log*
yarn-error.log*
 
# Editor directories and files
.vscode

# allow anything that starts with __env
!__env*
EOF
"
  fn__ExecCommandInContainer \
    ${__CONTAINER_NAME} \
    ${__DEBMIN_USERNAME} \
    ${__GIT_CLIENT_SHELL} \
    "${lCommand}" \
      && STS=${__DONE} \
      || STS=${__FAILED}

  return ${STS}
}


function fnInitClientContainerGitEnvironment() {
  local lCommand="
    cd ${__DEBMIN_GUEST_HOME}
    git init -q
    chown -R ${__DEBMIN_USERNAME}:${__DEBMIN_USERNAME} .git
    chmod -R g+s .git
"
  fn__ExecCommandInContainer \
    ${__CONTAINER_NAME} \
    "root" \
    ${__GIT_CLIENT_SHELL} \
    "${lCommand}" \
      && STS=${__DONE} \
      || STS=${__FAILED}

  test ${STS} -eq ${__FAILED} && return ${STS}

  lCommand="
    cd ${__DEBMIN_GUEST_HOME}
    git config --global core.editor nano
    git config --global user.name '${__DEBMIN_USERNAME}'
    git config --global user.email '${__DEBMIN_USERNAME}@${__HOST_NAME}'
    git remote add origin ssh://git@gitserver${__GITSERVER_REPOS_ROOT}/${__GIT_REMOTE_REPO_NAME}.git
    git add .
    git commit -m 'initial commit'
    # git config --list
  "
  fn__ExecCommandInContainer \
    ${__CONTAINER_NAME} \
    ${__DEBMIN_USERNAME} \
    ${__GIT_CLIENT_SHELL} \
    "${lCommand}" \
      && STS=${__DONE} \
      || STS=${__FAILED}

  return ${STS}
}


# function fnUpdateGITServerAuthorized_keys() {
#   echo "____ save original authorized_keys, and update authorized_keys";
#   pContainerName=${1?"Usage: $0 requires Value of __DEBMIN_PPROJECT_NAME and __GITSERVER_NAME as its arguments"}
#   pGITServerName=${2?"Usage: $0 requires Value of __DEBMIN_PPROJECT_NAME and __GITSERVER_NAME as its arguments"}
#   ${__DOCKER_EXE} container exec -itu git -w /home/git ${pGITServerName} ${__GITSERVER_SHELL} -c "
#   mv -v ~/.ssh/authorized_keys ~/.ssh/authorized_keys_previous
#   chmod 0600 ~/.ssh/authorized_keys_previous

#   test -e ~/.ssh/authorized_keys \
#   && cp -v ~/.ssh/authorized_keys ~/.ssh/authorized_keys_previous \
#   || touch ~/.ssh/authorized_keys ~/.ssh/authorized_keys_previous 

#     sed \"/${pContainerName}/d\" ~/.ssh/authorized_keys_previous > ~/.ssh/authorized_keys

#     cat /home/git/.ssh/${pContainerName}_id_rsa.pub >> ~/.ssh/authorized_keys

#     echo 'authorized_keys after append'
#     cat ~/.ssh/authorized_keys 
#     "
# }


# function fnAddGITServerToLocalKnown_hostsAndTestSshAccess() {
#     echo "____ add __GITSERVER ssh fingerprint to known_hosts and test access to git repository";
#     # https://www.techrepublic.com/article/how-to-easily-add-an-ssh-fingerprint-to-your-knownhosts-file-in-linux/
#     pContainerName=${1?"Usage: $0 requires Value of __DEBMIN_PPROJECT_NAME and __GITSERVER_NAME as its arguments"}
#     pGITServerName=${2?"Usage: $0 requires Value of __DEBMIN_PPROJECT_NAME and __GITSERVER_NAME as its arguments"}
# 	${__DOCKER_EXE}  exec -itu ${__DEBMIN_USERNAME} -w ${__DEBMIN_GUEST_HOME} ${pContainerName} ${__DEBMIN_SHELL} -c "
#         ssh-keyscan -H ${pGITServerName} >> ~/.ssh/known_hosts
#         ssh git@${pGITServerName} list && echo 'Can connect to the remote git repo' || echo 'Cannot connect to the remote git repo'
#         "
# }


# function fnPerformGitSetupOnHost() {
# # fnPerformGitSetupOnHost ${__DEBMIN_HOME} ${__GITSERVER_NAME} ${__GIT_REMOTE_REPO_NAME}

#     echo "____ initialise host git repository for this project";
#     local pDebminHome=${1?"Usage: $0 requires __DEBMIN_HOME, __DEBMIN_PPROJECT_NAME, __GITSERVER_NAME and __GIT_REMOTE_REPO_NAME as its arguments"}
#     local pGitServerName=${2?"Usage: $0 requires __DEBMIN_HOME, __DEBMIN_PPROJECT_NAME, __GITSERVER_NAME and __GIT_REMOTE_REPO_NAME as its arguments"}
#     local pGITServerRepoName=${3?"Usage: $0 requires __DEBMIN_HOME, __DEBMIN_PPROJECT_NAME, __GITSERVER_NAME and __GIT_REMOTE_REPO_NAME as its arguments"}

# # ${__DEBMIN_HOME}/dev is bind mounted in the container
# # certain operations are not permitted from within the container
# # they need to be performed on the host
# #
#     cd ${pDebminHome}/dev
#     rm -Rf .git
#     git init
#     git remote remove origin 2>/dev/null || true
#     git remote add origin ssh://git@${pGitServerName}/opt/gitrepos/${pGITServerRepoName}.git
#     cd -
# }


# function fnTestRemoteGitRepoOperation() {
#     #
#     # fnTestRemoteGitRepoOperation \
#     #     ${__DEBMIN_HOME} \
#     #     ${__DEBMIN_PPROJECT_NAME}  \
#     #     ${__GITSERVER_NAME} \
#     #     ${__GIT_REMOTE_REPO_NAME}
#     #
#     echo "____ test git repository operations";
#     local pContainerName=${1?"Usage: $0 requires __DEBMIN_HOME, __DEBMIN_PPROJECT_NAME, __GITSERVER_NAME and __GIT_REMOTE_REPO_NAME as its arguments"}
#     local pGitServerName=${2?"Usage: $0 requires __DEBMIN_HOME, __DEBMIN_PPROJECT_NAME, __GITSERVER_NAME and __GIT_REMOTE_REPO_NAME as its arguments"}
#     local pGITServerRepoName=${3?"Usage: $0 requires __DEBMIN_HOME, __DEBMIN_PPROJECT_NAME, __GITSERVER_NAME and __GIT_REMOTE_REPO_NAME as its arguments"}

#     # # ${__DEBMIN_HOME}/dev is bind mounted in the container
#     # # certain operations are not permitted from within the container
#     # # they need to be performed on the host
#     # #
#     # cd ${pDebminHome}/dev
#     # rm -Rvf .git
#     # git init
#     # git remote remove origin
#     # git remote add origin ssh://git@${pGitServerName}/opt/gitrepos/${pGITServerRepoName}.git
#     # cd -

# 	${__DOCKER_EXE}  exec -itu ${__DEBMIN_USERNAME} -w ${__DEBMIN_GUEST_HOME} ${pContainerName} ${__DEBMIN_SHELL} -c "
#         git add .
#         git commit -m 'create commit'
#         #git remote remove origin
#         #git remote add origin ssh://git@${pGitServerName}/opt/gitrepos/${pGITServerRepoName}.git
#         git remote -v show origin
#         git remote -v
#         git push origin master

#         mkdir -pv ../${pGITServerRepoName}2
#         cd ../${pGITServerRepoName}2
#         git init
#         git remote add origin ssh://git@${pGitServerName}/opt/gitrepos/${pGITServerRepoName}.git
#         git remote -v
#         git pull origin master
#         cd ..
#         rm -Rf ./${pGITServerRepoName}2
#         "
# }



fn__CreateWindowsShortcutsForShellInContainer() {
  [[ $# -lt  3 || "${0^^}" == "HELP" ]] && {
    echo '
Usage: 
  fn__CreateWindowsShortcutsForShellInContainer \
    "${__CONTAINER_NAME}" \
    "${__DEBMIN_HOME_DOS}" \
    "${__DEBMIN_SHELL}" && STS=${__DONE} || STS=${__FAILED}
'
    return ${__FAILED}
  }
 
  local -r pContainerName=${1?"Container Name to be assigned to the container"}
  local -r pHomeDosPath=${2?"Host Path, in DOS format, to write shortcuts to"}
  local -r pShellInContainer=${3?"Shell to use on connection to the container"}

  local lDockerComposeCommand=""
  local lARGS=""
  local lDockerContainerCommandLine=""

  # create windows shortcuts for shell in container

  lARGS="/c wsl -d Debian -- bash -lc \"docker.exe container exec -itu ${__DEBMIN_USERNAME} --workdir ${__DEBMIN_GUEST_HOME} ${pContainerName} ${pShellInContainer} -l\" || pause"
  fn__CreateWindowsShortcut \
    "${pHomeDosPath}\dcc exec -itu ${__DEBMIN_USERNAME} ${pContainerName}.lnk" \
    "C:\Windows\System32\cmd.exe" \
    "%~dp0" \
    "${fn__CreateWindowsShortcut__RUN_NORMAL_WINDOW}" \
    "%ProgramFiles%\Docker\Docker\resources\bin\docker.exe" \
    "${lARGS}"

  lARGS="/c wsl -d Debian -- bash -lc \"docker.exe container exec -itu root --workdir / ${pContainerName} ${pShellInContainer} -l\" || pause"
  fn__CreateWindowsShortcut \
    "${pHomeDosPath}\dcc exec -itu root ${pContainerName}.lnk" \
    "C:\Windows\System32\cmd.exe" \
    "%~dp0" \
    "${fn__CreateWindowsShortcut__RUN_NORMAL_WINDOW}" \
    "%ProgramFiles%\Docker\Docker\resources\bin\docker.exe" \
    "${lARGS}"

  lARGS="."
  fn__CreateWindowsShortcut \
    "${pHomeDosPath}\run Code here.lnk" \
    "C:\Program Files\Microsoft VS Code\Code.exe" \
    "%~dp0" \
    "${fn__CreateWindowsShortcut__RUN_MINIMISED}" \
    "%ProgramFiles%\Microsoft VS Code\Code.exe" \
    "${lARGS}"

  return ${__DONE}
}



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
[[ "${__CWD_NAME}" == "_commonUtils" ]] || {
  echo "${0} must run from directory with name _commonUtils and will use the name of its parent directory as project directory"
  exit ${__NO}
}


fn__SetEnvironmentVariables ## && STS=${__SUCCESS} || STS=${__FAILED} # let it fail 


fn__ConfirmYN "Artefact location will be ${__DEBMIN_HOME} - Is this correct?" && true || {
  echo -e "____ Aborting ...\n"
  exit ${__NO}
}


fn__ContainerExists \
    "${__DEBMIN_PPROJECT_NAME}" && STS=0 || STS=1
[[ $STS -eq ${__NO} ]] && {
    echo "____ Container ${__DEBMIN_PPROJECT_NAME} does not exist or is not running!"; 
    echo '____ Aborting ...'; 
    exit
} || {
    echo "____ Container ${__DEBMIN_PPROJECT_NAME} exists and is running"; 
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


fnInitClientContainerGitEnvironment \
  && {
    echo "____ Initialised git repository in remote environment"; 
  } || {
    echo "____ Failed to initialise git repository in remote environment"; 
    echo "____ Investigate the issue..."; 
    exit ${__FAILED}
  }


fn__CreateWindowsShortcutsForShellInContainer \
  "${__DEBMIN_PPROJECT_NAME}" \
  "${__DEBMIN_HOME_DOS}" \
  "${__DEBMIN_SHELL}" && STS=${__DONE} || STS=${__FAILED}

echo '____ Container set up'; 
