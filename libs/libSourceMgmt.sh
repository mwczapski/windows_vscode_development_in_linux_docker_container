

# #############################################
# The MIT License (MIT)
#
# Copyright © 2020 Michael Czapski
# #############################################

declare -r libSourceMgmt="1.0.0"

[[ ${__EXECUTION_ERROR} ]] || readonly __EXECUTION_ERROR=11
[[ ${__YES} ]] || readonly __YES=0
[[ ${__NO} ]] || readonly __NO=1


declare PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

declare __ENABLE_SOURCING_TRACE=false
declare __ENABLE_FUNCTION_STACK_TRACE=false


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
  local -r pCallerLineNo=${2?}
  local -r pExpected="${3?}"
  local -r pActual="${4?}"

  local lExpectedNumStr=""
  local lActualNumStr=""
  local -i liExpectedNum=0
  local -i liActualNum=0

  local num
  for num in ${pExpected//./ }; do printf -v aPart "%04d" $num && lExpectedNumStr+=${aPart}; done
  for num in ${pActual//./ }; do printf -v aPart "%04d" $num && lActualNumStr+=${aPart}; done

  printf -v liExpectedNum "%d" $((10#${lExpectedNumStr}))
  printf -v liActualNum "%d" $((10#${lActualNumStr}))

  local lImmadiateCaller=""
  local -ir i=${#FUNCNAME[@]}
  if [[ ${i} -gt 3 ]]
  then
    local -i x=$((${i} - 2))
    lImmadiateCaller="${BASH_SOURCE[${x}]}.${FUNCNAME[${x}]}"
    lImmadiateCaller=${lImmadiateCaller//.source/}
  fi

  if [[ ${liExpectedNum} -le ${liActualNum} ]]
  then
    test ${__ENABLE_SOURCING_TRACE} == true \
      && { 
        echo "${pCallerName}:${pCallerLineNo} Expected Version ${pExpected} is <= to actual version ${pActual}" >&2
        test ${__ENABLE_FUNCTION_STACK_TRACE} == true && fn__FunctionCallStack >&2
      }
    return ${__YES}
  else 
    echo "${pCallerName}:${pCallerLineNo} Expected Version ${pExpected} is > than actual version ${pActual} - Please review the issue ..." >&2
    # test ${__ENABLE_FUNCTION_STACK_TRACE} == true && \
    fn__FunctionCallStack >&2
    return ${__NO}
  fi
}


# from https://unix.stackexchange.com/questions/80476/bash-accessing-function-call-stack-in-trap-function
#
function fn__FunctionCallStack () {
  local T="${T}  "
  local STACK=
  local i=${#FUNCNAME[@]}
  ((--i))
  printf "${T}Function call stack ( command.function() ) ...\n" >&2
  T="${T}  "
  while (( $i >= 0 ))
  do
    STACK+="${T}${BASH_SOURCE[$i]}.${FUNCNAME[$i]}()\n"
    T="${T}  "
    ((--i))
  done
  printf "$STACK\n" >&2
}


function fn__CallStack () {
  local -i i=${#FUNCNAME[@]}

  if [[ ${i} -gt 2 ]]
  then
    local -i x=$((${i} - 2))
    echo "${BASH_SOURCE[${x}]}.${FUNCNAME[${x}]}()"
  fi
}

fn__SourcedVersionOK "${0}" "${LINENO}" "${1:-0.0.0}" "${libSourceMgmt}" || exit ${__EXECUTION_ERROR}
