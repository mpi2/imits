#!/bin/bash
# runremote.sh
# usage: runremote.sh localscript interpreter remoteuser remotehost arg1 arg2 ...

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

# runremote.sh /nfs/users/nfs_r/re4/scf.sh bash re4 t87-dev -s 999 -e 888 -c 999 -t st -x hhhh -f filename

#/nfs/users/nfs_r/re4/scf.sh -s 139237069 -e 139237133 -c 1 -t -1 -x Mouse -f /nfs/users/nfs_r/re4/scf_analysis/test-2.scf

#time perl -I ../lib ./crispr_damage_analysis.pl --target-start 139237069 --target-end 139237133 --target-chr 1 --target-strand -1 --species Mouse  --scf-file /nfs/users/nfs_r/re4/scf_analysis/test-2.scf

#/nfs/users/nfs_r/re4/dev/imits15/script/runremote.sh /nfs/users/nfs_r/re4/dev/imits15/script/scf.sh bash re4 t87-dev -s 139237069 -e 139237133 -c 1 -t -1 -x Mouse -f /nfs/users/nfs_r/re4/scf_analysis/test-2.scf
