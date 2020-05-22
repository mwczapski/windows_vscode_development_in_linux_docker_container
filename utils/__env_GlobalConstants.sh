
# #############################################
# The MIT License (MIT)
#
# Copyright © 2020 Michael Czapski
# #############################################

[[ ${__ZERO__} ]] || readonly __ZERO__=0
[[ ${__ONE__} ]] || readonly __ONE__=1

[[ ${__EXECUTION_ERROR} ]] || readonly __EXECUTION_ERROR=11
[[ ${__YES} ]] || readonly __YES=${__ZERO__}
[[ ${__NO} ]] || readonly __NO=${__ONE__}

[[ ${libSourceMgmt} ]] || source ./libs/libSourceMgmt.sh "1.0.0" || exit ${__EXECUTION_ERROR}

declare -r __env_GlobalConstants="1.0.0"
fn__SourcedVersionOK "${0}" "${LINENO}" "${1:-0.0.0}" "${__env_GlobalConstants}" || exit ${__EXECUTION_ERROR}

# readonly __ZERO__=0
# readonly __YES=${__ZERO__}
readonly __TRUE=${__ZERO__}
readonly __SUCCESS=${__ZERO__}
readonly __DONE=${__ZERO__}
readonly __THE_SAME=${__ZERO__}

# readonly __ONE__=1
# readonly __NO=${__ONE__}
readonly __FALSE=${__ONE__}
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
