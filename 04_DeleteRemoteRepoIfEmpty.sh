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


[[ ${__env_GlobalConstants} ]] || source ./utils/__env_GlobalConstants.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${fn__DockerGeneric} ]] || source ./utils/fn__DockerGeneric.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${__env_devcicd_net} ]] || source ./utils/__env_devcicd_net.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${__env_gitserverConstants} ]] || source ./utils/__env_gitserverConstants.sh "1.0.0" || exit ${__EXECUTION_ERROR}

[[ ${fn__GitserverGeneric} ]] || source ./utils/fn__GitserverGeneric.sh "1.0.1" || exit ${__EXECUTION_ERROR}
[[ ${fn__UtilityGeneric} ]] || source ./utils/fn__UtilityGeneric.sh "1.0.1" || exit ${__EXECUTION_ERROR}
[[ ${_04_DeleteRemoteRepoIfEmpty_utils} ]] || source ./04_DeleteRemoteRepoIfEmpty_utils.sh "1.0.0" || exit ${__EXECUTION_ERROR}

[[ ${_02_create_git_client_container_utils} ]] || source ./02_create_git_client_container_utils.sh "1.0.0" || exit ${__EXECUTION_ERROR}

## ##########################################################################################
## ##########################################################################################
## 
## ##########################################################################################
## ##########################################################################################

# see if repo name has been provided as $1 - if yes, use it, if no use the default
#

# need remote repo name a which to dleete, if empty
#
# declare pClientGitRemoteRepoName=${1:-${__GITSERVER_REM_TEST_REPO_NAME}}

declare lCWDCumProjectName=$(pwd)
fn__GetProjectName \
  "lCWDCumProjectName" || {
    echo "${0}:${LINENO} must run from directory with name _commonUtils and will use the name of its parent directory as project directory."
    exit ${__FAILED}
  }

declare pClientGitRemoteRepoName=""
fn__GetRemoteGitRepoName \
  ${lCWDCumProjectName}  \
  "pClientGitRemoteRepoName" && STS=$? || STS=$?
if [[ ${STS} -eq ${__SUCCESS} ]]
then
  echo "____ Will use '${pClientGitRemoteRepoName}' as the name of the remote git repository which to delete"
else
  echo "____ Will not delete remote git repository"
  exit ${__NO}
fi


# validate repository name
#
lCanonicalClientGitRemoteRepoName=$( fn__SanitizeInputIdentifier ${pClientGitRemoteRepoName} )


fn__InputIsValid \
  "${pClientGitRemoteRepoName}" \
  ${lCanonicalClientGitRemoteRepoName} \
  ${__GITSERVER_REMOTE_REPO_NAME_MAX_LEN} || {
    echo "____ (${LINENO}) Aborting ..."
    exit ${__FAILED}
  }
echo "____ Input accepted as '${lCanonicalClientGitRemoteRepoName}'"


fn__IsSSHToRemoteServerAuthorised \
  ${__GITSERVER_CONTAINER_NAME} \
  ${__GIT_USERNAME} \
  ${__GIT_HOST_PORT} \
  ${__GITSERVER_SHELL} && STS=$? || STS=$?

if [[ $STS -eq ${__NO} ]]; then
  echo "____ Client not authorised to connect to the server - please contact server administrator"
  echo "____ (${LINENO}) Aborting ..."
  exit ${__FAILED}
fi
echo "____ Client authorised to interact with the server"


fn__DoesRepoAlreadyExist \
  ${lCanonicalClientGitRemoteRepoName}  \
  ${__GITSERVER_CONTAINER_NAME} \
  ${__GIT_USERNAME} \
  ${__GITSERVER_SHELL} && STS=$? || STS=$? # can be __NO or __EXECUTION_ERROR

  [[ ${STS} -eq ${__EXECUTION_ERROR} ]] && {
      echo "____ Failed to determine whether Git Repository '${lCanonicalClientGitRemoteRepoName}' already exists"
      exit ${__FAILED}
  }
  [[ ${STS} -eq ${__NO} ]] && {
      echo "____ Git Repository '${lCanonicalClientGitRemoteRepoName}' does not exists"
      exit ${__FAILED}
  }
echo "____ Repository '${lCanonicalCanonicalClientGitRemoteRepoName}' exists"
 

fn__IsRepositoryEmpty \
  ${__GITSERVER_REPOS_ROOT} \
  ${lCanonicalClientGitRemoteRepoName}  \
  ${__GITSERVER_CONTAINER_NAME} \
  ${__GIT_USERNAME} \
  ${__GITSERVER_SHELL} && STS=${__YES} || STS=${__NO}

if [[ $STS -eq ${__NO} ]]
then
  fn__ForceRemoveRemoteRepo "${*}" \
    && {
      echo "____ Repository '${lCanonicalClientGitRemoteRepoName}' is not empty - can't delete it using this method - please see server administrator"
      echo "____ (${LINENO}) Aborting ..."
      exit ${__FAILED}
    } || {
      echo "No, don't force" >/dev/null
    }
fi
echo "____ Repository '${lCanonicalClientGitRemoteRepoName}' will be deleted"

fn__DeleteRemoteRepository \
  ${lCanonicalClientGitRemoteRepoName}  \
  ${__GITSERVER_CONTAINER_NAME} \
  ${__GIT_USERNAME} \
  ${__GITSERVER_SHELL} \
  ${__GITSERVER_REPOS_ROOT} \
    && STS=${__DONE} \
    || STS=${__FAILED}

if [[ $STS -eq ${__FAILED} ]]
then
  echo "____ Failed to delete repository '${lCanonicalClientGitRemoteRepoName}' - please see server administrator"
  echo "____ (${LINENO}) Aborting ..."
  exit ${__FAILED}
fi

fn__DoesRepoAlreadyExist \
  ${lCanonicalClientGitRemoteRepoName}  \
  ${__GITSERVER_CONTAINER_NAME} \
  ${__GIT_USERNAME} \
  ${__GITSERVER_SHELL} && STS=$? || STS=$? # can be __NO or __EXECUTION_ERROR

  [[ ${STS} -eq ${__EXECUTION_ERROR} ]] && {
      echo "____ Failed to determine whether Git Repository '${lCanonicalClientGitRemoteRepoName}' still exists"
      exit ${__FAILED}
  }
  [[ ${STS} -eq ${__YES} ]] && {
      echo "____ Git Repository '${lCanonicalClientGitRemoteRepoName}' still exists - please see server administrator"
      exit ${__FAILED}
  }
echo "____ Repository '${lCanonicalClientGitRemoteRepoName}' deleted"

exit ${__DONE} 
