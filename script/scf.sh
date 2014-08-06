#!/bin/bash

source "/opt/t87/global/conf/bashrc"

use lims2-devel

#cd /nfs/users/nfs_r/re4/dev/htgt_root/HTGT-QC-Common/bin
cd /opt/t87/global/software/perl/bin/

#export DEFAULT_CRISPR_DAMAGE_QC_DIR=/nfs/users/nfs_r/re4/dev/imits15/tmp/trace_files_output
export DEFAULT_CRISPR_DAMAGE_QC_DIR=/nfs/team87/imits/trace_files_output

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

#echo perl -I ../lib ./crispr_damage_analysis.pl --target-start $TSTART --target-end $TEND --target-chr $CHR --target-strand $STR --species $SPEC --dir $DIR --scf-file $FILE

perl -I ../lib ./crispr_damage_analysis.pl --target-start $TSTART --target-end $TEND --target-chr $CHR --target-strand $STR --species $SPEC --dir $DIR --scf-file $FILE
