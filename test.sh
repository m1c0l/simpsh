#!/bin/bash

# debug statements
if [ "$1" = "--debug" ]; then
  set -x
fi

all_passed=true

function should_fail() {
  result=$?

  echo -n "==> $1 ($(caller))"

  if [ $result -eq 0 ]; then
    echo "FAILURE"
    all_passed=false
    return 1
  else
    echo
    return 0
  fi
}

function should_succeed() {
  result=$?

  echo -n "==> $1 ($(caller))"

  if [ $result -ne 0 ]; then
    echo "FAILURE"
    all_passed=false
    return 1
  else
    echo
    return 0
  fi
}

# Valgrind
function check_valgrind() {
  valgrind="valgrind --leak-check=full --show-leak-kinds=all"
  simpsh="$1"
  output=$($valgrind $simpsh 2>&1)
  [[ "$output" =~ "no leaks are possible" ]]
  return $?
}


tmp=$(mktemp)
tmp2=$(mktemp)
tmp3=$(mktemp)



echo "some text" > $tmp
output=$( ./simpsh --rdonly $tmp --verbose --wronly $tmp \
  --command 0 1 1 sort --wronly $tmp )
test "$output" = "$(printf -- "--wronly $tmp\n--command 0 1 1 sort\n\
--wronly $tmp")"
should_succeed "verbose has the correct output"


output=$(./simpsh --rdonly $tmp --wronly $tmp2 --command 0 -1 1 cat 2>&1)
should_fail "negative file descriptors should fail"
[[ "$output" =~ "file descriptor" ]]
should_succeed "negative file descriptors should report and error"


output=$(./simpsh --rdonly $tmp --wronly $tmp2 --command 0 aa 1 cat 2>&1)
should_fail "nonnumber file descriptors should fail"
[[ "$output" =~ "file descriptor" ]]
should_succeed "nonnumber file descriptors should report and error"

output=$(./simpsh --rdonly $tmp --wronly $tmp2 --command 0 1a 1 cat 2>&1)
should_fail "nonnumber file descriptors should fail"
[[ "$output" =~ "file descriptor" ]]
should_succeed "nonnumber file descriptors should report and error"

random="reiujfsdkf"
output=$(./simpsh --rdonly $tmp --wronly $tmp2 --wronly $tmp3 \
  --command 0 1 2 ls $tmp $random 2>&1)
should_succeed "valid call should return 0"
test "$(cat $tmp2)" = "$tmp"
should_succeed "writes to stdout correctly"
[[ "$(cat $tmp3)" =~ "No such file or directory" ]]
should_succeed "writes to stderr correctly"
test "$(cat $tmp3)" = "$tmp"
should_fail "stderr should not be in stdout file"
[[ "$(cat $tmp2)" =~ "No such file or directory" ]]
should_fail "stdout should not be in stderr file"


check_valgrind "./simpsh --rdonly $tmp --wronly $tmp2 --wronly $tmp3 --verbose \
  --command 0 1 2 cat --rdonly in --command 0 1 2 ls -l --wronly out"
should_succeed "Valgrind reports no memory leaks"

check_valgrind "./simpsh --rdonly $tmp --wronly $tmp2 --wronly $tmp3 --verbose \
  --command 0 1 2 cat --rdonly in --command sd0 1 2 ls -l --wronly out"
should_succeed "No memory leaks on bad file descriptor"

check_valgrind "./simpsh --rdonly $tmp --wronly $tmp2 --wronly $tmp3 --verbose \
  --command 0 1 2 cat --rdonly in --command 1 1 2 ls -l --wronly out"
should_succeed "No memory leaks when reading write-only file"

check_valgrind "./simpsh --rdonly $tmp --wronly $tmp2 --command 0 1"
should_succeed "No memory leaks when not enough --command args"

check_valgrind "./simpsh --rdonly $tmp --wronly $tmp2 $tmp3"
should_succeed "No memory leaks when too many arguments to --wronly"



rm $tmp $tmp2 $tmp3

if $all_passed; then
  echo "Success"
  exit 0
else
  echo "Some tests failed"
  exit 1
fi
