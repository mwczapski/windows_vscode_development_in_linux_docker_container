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

[[ ${libSourceMgmt} ]] || source ./libs/libSourceMgmt.sh "1.0.0"

[[ ${__env_GlobalConstants} ]] || source ./utils/__env_GlobalConstants.sh "1.0.0" || exit ${__EXECUTION_ERROR}

# common environment variable values and utility functions
#
[[ ${fn__DockerGeneric} ]] || source ./utils/fn__DockerGeneric.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${__env_devcicd_net} ]] || source ./utils/__env_devcicd_net.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${__env_gitserverConstants} ]] || source ./utils/__env_gitserverConstants.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${__env_gitClientConstants} ]] || source ./utils/__env_gitClientConstants.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${fn__WSLPathToDOSandWSDPaths} ]] || source ./utils/fn__WSLPathToDOSandWSDPaths.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${fn__UtilityGeneric} ]] || source ./utils/fn__UtilityGeneric.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${fn__GitserverGeneric} ]] || source ./utils/fn__GitserverGeneric.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${fn__CreateWindowsShortcut} ]] || source ./utils/fn__CreateWindowsShortcut.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${_02_create_git_client_container_utils} ]] || source ./02_create_git_client_container_utils.sh "1.0.0" || exit ${__EXECUTION_ERROR}



# functions specific to this script - separated to facilitate  unit testing 
#
[[ ${_01_create_git_client_baseline_image_utils} ]] || source ./01_create_git_client_baseline_image_utils.sh "1.0.0" || exit ${__EXECUTION_ERROR}


## ##################################################################################
## ##################################################################################
## 
## ##################################################################################
## ##################################################################################

# is there a command line argument that asks for the image to be uploaded ot the remote docker repository?


# confirm working directory and push image to remote repository
#
if [[ "$(echo $(basename $(pwd)))" != "${__SCRIPTS_DIRECTORY_NAME}" ]]
then
  echo "____ Script '${0}' is expected to be located in, and run from the directory named '${__SCRIPTS_DIRECTORY_NAME}' "
  echo "____ Aborting ..."
  exit ${__FAILED}
fi


__DEBMIN_HOME=$(pwd)
 
 fn__SetEnvironmentVariables \
  "${__SCRIPTS_DIRECTORY_NAME}" \
  "${__GIT_CLIENT_IMAGE_NAME}"  \
  "${__GITSERVER_SHELL_GLOBAL_PROFILE}"  \
  "__DEBMIN_HOME"  \
  "__DEBMIN_HOME_DOS"  \
  "__DEBMIN_HOME_WSD" \
  "__DOCKERFILE_PATH"  \
  "__REMOVE_CONTAINER_ON_STOP"  \
  "__NEEDS_REBUILDING" ## && STS=${__SUCCESS} || STS=${__FAILED} # let it abort if failed and investigate
echo "____ Set environment variables" 


fn__ImageExists \
  "${__GIT_CLIENT_IMAGE_NAME}:${__GIT_CLIENT_IMAGE_VERSION}" && __IMAGE_EXISTS=${__YES} || __IMAGE_EXISTS=${__NO}
[[ ${__IMAGE_EXISTS} -eq ${__YES} ]]  \
  && {
    echo "____ Image '${__GIT_CLIENT_IMAGE_NAME}:${__GIT_CLIENT_IMAGE_VERSION}' already exists - aborting"
    exit ${__FAILED}
  } \
  || {
    echo "____ Image '${__GIT_CLIENT_IMAGE_NAME}:${__GIT_CLIENT_IMAGE_VERSION}' does not exist"
    __REBUILD_IMAGE=${__YES}
  }


fn__ConfirmYN "Artifacts location will be '${__DEBMIN_HOME}' - Is this correct?" && true || {
  echo "____ Aborting ..."
  exit ${__NO}
}
echo "____ Artifacts location confirmed as '${__DEBMIN_HOME}'"



fn__ConfirmYN "Push of the image to the remote Docker repository?" && STS=$? || STS=$?
readonly __PUSH_TO_REMOTE_DOCKER_REPO=${STS}
echo "____ Push of the image to the remote Docker repository has $([[ ${__PUSH_TO_REMOTE_DOCKER_REPO} -eq ${__NO} ]] && echo "NOT ")been requested."

cd ${__DEBMIN_HOME}

fn__Create_docker_entry_point_file \
  ${__DEBMIN_HOME} \
  ${__GIT_CLIENT_SHELL} ## && STS=${__SUCCESS} || STS=${__FAILED} # let it fail 
echo "____ Created docker-entrypoint.sh" 


fn__CreateDockerfile \
  ${__DOCKERFILE_PATH} \
  ${__DEBMIN_SOURCE_IMAGE_NAME} \
  ${__GIT_CLIENT_USERNAME} \
  ${__GIT_CLIENT_SHELL} \
  ${__GIT_CLIENT_SHELL_PROFILE} \
  ${__GIT_CLIENT_SHELL_GLOBAL_PROFILE} \
  ${__GIT_CLIENT_GUEST_HOME} \
  ${__GITSERVER_REPOS_ROOT} \
  ${__TZ_PATH} \
  ${__TZ_NAME} && __NEEDS_REBUILDING=$? || __NEEDS_REBUILDING=$?
echo "____ Created Dockerfile: '${__DOCKERFILE_PATH}'" 


fn__ImageExists \
  "${__GIT_CLIENT_IMAGE_NAME}:${__GIT_CLIENT_IMAGE_VERSION}" && __IMAGE_EXISTS=${__YES} || __IMAGE_EXISTS=${__NO}
[[ ${__IMAGE_EXISTS} -eq ${__YES} ]]  \
  && {
    echo "____ Image '${__GIT_CLIENT_IMAGE_NAME}:${__GIT_CLIENT_IMAGE_VERSION}' exists"
    __REBUILD_IMAGE=${__NO}
  } \
  || {
    echo "____ Image '${__GIT_CLIENT_IMAGE_NAME}:${__GIT_CLIENT_IMAGE_VERSION}' does not exist"
    __REBUILD_IMAGE=${__YES}
  }

if [[ ${__REBUILD_IMAGE} -eq ${__YES} ]]; then
  fn__BuildImage  \
    ${__REBUILD_IMAGE} \
    ${__GIT_CLIENT_IMAGE_NAME} \
    ${__GIT_CLIENT_IMAGE_VERSION} \
    ${__DEBMIN_HOME_DOS}/Dockerfile.${__GIT_CLIENT_IMAGE_NAME} \
    ${__DEVCICD_NET} ## && STS=${__SUCCESS} || STS=${__FAILED} # let it abort if failed
  echo "____ Image '${__GIT_CLIENT_IMAGE_NAME}:${__GIT_CLIENT_IMAGE_VERSION}' built"
fi


# Returns:
#   __SUCCESS and the chosen name in populated lClientContainerName
#   __FAILED if there were insufficient arguments
#   Script abort if all opportunities to choose a container name were exhausted
declare lClientContainerName="${__GIT_CLIENT_CONTAINER_NAME}"
fn__GetClientContainerName \
  "__DEBMIN_HOME"  \
  "lClientContainerName" && STS=$? || STS=$?

test ${STS} -eq ${__SUCCESS} || {
    echo "____ ${STS}:${lClientContainerName}"
  } && {
    echo "____ ${STS}:${lClientContainerName}"
  }


fn__ContainerExists \
  ${lClientContainerName} \
    && STS=${__YES} \
    || STS=${__NO}

if [[ $STS -eq ${__YES} ]]; then

  echo "____ Container '${lClientContainerName}' exists - will stop and remove"

  fn__StopAndRemoveContainer  \
    ${lClientContainerName} \
      && STS=${__YES} \
      || STS=${__NO}

  echo "____ Container '${lClientContainerName}' stopped and removed"
else
  echo "____ Container '${lClientContainerName}' does not exist"
fi


fn__RunContainerDetached \
  ${__GIT_CLIENT_IMAGE_NAME} \
  ${__GIT_CLIENT_IMAGE_VERSION} \
  ${lClientContainerName} \
  ${__GIT_CLIENT_HOST_NAME} \
  ${__REMOVE_CONTAINER_ON_STOP} \
  ${__EMPTY} \
  ${__DEVCICD_NET} \
    && STS=${__DONE} || \
    STS=${__FAILED}
   

[[ $STS -eq ${__DONE} ]] && echo "____ Container '${lClientContainerName}'started"

if [[ $STS -eq ${__DONE} ]]; then

  fn__CommitChangesStopContainerAndSaveImage   \
    "${lClientContainerName}" \
    "${__GIT_CLIENT_IMAGE_NAME}" \
    "${__GIT_CLIENT_IMAGE_VERSION}"
  echo "____ Commited changes to '${__GIT_CLIENT_IMAGE_NAME}:${__GIT_CLIENT_IMAGE_VERSION}' and Stopped container '${__CONTAINER_NAME}'"

  if [[ ${__PUSH_TO_REMOTE_DOCKER_REPO} == ${__YES} ]]; then

    fn__PushImageToRemoteRepository   \
      "${__DOCKER_REPOSITORY_HOST}"  \
      "${__GIT_CLIENT_IMAGE_NAME}" \
      "${__GIT_CLIENT_IMAGE_VERSION}"

    echo "____ Image tagged and pushed to repository as '${__DOCKER_REPOSITORY_HOST}/${__GIT_CLIENT_IMAGE_NAME}:${__GIT_CLIENT_IMAGE_VERSION}'" 
  else
    echo "____ On user request on user request image '${__GIT_CLIENT_IMAGE_NAME}:${__GIT_CLIENT_IMAGE_VERSION}' has NOT been pushed to Docker repository '${__DOCKER_REPOSITORY_HOST}'" 
  fi
else
  ${__INDUCE_ERROR}
fi

echo "Done..."
