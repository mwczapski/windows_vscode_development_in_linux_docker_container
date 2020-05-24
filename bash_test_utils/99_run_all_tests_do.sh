#!/bin/bash

# Generated on: 2020-05-24 16:53:21
# find . -name \*_tests.sh -exec echo "_FORCE_RUNNING_ALL_TESTS_='YES' {}  | tee -a " \; | grep -v ${0} | grep -v '/_' >> $(dirname ${0})/99_run_all_tests_do.sh

declare -r logFile="$(dirname ${0})/99_run_all_tests.log"

>${logFile}
_FORCE_RUNNING_ALL_TESTS_='YES' ./02_create_git_client_container_tests.sh | tee -a ${logFile}
_FORCE_RUNNING_ALL_TESTS_='YES' ./utils/fn__GitserverGeneric_tests.sh | tee -a ${logFile}
_FORCE_RUNNING_ALL_TESTS_='YES' ./utils/fn__SSHInContainerUtils_tests.sh | tee -a ${logFile}
_FORCE_RUNNING_ALL_TESTS_='YES' ./utils/fn__UtilityGeneric_tests.sh | tee -a ${logFile}
_FORCE_RUNNING_ALL_TESTS_='YES' ./utils/fn__WSLPathToDOSandWSDPaths_tests.sh | tee -a ${logFile}

echo ""
echo "Test Run On $(date +%Y-%m-%d\ %H:%M:%S)"

echo ""
echo '    ' 'Test Suites'
grep 'INFO' ${logFile}

echo ""
sum=0
while read i ; do
  i=${i##____ Executed }
  i=${i%% tests}
  (( sum+=${i} ))
done < <(grep '____ Executed' ${logFile})
printf "____ %4d tests executed\n" ${sum}

sum=0
while read i ; do
  i=${i##____ }
  i=${i%% tests were successful}
  (( sum+=${i} ))
done < <(grep 'tests were successful' ${logFile})
printf "____ %4d tests successfull\n" ${sum}

sum=0
while read i ; do
  i=${i##____ }
  i=${i%% tests failed}
  (( sum+=${i} ))
done < <(grep 'tests failed' ${logFile})
printf "____ %4d tests failed\n" ${sum}

sum=$(grep 'Not running test for' ${logFile} | wc -l )
printf "____ %4d tests skipped\n" ${sum}

