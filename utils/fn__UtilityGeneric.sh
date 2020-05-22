# #############################################
# The MIT License (MIT)
#
# Copyright © 2020 Michael Czapski
# #############################################

[[ ${__env_GlobalConstants} ]] || { source ./utils/__env_GlobalConstants.sh "1.0.0" || exit ${__FAILED}; }

declare -r fn__UtilityGeneric="1.0.1"
fn__SourcedVersionOK "${0}" "${LINENO}" "${1:-0.0.0}" "${fn__UtilityGeneric}" || exit ${__EXECUTION_ERROR}



:<<-'------------Function_Usage_Note-------------------------------'
fn__VariableMissingOrEmpty "${VarName}" && echo "Missing or Empty" || echo "Present and Valued"
------------Function_Usage_Note-------------------------------
function fn__VariableMissingOrEmpty() { 
  [[ -z "${1}" ]] ; 
}

:<<-'------------Function_Usage_Note-------------------------------'
fn__VariablePresentAndValued "${VarName}" && echo "Present and Valued" || echo "Missing or Empty" 
------------Function_Usage_Note-------------------------------
function fn__VariablePresentAndValued() { 
  [[ -n "${1}" ]] ; 
}



:<<-'------------Function_Usage_Note-------------------------------'
  Usage:
    fn__GetOptionValue \
      "${getoptsOptionsString}" \
      "${commandLineArgumentStrinfg}" \
      "CallersOutputStringName"
  Returns:
    ${__EXECUTION_ERROR} and emits error message to STDERR
    ${__YES} if command line argument is provided and the option argument
    ${__NO} if command line argument is not provided
    ${__EMPTY_ARGUMENT_NOT_ALLOWED} - 1st or 3rd argument is empty or missing
------------Function_Usage_Note-------------------------------
fn__GetOptionValue() {

  local -r prOptionsString="${1}"
  local -r prCmdArguments="${2}"
  local -r prOutputString=${3}

  fn__VariableMissingOrEmpty  ${1} 2>/dev/null && return ${__EMPTY_ARGUMENT_NOT_ALLOWED}
  fn__VariableMissingOrEmpty  ${3} 2>/dev/null && return ${__EMPTY_ARGUMENT_NOT_ALLOWED}

  local -n lrefOutputString=${prOutputString}

  # echo "${LINENO}:lrOptionsString:${prOptionsString}"
  # echo "${LINENO}:lrCmdArguments:${prCmdArguments}"
  # echo "${LINENO}:lrOutputString:${prOutputString}"

  test ${#prOptionsString} == 0 && return ${__EXECUTION_ERROR}
  test ${#prCmdArguments} == 0 && return ${__NO}
  test ${#prOutputString} == 0 && return ${__EXECUTION_ERROR}

  local -r lrOptionLetter=${prOptionsString//:/}

  local _ERROR_=false
  while getopts "${prOptionsString}" option ${prCmdArguments}
  do
    case ${option} in
      ${lrOptionLetter})
        # echo "-f was triggered, Parameter: ${OPTARG}" >&2
        # local -r _OPT_VAL_=${OPTARG^^}
        # lrefOutputString="${_OPT_VAL_:0:1}"
        lrefOutputString="${OPTARG}"
        return ${__YES}
        # break
        ;;
      \?)
        # ignore options that are not
        # echo "Invalid option: -${OPTARG}" >&2
        # _ERROR_=true
        # return ${__EXECUTION_ERROR}
        # break
        ;;
      :)
        echo "Option -${OPTARG} requires an argument." >&2
        _ERROR_=true
        return ${__EXECUTION_ERROR}
        # break
        ;;
    esac
  done

  [[ ${_ERROR_} == true ]] && return ${__EXECUTION_ERROR}

}


:<<-'------------Function_Usage_Note-------------------------------'
  Usage:
    fn__RefVariableExists \
      "outerScopeVariableName"
  Returns:
    ${__YES}
    ${__NO}
  Expects in environment:
    Constants from __env_GlobalConstants
------------Function_Usage_Note-------------------------------
fn__RefVariableExists() {
  local -r p1=${1}
  local -n p2=${p1} 2>/dev/null && return ${__YES} || return ${__NO}
}



:<<-'------------Function_Usage_Note-------------------------------'
  Usage:
    fn__ConfirmYN \
      "${prompt}"
  Returns:
    ${__YES}
    ${__NO}
  Expects in environment:
    Constants from __env_GlobalConstants
------------Function_Usage_Note-------------------------------
function fn__ConfirmYN() {
  local -r lUsage='
  Usage:
    fn__ConfirmYN \
      "${prompt}"
  Returns:
    ${__YES}
    ${__NO}
  '
  # this picks up missing arguments
  #
  [[ $# -lt 1 || "${0^^}" == "HELP" ]] && {
    echo -e "${__INSUFFICIENT_ARGS}\n${lUsage}"
    return ${__FAILED}
  }

  pPrompt=${1?"No prmpt"}
  read -t ${_PROMPTS_TIMEOUT_SECS_} -p "_??_ ${pPrompt} (y/N) " -i 'No' -r RESP || echo
  RESP=${RESP^^}; RESP=${RESP:0:1}
  [[ $RESP == 'Y' ]] && return ${__YES} || return ${__NO}
}


:<<-'------------Function_Usage_Note-------------------------------'
  Usage:
    fn__GetValidIdentifierInput \
      "inPromptString"  \ # in
      "inMaxLength"  \    # in
      "inTimeoutSecs" \   # in
      "outValidValue"     # in/out
  Returns:
    ${__SUCCESS} and string value in outValidValue outer context variable
    ${__FAILED}
  Expects in environment:
    Constants from __env_GlobalConstants
  Notes:
    Arguments are names of variabes in the outer scope.
    'local -n "${XXXX}"' attempts to create a local reference variable
    that give direct access to the value of the corresponding variable
    in the outer scope. The 'outValidValue' is then used to set the value
    in the corresponding outer scope variable and onsequently
    to return a string value as well as completion status to the caller.
    Not also that the outer scope in/out variablemust have a globally
    unique name in the outer scope. If not, the value will not be set.
------------Function_Usage_Note-------------------------------
function fn__GetValidIdentifierInput() {
  local -r lUsage='
  Usage:
    fn__GetValidIdentifierInput \
      "inPromptString"  \
      "inMaxLength"  \
      "inTimeoutSecs" \
      "outValidValue"
    '
  # this picks up missing arguments
  #
  [[ $# -lt 4 || "${0^^}" == "HELP" ]] && {
    echo -e "${__INSUFFICIENT_ARGS}\n${lUsage}"
    return ${__FAILED}
  }

  # this picks up arguments which are empty strings
  #
  [[ -n "${1}" ]] 2>/dev/null || { echo "1st Argument value, '${1}', is invalid"; return ${__FAILED} ; }
  [[ -n "${2}" ]] 2>/dev/null || { echo "2nd Argument value, '${2}', is invalid"; return ${__FAILED} ; }
  [[ -n "${3}" ]] 2>/dev/null || { echo "3rd Argument value, '${3}', is invalid"; return ${__FAILED} ; }
  [[ -n "${4}" ]] 2>/dev/null || { echo "4th Argument value, '${4}', is invalid"; return ${__FAILED} ; }

  # name reference variables
  #
  local -n lXinPromptString="${1}"
  local -n lXinMaxLength=${2}
  local -n lXinTimeoutSecs=${3}
  local -n lXoutValidValue="${4}"

  # read data - if value is pumped into the function, for example with:
  # fn__GetValidIdentifierInput "inPromptString" "inMaxLength" "inTimeoutSecs" "outValidValue" <<<"${testValue}"
  # then read will read it and not wait for input
  # this is great for testing
  #
  local lReaData="${lXoutValidValue}"
  if [[ ! -n "${lReaData}" ]]
  then
    read -t ${lXinTimeoutSecs} -p "${lXinPromptString}" -n $((lXinMaxLength*2)) lReaData && STS=$? || STS=$?
    if [[ ${STS} -ne ${__SUCCESS} ]]  # timeout - 142
    then
      lReaData="${lXoutValidValue}"
    else
      if [[ ! -n "${lReaData}" ]]
      then
        lReaData="${lXoutValidValue}"
      fi
    fi
  else
    read -t ${lXinTimeoutSecs} -p "${lXinPromptString}" -n $((lXinMaxLength*2)) -e -i "${lXoutValidValue}" lReaData && STS=$? || STS=$?
    if [[ ${STS} -ne ${__SUCCESS} ]]  # timeout - 142
    then
      lReaData="${lXoutValidValue}"
    else
      if [[ ! -n "${lReaData}" ]]
      then
        lReaData="${lXoutValidValue}"
      fi
    fi
  fi

  # no data provided either via keyboard entry, pipe or in lXoutValidValue as default
  #
  [[ ${lReaData} ]] || {
    lXoutValidValue=""
    return ${__FAILED}
  }

  # remove all non-compliant characters from the string - see fn__SanitizeInputIdentifier for details
  #
  lReaData=$(fn__SanitizeInputIdentifier "${lReaData}") || {
    lXoutValidValue=""
    return ${__FAILED}
  }

  # make sure the string is cut down to at most the expected length
  #
  lReaData=${lReaData:0:${lXinMaxLength}}

  test ${#lReaData} -eq 0 && return ${__FAILED}

  # set return value
  #
  lXoutValidValue="${lReaData}"

  return ${__SUCCESS}
}


function fn__FileSameButForDate() {
  local lUsage='
      Usage:
        fn__FileSameButForDate
          ${__FIRST_FILE_PATH}
          ${__SECOND_FILE_PATH}
      '
  [[ $# -lt  2 || ${0^^} == "HELP" ]] && {
    echo -e "${__INSUFFICIENT_ARGS}${lUsage}"
    return ${__FAILED}
  }

  local pFile1=${1?"${lUsage}"}
  local pFile2=${2?"${lUsage}"}

  diff -swq \
    <(cat ${pFile1} | sed 's|[0-9]\{8\}_[0-9]\{6\}|DDDDDDDD_TTTTTT|g') \
    <(cat ${pFile2} | sed 's|[0-9]\{8\}_[0-9]\{6\}|DDDDDDDD_TTTTTT|g') \
    >/dev/null \
      && return ${__THE_SAME} \
      || return ${__DIFFERENT}
}


:<<-'------------Function_Usage_Note-------------------------------'
  Usage:
    fn__IsValidRegEx \
      ${ShellRegEx} \
  Returns:
    ${__SUCCESS}
    ${__FAILED}
  Expects in environment:
    Constants from __env_GlobalConstants
------------Function_Usage_Note-------------------------------
function fn__IsValidRegEx() {
  [[ $# -lt 1 ]] && {
    echo "____ Requires a shell regex to validate"
    return ${__FAILED}
  }
  local pRegEx="$@"
  [[ ${#pRegEx} -ge 3 ]] || {
    echo "____ Alleged regular expression '${pRegEx}' must be at least 3 characters long"
    return ${__FAILED}
  }
  [[ "${pRegEx:0:1}" == "[" ]] && [[ "${pRegEx:${#pRegEx}-1}" == "]" ]] \
    || {
      echo "____ Alleged regular expression '${pRegEx}' must start with [ and end with ]"
      return ${__FAILED}
    }

  echo "VALID"
  return ${__SUCCESS}
}


function fn__SanitizeInput() {
  [[ $# -lt 1 ]] && { echo "____ Requires shell regex to use to determine valid characters and eliminate all that do not match"; return ${__FAILED} ; }
  [[ $# -lt 2 ]] && { echo "____ Require string to sanitize"; return ${__FAILED} ; }
  local pRegEx="${@}"
  pRegEx="${pRegEx%%]*}]"
  local lMsg=$(fn__IsValidRegEx "${pRegEx}")
  [[ ${lMsg} != "VALID" ]] && {
    echo ${lMsg}
    return ${__FAILED}
  }
  local pInput="${@}"
  local -r lLenRegEx=${#pRegEx}
  pInput="${pInput:${lLenRegEx}}"
  local -r lRegEx="${pRegEx:0:1}^${pRegEx:1}"  # regex must be inverted to eliminate all character except these which match the original expression
  local lOutput="${pInput//${lRegEx}/}"
  local lOutputLen=${#pInput}
  echo ${lOutput}
  return ${__SUCCESS}
}


function fn__SanitizeInputAlphaNum() {
  [[ $# -lt 1 ]] && { echo "____ Require string which to sanitize"; return ${__FAILED} ; }
  local pInput="$@"
  local pOutput=$(fn__SanitizeInput "[a-zA-Z0-9]" ${pInput}) && STS=${__SUCCESS}|| STS=${__FAILED}
  echo ${pOutput}
  return ${STS}
}


function fn__SanitizeInputIdentifier() {
  [[ $# -lt 1 ]] && { echo "____ Require string which to sanitize"; return ${__FAILED} ; }
  local pInput="$@"
  local pOutput=$(fn__SanitizeInput "[a-zA-Z0-9_]" ${pInput}) && STS=$?|| STS=$?
  echo ${pOutput}
  return ${STS}
}


function fn__SanitizeInputAlpha() {
  [[ $# -lt 1 ]] && { echo "____ Require string which to sanitize"; return ${__FAILED} ; }
  local pInput="$@"
  local pOutput=$(fn__SanitizeInput "[a-zA-Z]" ${pInput}) && STS=$?|| STS=$?
  echo ${pOutput}
  return ${STS}
}


function fn__SanitizeInputNumeric() {
  [[ $# -lt 1 ]] && { echo "____ Require string which to sanitize"; return ${__FAILED} ; }
  local pInput="$@"
  local pOutput=$(fn__SanitizeInput "[0-9]" ${pInput}) && STS=$?|| STS=$?
  echo ${pOutput}
  return ${STS}
}
