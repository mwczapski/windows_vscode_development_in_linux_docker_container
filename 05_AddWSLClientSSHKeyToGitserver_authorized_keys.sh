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

[[ ${__env_GlobalConstants} ]] || source ./utils/__env_GlobalConstants.sh "1.0.0" || exit ${__FAILED};

# common environment variable values and utility functions
#
[[ ${__env_gitserverConstants} ]] || source ./utils/__env_gitserverConstants.sh "1.0.0" || exit ${__FAILED}
[[ ${fn__SSHInContainerUtils} ]] || source ./utils/fn__SSHInContainerUtils.sh "1.0.0" || exit ${__FAILED}


## ##########################################################################################
## ##########################################################################################
## 
## ##########################################################################################
## ##########################################################################################

declare __GIT_CLIENT_ID_RSA_PUB_=""

fn__GetSSHIdRsaPubKeyFromLocalWSLHost \
  "__GIT_CLIENT_ID_RSA_PUB_" && STS=${__DONE} || STS=${__FAILED}

if [[ ${STS} -eq ${__FAILED} ]]
then
  echo "!!!! ${0}:${LINENO}: fn__GetSSHIdRsaPubKeyFromLocalWSLHost returned error '${__GIT_CLIENT_ID_RSA_PUB_}'"
  echo "!!!! ${0}:${LINENO}: Aborting ..."
  exit ${__FAILED}
fi

fn__IntroduceLocalWSLClientToServerWithPublicKey \
  "${__GIT_CLIENT_ID_RSA_PUB_}"  \
  "${__GITSERVER_CONTAINER_NAME}" \
  "${__GIT_USERNAME}" \
  "${__GITSERVER_SHELL}" && STS=${__DONE} || STS=${__FAILED}

if [[ ${STS} -eq ${__FAILED} ]]
then
  echo "!!!! ${0}:${LINENO}: fn__IntroduceLocalWSLClientToServerWithPublicKey returned error '${__GIT_CLIENT_ID_RSA_PUB_}'"
  echo "!!!! ${0}:${LINENO}: Error exit"
  exit ${__FAILED}
fi

echo "____ Local WSL Client SSH Public Key added to authorized_hosts '${__GIT_USERNAME}@${__GITSERVER_CONTAINER_NAME}'..."