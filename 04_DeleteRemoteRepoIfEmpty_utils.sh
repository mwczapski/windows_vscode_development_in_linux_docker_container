#!/bin/bash
# #############################################
# The MIT License (MIT)
#
# Copyright © 2020 Michael Czapski
# #############################################

[[ ${__env_GlobalConstants} ]] || source ./utils/__env_GlobalConstants.sh "1.0.0" || exit ${__FAILED}

declare -u _04_DeleteRemoteRepoIfEmpty_utils="1.0.0"
fn__SourcedVersionOK "${0}" "${1:-0.0.0}" "${_04_DeleteRemoteRepoIfEmpty_utils}" || exit ${__FAILED}

[[ ${fn__UtilityGeneric} ]] || { source ./utils/fn__UtilityGeneric.sh "1.0.1" || exit ${__FAILED}; }





:<<-'------------Function_Usage_Note-------------------------------'
  Usage:
    fn__ForceRemoveRemoteRepo \
      "${*}"
  Returns:
    ${__EXECUTION_ERROR}
    ${__NO} if command line argument is not provided or it's value does not match the expectation
    ${__YES} if command line argument is provided and matches the expectation
  Example:
    fn__ForceRemoveRemoteRepo "${*}" && echo "Yes, force" || echo "No, don't force"
------------Function_Usage_Note-------------------------------
fn__ForceRemoveRemoteRepo() {
  local -r prCmdArguments="${1}"
  local -r lrOptionValue=":f:"    # provide a single option, possible prefixed with : and possibly suffixed with : if option value is required
  local lOutputString=""
  fn__GetOptionValue "${lrOptionValue}" "${prCmdArguments}" "lOutputString" && STS=${?} || STS=${?}

  case ${STS} in
    ${__EXECUTION_ERROR} | ${__EMPTY_ARGUMENT_NOT_ALLOWED})
      echo "Execution error - check logic" >&2
      return ${__EXECUTION_ERROR};
      ;;
    ${__NO})
      return ${__NO}
      ;;
    *)
      # only want the first letter of the string following the -f flag
      # and only care aboiut Y - everything else is a ${__NO}
      local -r _OPT_VAL_=${lrefOutputString^^}
      [[ ${_OPT_VAL_:0:1} == "Y" ]] \
        && return ${__YES} \
        || return ${__NO}
      ;;
  esac
}


:<<-'------------Function_Usage_Note-------------------------------'
  Usage:
    fn__InputIsValid 
      "${pClientGitRemoteRepoName}"
      ${pCanonicalClientGitRemoteRepoName} 
      ${pGiterverRemoteRepoNameMaxLen}
  Returns:
    ${__DONE}
    ${__FAILED}
------------Function_Usage_Note-------------------------------
function fn__InputIsValid() {
  local -r lUsage='
  Usage: 
    fn__InputIsValid 
      "${pClientGitRemoteRepoName}"
      ${pCanonicalClientGitRemoteRepoName} 
      ${pGiterverRemoteRepoNameMaxLen}
        && STS=${__DONE} 
        || STS=${__FAILED}
        '
  [[ $# -lt 3 || "${0^^}" == "HELP" ]] && {
    echo -e "____ Insufficient number of arguments $@\n${lUsage}"
    return ${__FAILED}
  }
 
  local -r pClientGitRemoteRepoName=${1?"${lUsage}"}
  local -r pCanonicalClientGitRemoteRepoName=${2?"${lUsage}"}
  local -r pGiterverRemoteRepoNameMaxLen=${3?"${lUsage}"}

  [[ ${#pCanonicalClientGitRemoteRepoName} -lt 2 ]] && {
    echo "____ Git repository name '${pClientGitRemoteRepoName}' translated to '${pCanonicalClientGitRemoteRepoName}'"
    echo "____ Git repository name must be at least 2 characters long"
    return ${__FAILED}
  }
  [[ ${#pCanonicalClientGitRemoteRepoName} -gt ${pGiterverRemoteRepoNameMaxLen} ]] && {
    echo "____ Final Git repository name '${pCanonicalClientGitRemoteRepoName}' is longer than the maximum of ${pGiterverRemoteRepoNameMaxLen} characters"
    echo "____ Git repository name must be no longer than ${pGiterverRemoteRepoNameMaxLen} characters"
    return ${__FAILED}
  }

  return ${__DONE}
}
