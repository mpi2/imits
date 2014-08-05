#!/bin/bash
# runremote.sh
# usage: runremote.sh localscript interpreter remoteuser remotehost arg1 arg2 ...

# see http://backreference.org/2011/08/10/running-local-script-remotely-with-arguments/

realscript=$1
interpreter=$2
user=$3
host=$4
shift 4

declare -a args

count=0
for arg in "$@"; do
  args[count]=$(printf '%q' "$arg")
  count=$((count+1))
done

ssh $user@$host "cat | ${interpreter} /dev/stdin" "${args[@]}" < "$realscript"

