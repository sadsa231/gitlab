#!/usr/bin/env bash

function retrieve_tests_metadata() {
  mkdir -p $(dirname "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}") $(dirname "${FLAKY_RSPEC_SUITE_REPORT_PATH}") "${RSPEC_PROFILING_FOLDER_PATH}"

  if [[ ! -f "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" ]]; then
    curl --location -o "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" "https://gitlab-org.gitlab.io/gitlab/${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" ||
      echo "{}" > "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}"
  fi

  if [[ ! -f "${FLAKY_RSPEC_SUITE_REPORT_PATH}" ]]; then
    curl --location -o "${FLAKY_RSPEC_SUITE_REPORT_PATH}" "https://gitlab-org.gitlab.io/gitlab/${FLAKY_RSPEC_SUITE_REPORT_PATH}" ||
      echo "{}" > "${FLAKY_RSPEC_SUITE_REPORT_PATH}"
  fi
}

function update_tests_metadata() {
  local rspec_flaky_folder_path="$(dirname "${FLAKY_RSPEC_SUITE_REPORT_PATH}")/"
  local knapsack_folder_path="$(dirname "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}")/"

  echo "{}" > "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}"

  scripts/merge-reports "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" ${knapsack_folder_path}rspec*.json

  export FLAKY_RSPEC_GENERATE_REPORT="true"
  scripts/merge-reports "${FLAKY_RSPEC_SUITE_REPORT_PATH}" ${rspec_flaky_folder_path}all_*.json

  # Prune flaky tests that weren't flaky in the last 7 days, *after* updating the flaky tests detected
  # in this pipeline, so that first_flaky_at for tests that are still flaky is maintained.
  scripts/flaky_examples/prune-old-flaky-examples "${FLAKY_RSPEC_SUITE_REPORT_PATH}"

  if [[ "$CI_PIPELINE_SOURCE" == "schedule" ]]; then
    if [[ -n "$RSPEC_PROFILING_PGSSLKEY" ]]; then
      chmod 0600 $RSPEC_PROFILING_PGSSLKEY
    fi
    PGSSLMODE=$RSPEC_PROFILING_PGSSLMODE PGSSLROOTCERT=$RSPEC_PROFILING_PGSSLROOTCERT PGSSLCERT=$RSPEC_PROFILING_PGSSLCERT PGSSLKEY=$RSPEC_PROFILING_PGSSLKEY scripts/insert-rspec-profiling-data
  else
    echo "Not inserting profiling data as the pipeline is not a scheduled one."
  fi

  cleanup_individual_job_reports
}

function retrieve_tests_mapping() {
  mkdir -p $(dirname "$RSPEC_PACKED_TESTS_MAPPING_PATH")

  if [[ ! -f "${RSPEC_PACKED_TESTS_MAPPING_PATH}" ]]; then
    (curl --location  -o "${RSPEC_PACKED_TESTS_MAPPING_PATH}.gz" "https://gitlab-org.gitlab.io/gitlab/${RSPEC_PACKED_TESTS_MAPPING_PATH}.gz" && gzip -d "${RSPEC_PACKED_TESTS_MAPPING_PATH}.gz") || echo "{}" > "${RSPEC_PACKED_TESTS_MAPPING_PATH}"
  fi

  scripts/unpack-test-mapping "${RSPEC_PACKED_TESTS_MAPPING_PATH}" "${RSPEC_TESTS_MAPPING_PATH}"
}

function retrieve_frontend_fixtures_mapping() {
  mkdir -p $(dirname "$FRONTEND_FIXTURES_MAPPING_PATH")

  if [[ ! -f "${FRONTEND_FIXTURES_MAPPING_PATH}" ]]; then
    (curl --location  -o "${FRONTEND_FIXTURES_MAPPING_PATH}" "https://gitlab-org.gitlab.io/gitlab/${FRONTEND_FIXTURES_MAPPING_PATH}") || echo "{}" > "${FRONTEND_FIXTURES_MAPPING_PATH}"
  fi
}

function update_tests_mapping() {
  if ! crystalball_rspec_data_exists; then
    echo "No crystalball rspec data found."
    return 0
  fi

  scripts/generate-test-mapping "${RSPEC_TESTS_MAPPING_PATH}" crystalball/rspec*.yml
  scripts/pack-test-mapping "${RSPEC_TESTS_MAPPING_PATH}" "${RSPEC_PACKED_TESTS_MAPPING_PATH}"
  gzip "${RSPEC_PACKED_TESTS_MAPPING_PATH}"
  rm -f crystalball/rspec*.yml "${RSPEC_PACKED_TESTS_MAPPING_PATH}"
}

function crystalball_rspec_data_exists() {
  compgen -G "crystalball/rspec*.yml" >/dev/null
}

function retrieve_previous_failed_tests() {
  local directory_for_output_reports="${1}"
  local rspec_pg_regex="${2}"
  local rspec_ee_pg_regex="${3}"
  local pipeline_report_path="test_results/previous/test_reports.json"

  # Used to query merge requests. This variable reflects where the merge request has been created
  local target_project_path="${CI_MERGE_REQUEST_PROJECT_PATH}"
  local instance_url="${CI_SERVER_URL}"

  echo 'Attempting to build pipeline test report...'

  scripts/pipeline_test_report_builder.rb --instance-base-url "${instance_url}" --target-project "${target_project_path}" --mr-id "${CI_MERGE_REQUEST_IID}" --output-file-path "${pipeline_report_path}"

  echo 'Generating failed tests lists...'

  scripts/failed_tests.rb --previous-tests-report-path "${pipeline_report_path}" --output-directory "${directory_for_output_reports}" --rspec-pg-regex "${rspec_pg_regex}" --rspec-ee-pg-regex "${rspec_ee_pg_regex}"
}

function rspec_args() {
  local rspec_opts="${1}"
  local junit_report_file="${2:-${JUNIT_RESULT_FILE}}"

  echo "-Ispec -rspec_helper --color --failure-exit-code 1 --error-exit-code 2 --format documentation --format RspecJunitFormatter --out ${junit_report_file} ${rspec_opts}"
}

function rspec_simple_job() {
  export NO_KNAPSACK="1"

  local rspec_cmd="bin/rspec $(rspec_args "${1}" "${2}")"
  echoinfo "Running RSpec command: ${rspec_cmd}"

  eval "${rspec_cmd}"
}

function rspec_simple_job_with_retry () {
  local rspec_run_status=0

  rspec_simple_job "${1}" "${2}" || rspec_run_status=$?

  handle_retry_rspec_in_new_process $rspec_run_status
}

function rspec_db_library_code() {
  local db_files="spec/lib/gitlab/database/"

  rspec_simple_job_with_retry "-- ${db_files}"
}

function debug_rspec_variables() {
  echoinfo "SKIP_FLAKY_TESTS_AUTOMATICALLY: ${SKIP_FLAKY_TESTS_AUTOMATICALLY}"
  echoinfo "RETRY_FAILED_TESTS_IN_NEW_PROCESS: ${RETRY_FAILED_TESTS_IN_NEW_PROCESS}"

  echoinfo "KNAPSACK_GENERATE_REPORT: ${KNAPSACK_GENERATE_REPORT}"
  echoinfo "FLAKY_RSPEC_GENERATE_REPORT: ${FLAKY_RSPEC_GENERATE_REPORT}"

  echoinfo "KNAPSACK_TEST_FILE_PATTERN: ${KNAPSACK_TEST_FILE_PATTERN}"
  echoinfo "KNAPSACK_LOG_LEVEL: ${KNAPSACK_LOG_LEVEL}"
  echoinfo "KNAPSACK_REPORT_PATH: ${KNAPSACK_REPORT_PATH}"

  echoinfo "FLAKY_RSPEC_SUITE_REPORT_PATH: ${FLAKY_RSPEC_SUITE_REPORT_PATH}"
  echoinfo "FLAKY_RSPEC_REPORT_PATH: ${FLAKY_RSPEC_REPORT_PATH}"
  echoinfo "NEW_FLAKY_RSPEC_REPORT_PATH: ${NEW_FLAKY_RSPEC_REPORT_PATH}"
  echoinfo "SKIPPED_FLAKY_TESTS_REPORT_PATH: ${SKIPPED_FLAKY_TESTS_REPORT_PATH}"

  echoinfo "CRYSTALBALL: ${CRYSTALBALL}"
}

function handle_retry_rspec_in_new_process() {
  local rspec_run_status="${1}"

  if [[ $rspec_run_status -eq 2 ]]; then
    echoerr "Not retrying failing examples since there were errors happening outside of the RSpec examples!"
  elif [[ $rspec_run_status -eq 1 ]]; then
    # Experiment to retry failed examples in a new RSpec process: https://gitlab.com/gitlab-org/quality/team-tasks/-/issues/1148
    if [[ "${RETRY_FAILED_TESTS_IN_NEW_PROCESS}" == "true" ]]; then
      retry_failed_rspec_examples
      rspec_run_status=$?
    else
      echoerr "Not retrying failing examples since \$RETRY_FAILED_TESTS_IN_NEW_PROCESS != 'true'!"
    fi
  else
    echosuccess "No examples to retry, congrats!"
  fi

  exit $rspec_run_status
}

function rspec_paralellized_job() {
  read -ra job_name <<< "${CI_JOB_NAME}"
  local test_tool="${job_name[0]}"
  local test_level="${job_name[1]}"
  local report_name=$(echo "${CI_JOB_NAME}" | sed -E 's|[/ ]|_|g') # e.g. 'rspec unit pg12 1/24' would become 'rspec_unit_pg12_1_24'
  local rspec_opts="${1}"
  local spec_folder_prefixes=""
  local rspec_flaky_folder_path="$(dirname "${FLAKY_RSPEC_SUITE_REPORT_PATH}")/"
  local knapsack_folder_path="$(dirname "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}")/"
  local rspec_run_status=0

  if [[ "${test_tool}" =~ "-ee" ]]; then
    spec_folder_prefixes="'ee/'"
  fi

  if [[ "${test_tool}" =~ "-jh" ]]; then
    spec_folder_prefixes="'jh/'"
  fi

  if [[ "${test_tool}" =~ "-all" ]]; then
    spec_folder_prefixes="['', 'ee/', 'jh/']"
  fi

  export KNAPSACK_LOG_LEVEL="debug"
  export KNAPSACK_REPORT_PATH="${knapsack_folder_path}${report_name}_report.json"

  # There's a bug where artifacts are sometimes not downloaded. Since specs can run without the Knapsack report, we can
  # handle the missing artifact gracefully here. See https://gitlab.com/gitlab-org/gitlab/-/issues/212349.
  if [[ ! -f "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" ]]; then
    echo "{}" > "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}"
  fi

  cp "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}" "${KNAPSACK_REPORT_PATH}"

  export KNAPSACK_TEST_FILE_PATTERN="spec/{,**/}*_spec.rb"

  if [[ "${test_level}" != "foss-impact" ]]; then
    export KNAPSACK_TEST_FILE_PATTERN=$(ruby -r./tooling/quality/test_level.rb -e "puts Quality::TestLevel.new(${spec_folder_prefixes}).pattern(:${test_level})")
  fi

  export FLAKY_RSPEC_REPORT_PATH="${rspec_flaky_folder_path}all_${report_name}_report.json"
  export NEW_FLAKY_RSPEC_REPORT_PATH="${rspec_flaky_folder_path}new_${report_name}_report.json"
  export SKIPPED_FLAKY_TESTS_REPORT_PATH="${rspec_flaky_folder_path}skipped_flaky_tests_${report_name}_report.txt"

  if [[ -d "ee/" ]]; then
    export KNAPSACK_GENERATE_REPORT="true"
    export FLAKY_RSPEC_GENERATE_REPORT="true"

    if [[ ! -f $FLAKY_RSPEC_REPORT_PATH ]]; then
      echo "{}" > "${FLAKY_RSPEC_REPORT_PATH}"
    fi

    if [[ ! -f $NEW_FLAKY_RSPEC_REPORT_PATH ]]; then
      echo "{}" > "${NEW_FLAKY_RSPEC_REPORT_PATH}"
    fi
  fi

  debug_rspec_variables

  if [[ -n "${RSPEC_TESTS_MAPPING_ENABLED}" ]]; then
    tooling/bin/parallel_rspec --rspec_args "$(rspec_args "${rspec_opts}")" --filter "${RSPEC_TESTS_FILTER_FILE}" || rspec_run_status=$?
  else
    tooling/bin/parallel_rspec --rspec_args "$(rspec_args "${rspec_opts}")" || rspec_run_status=$?
  fi

  echoinfo "RSpec exited with ${rspec_run_status}."

  handle_retry_rspec_in_new_process $rspec_run_status
}

function retry_failed_rspec_examples() {
  local rspec_run_status=0

  # Sometimes the file isn't created or is empty. In that case we exit(1) ourselves, otherwise, RSpec would
  # not run any examples an exit successfully, actually hiding failed tests!
  if [[ ! -f "${RSPEC_LAST_RUN_RESULTS_FILE}" ]] || [[ ! -s "${RSPEC_LAST_RUN_RESULTS_FILE}" ]]; then
    exit 1
  fi

  # Keep track of the tests that are retried, later consolidated in a single file by the `rspec:flaky-tests-report` job
  local failed_examples=$(grep " failed" ${RSPEC_LAST_RUN_RESULTS_FILE})
  local report_name=$(echo "${CI_JOB_NAME}" | sed -E 's|[/ ]|_|g') # e.g. 'rspec unit pg12 1/24' would become 'rspec_unit_pg12_1_24'
  local rspec_flaky_folder_path="$(dirname "${FLAKY_RSPEC_SUITE_REPORT_PATH}")/"

  export RETRIED_TESTS_REPORT_PATH="${rspec_flaky_folder_path}retried_tests_${report_name}_report.txt"
  echoinfo "RETRIED_TESTS_REPORT_PATH: ${RETRIED_TESTS_REPORT_PATH}"

  echo "${CI_JOB_URL}" > "${RETRIED_TESTS_REPORT_PATH}"
  echo $failed_examples >> "${RETRIED_TESTS_REPORT_PATH}"

  echoinfo "Retrying the failing examples in a new RSpec process..."

  install_junit_merge_gem

  # Disable Crystalball on retry to not overwrite the existing report
  export CRYSTALBALL="false"

  # Disable simplecov so retried tests don't override test coverage report
  export SIMPLECOV=0

  local default_knapsack_pattern="{,ee/,jh/}spec/{,**/}*_spec.rb"
  local knapsack_test_file_pattern="${KNAPSACK_TEST_FILE_PATTERN:-$default_knapsack_pattern}"

  # Retry only the tests that failed on first try
  rspec_simple_job "--only-failures --pattern \"${knapsack_test_file_pattern}\"" "${JUNIT_RETRY_FILE}"
  rspec_run_status=$?

  # Merge the JUnit report from retry into the first-try report
  junit_merge "${JUNIT_RETRY_FILE}" "${JUNIT_RESULT_FILE}" --update-only

  if [[ $rspec_run_status -eq 0 ]]; then
    # The test is flaky because it succeeded after being retried.
    # Make the pipeline "pass with warnings" if the flaky test is part of this MR.
    warn_on_successfully_retried_test
  fi

  exit $rspec_run_status
}

# Exit with an allowed_failure exit code if the flaky test was part of the MR that triggered this pipeline
function warn_on_successfully_retried_test {
  local changed_files=$(git diff --name-only $CI_MERGE_REQUEST_TARGET_BRANCH_SHA | grep spec)
  echoinfo "A test was flaky and succeeded after being retried. Checking to see if flaky test is part of this MR..."

  if [[ "$changed_files" == "" ]]; then
    echoinfo "Flaky test was not part of this MR."
    return
  fi

  while read changed_file
  do
    # include the root path in the regexp to eliminate false positives
    changed_file="^\./$changed_file"

    if grep -q "$changed_file" "$RETRIED_TESTS_REPORT_PATH"; then
      echoinfo "Flaky test '$changed_file' was found in the list of files changed by this MR."
      echoinfo "Exiting with code $SUCCESSFULLY_RETRIED_TEST_EXIT_CODE."
      exit $SUCCESSFULLY_RETRIED_TEST_EXIT_CODE
    fi
  done <<< "$changed_files"

  echoinfo "Flaky test was not part of this MR."
}

function rspec_rerun_previous_failed_tests() {
  local test_file_count_threshold=${RSPEC_PREVIOUS_FAILED_TEST_FILE_COUNT_THRESHOLD:-10}
  local matching_tests_file=${1}
  local rspec_opts=${2}
  local test_files="$(cat "${matching_tests_file}")"
  local test_file_count=$(wc -w "${matching_tests_file}" | awk {'print $1'})

  if [[ "${test_file_count}" -gt "${test_file_count_threshold}" ]]; then
    echo "This job is intentionally exited because there are more than ${test_file_count_threshold} test files to rerun."
    exit 0
  fi

  if [[ -n $test_files ]]; then
    rspec_simple_job_with_retry "${test_files}"
  else
    echo "No failed test files to rerun"
  fi
}

function rspec_fail_fast() {
  local test_file_count_threshold=${RSPEC_FAIL_FAST_TEST_FILE_COUNT_THRESHOLD:-10}
  local matching_tests_file=${1}
  local rspec_opts=${2}
  local test_files="$(cat "${matching_tests_file}")"
  local test_file_count=$(wc -w "${matching_tests_file}" | awk {'print $1'})

  if [[ "${test_file_count}" -gt "${test_file_count_threshold}" ]]; then
    echo "This job is intentionally skipped because there are more than ${test_file_count_threshold} test files matched,"
    echo "which would take too long to run in this job."
    echo "All the tests would be run in other rspec jobs."
    exit 0
  fi

  if [[ -n $test_files ]]; then
    rspec_simple_job_with_retry "${rspec_opts} ${test_files}"
  else
    echo "No rspec fail-fast tests to run"
  fi
}

function filter_rspec_matched_foss_tests() {
  local matching_tests_file="${1}"
  local foss_matching_tests_file="${2}"

  # Keep only files that exists (i.e. exclude EE speficic files)
  cat ${matching_tests_file} | ruby -e 'puts $stdin.read.split(" ").select { |f| f.start_with?("spec/") && File.exist?(f) }.join(" ")' > "${foss_matching_tests_file}"
}

function generate_frontend_fixtures_mapping() {
  local pattern=""

  if [[ -d "ee/" ]]; then
    pattern=",ee/"
  fi

  if [[ -d "jh/" ]]; then
    pattern="${pattern},jh/"
  fi

  if [[ -n "${pattern}" ]]; then
    pattern="{${pattern}}"
  fi

  pattern="${pattern}spec/frontend/fixtures/**/*.rb"

  export GENERATE_FRONTEND_FIXTURES_MAPPING="true"

  mkdir -p $(dirname "$FRONTEND_FIXTURES_MAPPING_PATH")

  rspec_simple_job_with_retry "--pattern \"${pattern}\""
}

function cleanup_individual_job_reports() {
  local rspec_flaky_folder_path="$(dirname "${FLAKY_RSPEC_SUITE_REPORT_PATH}")/"
  local knapsack_folder_path="$(dirname "${KNAPSACK_RSPEC_SUITE_REPORT_PATH}")/"

  rm -rf ${knapsack_folder_path}rspec*.json \
    ${rspec_flaky_folder_path}all_*.json \
    ${rspec_flaky_folder_path}new_*.json \
    ${rspec_flaky_folder_path}skipped_flaky_tests_*_report.txt \
    ${rspec_flaky_folder_path}retried_tests_*_report.txt \
    ${RSPEC_LAST_RUN_RESULTS_FILE} \
    ${RSPEC_PROFILING_FOLDER_PATH}/**/*
  rmdir ${RSPEC_PROFILING_FOLDER_PATH} || true
}

function generate_flaky_tests_reports() {
  local rspec_flaky_folder_path="$(dirname "${FLAKY_RSPEC_SUITE_REPORT_PATH}")/"

  debug_rspec_variables

  mkdir -p ${rspec_flaky_folder_path}

  find ${rspec_flaky_folder_path} -type f -name 'skipped_flaky_tests_*_report.txt' -exec cat {} + >> "${SKIPPED_FLAKY_TESTS_REPORT_PATH}"
  find ${rspec_flaky_folder_path} -type f -name 'retried_tests_*_report.txt' -exec cat {} + >> "${RETRIED_TESTS_REPORT_PATH}"

  cleanup_individual_job_reports
}
