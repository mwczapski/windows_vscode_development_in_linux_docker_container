#!/bin/bash
# #############################################
# The MIT License (MIT)
#
# Copyright © 2020 Michael Czapski
# #############################################

set -o pipefail
set -o errexit

traperr() {
  echo "ERROR: ------------------------------------------------"
  echo "ERROR: ${BASH_SOURCE[1]} at about ${BASH_LINENO[0]}"
  echo "ERROR: ------------------------------------------------"
}
set -o errtrace
trap traperr ERR

# common environment variable values and utility functions
# are sourced conditionally - if they were not sourced earlier
#
[[ ${libSourceMgmt} ]] || source ./libs/libSourceMgmt.sh "1.0.0"

[[ ${__env_GlobalConstants} ]] || source ./utils/__env_GlobalConstants.sh "1.0.0" || exit ${__EXECUTION_ERROR}

[[ ${fn__DockerGeneric} ]] || source ./utils/fn__DockerGeneric.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${__env_devcicd_net} ]] || source ./utils/__env_devcicd_net.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${__env_gitserverConstants} ]] || source ./utils/__env_gitserverConstants.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${__env_gitClientConstants} ]] || source ./utils/__env_gitClientConstants.sh "1.0.0" || exit ${__EXECUTION_ERROR}

[[ ${fn__WSLPathToDOSandWSDPaths} ]] || source ./utils/fn__WSLPathToDOSandWSDPaths.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${fn__GitserverGeneric} ]] || source ./utils/fn__GitserverGeneric.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${fn__UtilityGeneric} ]] || source ./utils/fn__UtilityGeneric.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${fn__SSHInContainerUtils} ]] || source ./utils/fn__SSHInContainerUtils.sh "1.0.0" || exit ${__EXECUTION_ERROR}

[[ ${fn__CreateWindowsShortcut} ]] || source ./utils/fn__CreateWindowsShortcut.sh "1.0.0" || exit ${__EXECUTION_ERROR}

[[ ${_02_create_git_client_container_utils} ]] || source ./02_create_git_client_container_utils.sh "1.0.0" || exit ${__EXECUTION_ERROR}



## ##################################################################################
## ##################################################################################
## expect directory structure like
## /mnt/x/dir1/dir2/..dirN/projectDir/_commonUtils/02_create_node13131_container
## and working directory /mnt/x/dir1/dir2/..dirN/projectDir/_commonUtils
## ##################################################################################
## ##################################################################################

declare -i _PROMPTS_TIMEOUT_SECS_=30


##========================================================================================
## get project directory and project name                                               ##
## /mnt/x/dir1/dir2/..dirn/projectDir/_commonUtils/02_create_git_client_container.sh    ##
##========================================================================================
#
declare __DEBMIN_HOME=$(pwd)
fn__GetProjectDirectory \
  "__DEBMIN_HOME" || {
    echo "${0}:${LINENO} must run from directory with name ${__SCRIPTS_DIRECTORY_NAME} and will use the name of its parent directory as project directory."
    exit ${__FAILED}
  }

# declare lProjectName="${__DEBMIN_HOME}/${__SCRIPTS_DIRECTORY_NAME}"
declare lProjectName="${__DEBMIN_HOME}"
fn__GetProjectName \
  "lProjectName" || {
    echo "${0}:${LINENO} must run from directory with name _commonUtils and will use the name of its parent directory as project directory."
    exit ${__FAILED}
  }


fn__SetEnvironmentVariables \
  "${__DEBMIN_HOME}" \
  "${__GIT_CLIENT_IMAGE_NAME}:${__GIT_CLIENT_IMAGE_VERSION}"  \
  "__DEBMIN_HOME" \
  "__DEBMIN_HOME_WSD" \
  "__DEBMIN_HOME_DOS" \
  "__DOCKER_COMPOSE_FILE_WLS" \
  "__DOCKER_COMPOSE_FILE_DOS" \
  "__CONTAINER_SOURCE_IMAGE_NAME" \
  "__GIT_CLIENT_CONTAINER_NAME" \
  "__GIT_CLIENT_HOST_NAME" \
  "__GIT_CLIENT_REMOTE_REPO_NAME" && STS=$? || STS=$?

  case ${STS} in
    ${__SUCCESS})
      ;;
    ${__INSUFFICIENT_ARGS_STS})
      echo "${__INSUFFICIENT_ARGS}"
      echo "____ ${LINENO}: Aborting ..."
      exit ${STS}
      ;;
    ${__EMPTY_ARGUMENT_NOT_ALLOWED})
      echo "_error Empty arguments not allowed"
      echo "____ ${LINENO}: Aborting ..."
      exit ${STS}
      ;;
    ${__INVALID_VALUE})
      echo "_error Argument has invalid value"
      echo "____ ${LINENO}: Aborting ..."
      exit ${STS}
      ;;
    ${__NO_SUCH_DIRECTORY})
      echo "_error script not running from '${__SCRIPTS_DIRECTORY_NAME}'"
      echo "____ ${LINENO}: Aborting ..."
      exit ${STS}
      ;;
  esac
echo "____ Set environment variables"; 


##========================================================================================
## private git server integration support will be omitted by default                    ##
## command line argument "-g yes" is required to enable it                              ##
## this implies that the provate git repository exists                                  ##
## and its details were configured in __env_gitserverConstants.sh                       ##
##========================================================================================
#
if fn_IncludePrivateGitServerSupport "${*}" 
then
  __INCLUDE_PRIVATE_GIT_SERVER_SUPPORT=true
  echo "____ Will include support for private git server integration"

  ##========================================================================================
  ## ask if user wants to create a repo                                                   ##
  ## if yes, ask for name offering default and an opportunity to change                   ##
  ## if not - set the flag to not do it                                                   ##
  ##========================================================================================
  fn__ConfirmYN "Create remote git repository if it does not exist? " && _CREATE_REMOTE_GIT_REPO_=${__YES} || _CREATE_REMOTE_GIT_REPO_=${__NO}
  if [[ ${_CREATE_REMOTE_GIT_REPO_} -eq ${__YES} ]]
  then
    fn__GetRemoteGitRepoName \
      ${__GIT_CLIENT_REMOTE_REPO_NAME}  \
      "__GIT_CLIENT_REMOTE_REPO_NAME" && STS=$? || STS=$?
    if [[ ${STS} -eq ${__SUCCESS} ]]
    then
      echo "____ Will use '${__GIT_CLIENT_REMOTE_REPO_NAME}' as the name of the remote git repository which to create"
    else
      _CREATE_REMOTE_GIT_REPO_=${__NO}
      echo "____ Will not create remote git repository"
    fi
  fi

else
  __INCLUDE_PRIVATE_GIT_SERVER_SUPPORT=false
  echo "____ Will NOT include support for private git server integration"
  echo "____ To include this support invoke the script with '-g yes' command line argument "
fi



fn__ConfirmYN "Project Directory is ${__DEBMIN_HOME}, Project Name is '${lProjectName}' - Is this correct?" && true || {
  echo -e "____ Aborting ...\n"
  exit ${__FAILED}
}


cd ${__DEBMIN_HOME}






fn__GetClientContainerName  \
  "__DEBMIN_HOME" \
  "__GIT_CLIENT_CONTAINER_NAME" && STS=$? || STS=$?

  if [[ ${STS} -ne ${__SUCCESS} ]]
  then
    echo "____ Failed to choose container name."
    echo "____ Aborting ..."
    exit ${__FAILED}
  fi
echo "____ Using '${__GIT_CLIENT_CONTAINER_NAME}' as Container Name and Host Name"

__GIT_CLIENT_HOST_NAME=${__GIT_CLIENT_CONTAINER_NAME}



fn__ConfirmYN "Create Windows Shortcuts?" && _CREATE_WINDOWS_SHORTCUTS_=${__YES} || _CREATE_WINDOWS_SHORTCUTS_=${__NO}
echo "____ Will $([[ ${_CREATE_WINDOWS_SHORTCUTS_} == ${__NO} ]] && echo "NOT ")create windows shortcuts"


fn__CreateDockerComposeFile \
  "${__GIT_CLIENT_CONTAINER_NAME}"  \
  "${__GIT_CLIENT_HOST_NAME}"  \
  "${__GIT_CLIENT_USERNAME}"  \
  "${__DEVCICD_NET}"  \
  "${__CONTAINER_SOURCE_IMAGE_NAME}"  \
  "${__DEBMIN_HOME_WSD}/${__GIT_CLIENT_CONTAINER_NAME}/backups:${__GIT_CLIENT_GUEST_HOME}/backups" \
  "${__DOCKER_COMPOSE_FILE_WLS}"
echo "____ Created '${__DOCKER_COMPOSE_FILE_WLS}'"; 


fn__ImageExists \
  "${__CONTAINER_SOURCE_IMAGE_NAME}" \
  && echo "____ Image '${__CONTAINER_SOURCE_IMAGE_NAME}' exist" \
  || {
    echo "repo: ${__DOCKER_REPOSITORY_HOST}/${__GIT_CLIENT_IMAGE_NAME}:${__GIT_CLIENT_IMAGE_VERSION}"

    fn__PullImageFromRemoteRepository   \
      ${__DOCKER_REPOSITORY_HOST}  \
      ${__GIT_CLIENT_IMAGE_NAME} \
      ${__GIT_CLIENT_IMAGE_VERSION} \
        && echo "____ Image '${__DOCKER_REPOSITORY_HOST}/${__GIT_CLIENT_IMAGE_NAME}:${__GIT_CLIENT_IMAGE_VERSION}' pulled from remote docker repository" \
        || {
          echo "____ Cannot find image '${__CONTAINER_SOURCE_IMAGE_NAME}' ['${__DOCKER_REPOSITORY_HOST}/${__GIT_CLIENT_IMAGE_NAME}:${__GIT_CLIENT_IMAGE_VERSION}']" 
          echo "____ Aborting script execution ..." 
          exit ${__FAILED}
        }
  }


fn__ContainerExists \
  ${__GIT_CLIENT_CONTAINER_NAME} \
    && STS=${__YES} \
    || STS=${__NO}

if [[ $STS -eq ${__YES} ]]; then

  fn__ContainerIsRunning ${__GIT_CLIENT_CONTAINER_NAME} && STS=${__YES} || STS=${__NO}
  if [[ $STS -eq ${__YES} ]]; then
    echo "____ Container '${__GIT_CLIENT_CONTAINER_NAME}' exist and is running - nothing needs doing - exiting"; 
    exit ${__SUCCESS}

  else

    fn__StartContainer ${__GIT_CLIENT_CONTAINER_NAME} && STS=${__YES} || STS=${__NO}
    if [[ $STS -eq ${__DONE} ]]; then
        echo "____ Container '${__GIT_CLIENT_CONTAINER_NAME}' started"; 
    else
        echo "____ Failed to start container '${__GIT_CLIENT_CONTAINER_NAME}' - investigate..."; 
        exit ${__FAILED}
    fi
  fi

else
  
  fn_DockerComposeUpDetached "${__DOCKER_COMPOSE_FILE_DOS}" "${__GIT_CLIENT_CONTAINER_NAME}" && STS=${__DONE} || STS=${__FAILED}
  if [[ $STS -eq ${__DONE} ]]; then
    echo "____ Container' ${__GIT_CLIENT_CONTAINER_NAME}' started"; 
  else
    echo "____ Failed to start container '${__GIT_CLIENT_CONTAINER_NAME}' - investigate"; 
    exit ${__FAILED}
  fi
fi


if [[ ${__INCLUDE_PRIVATE_GIT_SERVER_SUPPORT} == true ]]
then

  declare __GIT_CLIENT_ID_RSA_PUB_=""
  fn__GenerateSSHKeyPairInClientContainer \
    ${__GIT_CLIENT_CONTAINER_NAME} \
    ${__GIT_CLIENT_USERNAME} \
    ${__GIT_CLIENT_SHELL} \
    "__GIT_CLIENT_ID_RSA_PUB_" \
      && STS=${__DONE} \
      || STS=${__FAILED}
  echo "____ Generated '${__GIT_CLIENT_GUEST_HOME}' ssh keypair"; 


  fn__IntroduceRemoteClientToServerWithPublicKey \
    ${__GIT_CLIENT_CONTAINER_NAME} \
    ${__GIT_CLIENT_USERNAME} \
    "${__GIT_CLIENT_ID_RSA_PUB_}"  \
    ${__GITSERVER_CONTAINER_NAME} \
    ${__GIT_USERNAME} \
    ${__GITSERVER_SHELL} \
      && STS=${__DONE} \
      || STS=${__FAILED}
  echo "____ Added '${__GIT_CLIENT_GUEST_HOME}' public key to '${__GITSERVER_HOST_NAME}' ~/.ssh/authorised_keys"; 


  fn__AddGITServerToLocalKnown_hostsAndTestSshAccess \
    ${__GIT_CLIENT_CONTAINER_NAME} \
    ${__GIT_CLIENT_USERNAME} \
    ${__GIT_CLIENT_SHELL} \
      && STS=${__DONE} \
      || STS=${__FAILED}
  echo "____ Added '${__GITSERVER_HOST_NAME}' to '${__GIT_CLIENT_GUEST_HOME}' \${HOME}/.ssh/known_hosts"; 


  # client's public key must be in git server's authorised_keys file
  #
  fn__AddClientPublicKeyToServerAuthorisedKeysStore \
    "${__GIT_CLIENT_ID_RSA_PUB_}"  \
    ${__GITSERVER_CONTAINER_NAME} \
    ${__GIT_USERNAME} \
    ${__GITSERVER_SHELL} \
      && STS=${__DONE} \
      || STS=${__FAILED}
  echo "____ Added '${__GIT_CLIENT_CONTAINER_NAME}' to '${__GIT_CLIENT_GUEST_HOME}' \${HOME}/.ssh/known_hosts"; 


  # if repo already exists we can't create a new one with the same name
  #
  fn__DoesRepoAlreadyExist \
    ${__GIT_CLIENT_REMOTE_REPO_NAME}  \
    ${__GITSERVER_CONTAINER_NAME} \
    ${__GIT_USERNAME} \
    ${__GITSERVER_SHELL} && STS=$? || STS=$?

    if [[ ${STS} -eq ${__YES} ]]
    then
      echo "____ Git Repository '${__GIT_CLIENT_REMOTE_REPO_NAME}' already exists - will skip creation steps"
    elif [[ ${STS} -eq ${__EXECUTION_ERROR} ]]
    then
      echo "____ Failed to determine whether Git Repository '${__GIT_CLIENT_REMOTE_REPO_NAME}' already exists - will skip creation steps"
    else
      fn__CreateNewClientGitRepositoryOnRemote \
        ${__GIT_CLIENT_REMOTE_REPO_NAME}  \
        ${__GITSERVER_CONTAINER_NAME} \
        ${__GIT_USERNAME} \
        ${__GITSERVER_SHELL} \
        ${__GITSERVER_REPOS_ROOT} && STS=$? || STS=$?

      if [[ ${STS} -eq ${__DONE} ]]
      then
        fn__DoesRepoAlreadyExist \
          ${__GIT_CLIENT_REMOTE_REPO_NAME}  \
          ${__GITSERVER_CONTAINER_NAME} \
          ${__GIT_USERNAME} \
          ${__GITSERVER_SHELL} && STS=$? || STS=$?

        if [[ ${STS} -eq ${__YES} ]]
        then
          echo "____ Created remote repository '${__GIT_CLIENT_REMOTE_REPO_NAME}'"
        else
          echo "____ Failed to create remote repository '${__GIT_CLIENT_REMOTE_REPO_NAME}' - investigate"
        fi
      else
        echo "____ Failed to create remote repository '${__GIT_CLIENT_REMOTE_REPO_NAME}'"
      fi
    fi

  # fn__TestLocalAndRemoteGitReposOperation \
  #   ${__GIT_CLIENT_CONTAINER_NAME} \
  #   ${__GIT_CLIENT_USERNAME} \
  #   ${__GIT_CLIENT_SHELL} \
  #   ${__GIT_CLIENT_GUEST_HOME} \
  #   ${__GITSERVER_HOST_NAME} \
  #   ${__GIT_USERNAME} \
  #   ${__GITSERVER_REPOS_ROOT} \
  #   ${__GIT_CLIENT_REMOTE_REPO_NAME} \
  #     && echo "____ Local and Remote Git repository test completed" \
  #     || echo "____ Local and Remote Git repository test failed - investigate!!!"
fi


[[ ${_CREATE_WINDOWS_SHORTCUTS_} -eq ${__YES} ]] && {
  fn__CreateWindowsShortcutsForShellInContainer \
    "${__GIT_CLIENT_CONTAINER_NAME}" \
    "${__DEBMIN_HOME_DOS}" \
    "${__GIT_CLIENT_SHELL}" \
    "${__DOCKER_COMPOSE_FILE_DOS}" && STS=${__DONE} || STS=${__FAILED}
  echo "____ Created Windows Shortcuts"; 
}


echo "____ ${0} Done"
