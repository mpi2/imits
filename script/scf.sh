#!/bin/bash

source "/opt/t87/global/conf/bashrc"

use lims2-devel

cd /nfs/users/nfs_r/re4/dev/htgt_root/HTGT-QC-Common/bin

#export DEFAULT_CRISPR_DAMAGE_QC_DIR=/nfs/users/nfs_r/re4/scf_analysis_output
export DEFAULT_CRISPR_DAMAGE_QC_DIR=/nfs/users/nfs_r/re4/dev/imits15/tmp/trace_files_output

#time perl -I ../lib ./crispr_damage_analysis.pl --target-start 139237069 --target-end 139237133 --target-chr 1 --target-strand -1 --species Mouse  --scf-file /nfs/users/nfs_r/re4/scf_analysis/test-2.scf

#while getopts s:d:p:f: option
while getopts s:e:c:t:x:f:d: option
do
        case "${option}"
        in
                s) TSTART=${OPTARG};;
                e) TEND=${OPTARG};;
                c) CHR=${OPTARG};;
                t) STR=$OPTARG;;
                x) SPEC=$OPTARG;;
                f) FILE=$OPTARG;;
                d) DIR=$OPTARG;;
        esac
done

#echo $TSTART

echo perl -I ../lib ./crispr_damage_analysis.pl --target-start $TSTART --target-end $TEND --target-chr $CHR --target-strand $STR --species $SPEC --dir $DIR --scf-file $FILE

perl -I ../lib ./crispr_damage_analysis.pl --target-start $TSTART --target-end $TEND --target-chr $CHR --target-strand $STR --species $SPEC --dir $DIR --scf-file $FILE

#http://backreference.org/2011/08/10/running-local-script-remotely-with-arguments/
