
# #############################################
# The MIT License (MIT)
#
# Copyright © 2020 Michael Czapski
# #############################################

[[ ${__env_GlobalConstants} ]] || source ./utils/__env_GlobalConstants.sh "1.0.0" || exit ${__EXECUTION_ERROR}

declare -u __env_gitClientConstants="1.0.0"
fn__SourcedVersionOK "${0}" "${1:-0.0.0}" "${__env_gitClientConstants}" || exit ${__EXECUTION_ERROR}

[[ ${__env_devcicd_net} ]] || source ./utils/__env_devcicd_net.sh "1.0.0" || exit ${__EXECUTION_ERROR}
[[ ${__env_gitserverConstants} ]] || source ./utils/__env_gitserverConstants.sh "1.0.0" || exit ${__EXECUTION_ERROR}


readonly __GIT_CLIENT_USERNAME="gitclient"
readonly __GIT_CLIENT_NAME="gitclient"
readonly __GIT_CLIENT_SHELL="/bin/bash"
readonly __GIT_CLIENT_SHELL_GLOBAL_PROFILE="/etc/profile"
readonly __GIT_CLIENT_SHELL_PROFILE=".bash_profile"
readonly __GIT_CLIENT_IMAGE_NAME="gitclient"
readonly __GIT_CLIENT_IMAGE_VERSION="1.0.0"
declare  __GIT_CLIENT_HOST_NAME="gitclient"
declare  __GIT_CLIENT_CONTAINER_NAME="gitclient"
readonly __GIT_CLIENT_GUEST_HOME="/home/${__GIT_CLIENT_USERNAME}"
declare  __GIT_CLIENT_REMOTE_REPO_NAME="gitclient"
