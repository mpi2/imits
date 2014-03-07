#!/bin/bash

#SOLR_UP=`curl -s 'http://ikmc.vm.bytemark.co.uk:8983/solr/allele/admin/ping'|grep -q OK;echo $?`
#echo $SOLR_UP

#echo /nfs/users/nfs_r/re4

#if [ ! -f /nfs/users/nfs_r/re4/dev/imits10/script/solr_bulk/solr_bulk.sql ]; then
#    echo "Cannot find '/nfs/users/nfs_r/re4/dev/imits10/script/solr_bulk/solr_bulk.sql'!"
#    exit
#fi
#
#echo "done!"

time PGPASSWORD=imits psql -U imits -d imits_development -h localhost < /nfs/users/nfs_r/re4/dev/imits10/script/solr_bulk/solr_bulk.sql
time zeus rake solr_bulk:index:load
rm -f /nfs/users/nfs_r/re4/Desktop/solr-old-all.csv /nfs/users/nfs_r/re4/Desktop/solr-new-all.csv
time zeus rake solr_bulk:download_and_normalize['/nfs/users/nfs_r/re4/Desktop/solr-old-all.csv','http://localhost:8985/solr']
time zeus rake solr_bulk:download_and_normalize['/nfs/users/nfs_r/re4/Desktop/solr-new-all.csv','http://localhost:8983/solr']
sort /nfs/users/nfs_r/re4/Desktop/solr-old-all-regular.csv > /nfs/users/nfs_r/re4/Desktop/solr-old-all.csv
sort /nfs/users/nfs_r/re4/Desktop/solr-new-all-regular.csv > /nfs/users/nfs_r/re4/Desktop/solr-new-all.csv
diff /nfs/users/nfs_r/re4/Desktop/solr-old-all.csv /nfs/users/nfs_r/re4/Desktop/solr-new-all.csv | wc

#diff /nfs/users/nfs_r/re4/Desktop/solr-old-all.csv /nfs/users/nfs_r/re4/Desktop/solr-new-all.csv
#meld /nfs/users/nfs_r/re4/Desktop/solr-old-all.csv /nfs/users/nfs_r/re4/Desktop/solr-new-all.csv &
