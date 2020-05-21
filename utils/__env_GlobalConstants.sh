
# #############################################
# The MIT License (MIT)
#
# Copyright © 2020 Michael Czapski
# #############################################

declare -r __env_GlobalConstants="1.0.0"

declare __ENABLE_SOURCING_TRACE=${__ENABLE_SOURCING_TRACE:-false}

readonly __ZERO__=0
readonly __TRUE=${__ZERO__}
readonly __YES=${__ZERO__}
readonly __SUCCESS=${__ZERO__}
readonly __DONE=${__ZERO__}
readonly __THE_SAME=${__ZERO__}

readonly __ONE__=1
readonly __FALSE=${__ONE__}
readonly __NO=${__ONE__}
readonly __FAILED=${__ONE__}
readonly __DIFFERENT=${__ONE__}


readonly __IGNORE_ERROR=true
readonly __INDUCE_ERROR=false

readonly __EMPTY="EMPTY"

readonly __SCRIPTS_DIRECTORY_NAME='_commonUtils'
readonly __DEBMIN_SOURCE_IMAGE_NAME='bitnami/minideb:jessie'

readonly __MAX_CONTAIMER_NAME_LENGTH=40
readonly __IDENTIFIER_MAX_LEN=40

readonly __TZ_PATH="Australia/Sydney"
readonly __TZ_NAME="Australia/Sydney"

readonly __INSUFFICIENT_ARGS="____ Insufficient number of arguments"
readonly __INSUFFICIENT_ARGS_STS=200
readonly __EMPTY_ARGUMENT_NOT_ALLOWED=201
readonly __NO_SUCH_DIRECTORY=203
readonly __INVALID_VALUE=204

declare _PROMPTS_TIMEOUT_SECS_=${_PROMPTS_TIMEOUT_SECS_:-15.5}

savedPS4=${PS4}
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'


# from https://unix.stackexchange.com/questions/80476/bash-accessing-function-call-stack-in-trap-function
#
function fn__CallStackXX () {
  local T="${T}  "
  local STACK=
  i=${#FUNCNAME[@]}
  ((--i))
  printf "${T}Function call stack ( command.function() ) ...\n" >&2
  T="${T}  "
  while (( $i >= 0 ))
  do
    STACK+="${T}${BASH_SOURCE[$i]}.${FUNCNAME[$i]}()\n"
    T="${T}  "
    ((--i))
  done
  printf "$STACK" >&2
}


function fn__CallStack () {
  local -i i=${#FUNCNAME[@]}

  if [[ ${i} -gt 2 ]]
  then
    local -i x=$((${i} - 2))
    echo "${BASH_SOURCE[${x}]}.${FUNCNAME[${x}]}()"
  fi

  # local T="${T}  "
  # local STACK=
  
  # ((--i))
  # printf "${T}Function call stack ( command.function() ) ...\n" >&2
  # T="${T}  "
  # while (( $i >= 0 ))
  # do
  #   STACK+="${T}${BASH_SOURCE[$i]}.${FUNCNAME[$i]}()\n"
  #   T="${T}  "
  #   ((--i))
  # done
  # printf "$STACK" >&2
}



:<<-'------------Function_Usage_Note-------------------------------'
  Usage:
    expectedVersion=${1:-"0.5.1"}
    ___env_GlobalConstants="1.0.0"

    fn__SourcedVersionOK "${expectedVersion}" "${___env_GlobalConstants}" \
      && echo "expectedVersion ${expectedVersion} is less than or equal to actual version ${___env_GlobalConstants}" \
      || echo "expectedVersion ${expectedVersion} is greater than actual version ${___env_GlobalConstants}"

  Returns:
    ${__YES}
    ${__NO}
------------Function_Usage_Note-------------------------------
fn__SourcedVersionOK() {
  local -r pCallerName=${1?}
  local -r pExpected="${2?}"
  local -r pActual="${3?}"

  local lExpectedNumStr=""
  local lActualNumStr=""
  local -i liExpectedNum=0
  local -i liActualNum=0

  local num
  for num in ${pExpected//./ }; do printf -v aPart "%04d" $num && lExpectedNumStr+=${aPart}; done
  for num in ${pActual//./ }; do printf -v aPart "%04d" $num && lActualNumStr+=${aPart}; done

  printf -v liExpectedNum "%d" $((10#${lExpectedNumStr}))
  printf -v liActualNum "%d" $((10#${lActualNumStr}))

  local lCaller
  local -ir i=${#FUNCNAME[@]}
  if [[ ${i} -gt 2 ]]
  then
    local -i x=$((${i} - 2))
    lImmadiateCaller="${BASH_SOURCE[${x}]}.${FUNCNAME[${x}]}"
    lImmadiateCaller=${lImmadiateCaller//.source/}
    # lImmadiateCaller=${lImmadiateCaller//??utils?/ }
  fi

  if [[ ${liExpectedNum} -le ${liActualNum} ]]
  then
    [[ ${__ENABLE_SOURCING_TRACE} == true ]] \
      && echo "${pCallerName}:${lImmadiateCaller} Expected Version ${pExpected} is <= to actual version ${pActual}" >&2
    return ${__YES}
  else 
    echo "${pCallerName}:${lImmadiateCaller} Expected Version ${pExpected} is > than actual version ${pActual} - Please review the issue ..." >&2
    return ${__NO}
  fi
}

fn__SourcedVersionOK "${0}" "${1:-0.0.0}" "${__env_GlobalConstants}" || exit ${__EXECUTION_ERROR}
