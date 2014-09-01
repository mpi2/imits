#!/bin/bash

source "/opt/t87/global/conf/bashrc"

use lims2-devel

cd /opt/t87/global/software/perl/bin/

while getopts s:e:c:t:x:f:d:q: option
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
                q) QCDIR=$OPTARG;;
        esac
done

echo $QCDIR

export DEFAULT_CRISPR_DAMAGE_QC_DIR=$QCDIR

echo perl -I ../lib ./crispr_damage_analysis.pl --target-start $TSTART --target-end $TEND --target-chr $CHR --target-strand $STR --species $SPEC --dir $DIR --scf-file $FILE

perl -I ../lib ./crispr_damage_analysis.pl --target-start $TSTART --target-end $TEND --target-chr $CHR --target-strand $STR --species $SPEC --dir $DIR --scf-file $FILE
