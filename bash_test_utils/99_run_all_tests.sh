#!/bin/bash

declare -r lrDoTestsScript=$(dirname ${0})/99_run_all_tests_do.sh

cat <<-EOF > ${lrDoTestsScript}
#!/bin/bash

# Generated on: $(date +%Y-%m-%d\ %H:%M:%S)
# find . -name \*_tests.sh -exec echo "_FORCE_RUNNING_ALL_TESTS_='YES' {}  | tee -a ${logFile}" \; | grep -v \${0} | grep -v '/_' >> \$(dirname \${0})/99_run_all_tests_do.sh

declare -r logFile="\$(dirname \${0})/99_run_all_tests.log"

>\${logFile}
EOF

find . -name \*_tests.sh -exec echo "_FORCE_RUNNING_ALL_TESTS_='YES' {} | tee -a \${logFile}" \; | grep -v ${0} | grep -v '/_' >> ${lrDoTestsScript}

cat <<-'EOF' >> ${lrDoTestsScript}

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

EOF


${lrDoTestsScript}