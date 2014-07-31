require 'pp'
require "open3"

namespace :scf do

  desc 'run the scf process'
  task :run => [:environment] do

    error_output = nil
    exit_status = nil
    output = nil

    command_pre = "use lims2-devel; cd #{Rails.root}/script;"
    command = "perl -I /nfs/users/nfs_r/re4/dev/htgt_root/HTGT-QC-Common/lib ./crispr_damage_analysis.pl --target-start 139237069 --target-end 139237133 --target-chr 1 --target-strand -1 --species Mouse  --scf-file /nfs/users/nfs_r/re4/scf_analysis/test-2.scf"
    #command = "which perl"
    command_post = ""

    Open3.popen3("#{command_pre} #{command} #{command_post}") do |scriptin, scriptout, scripterr, wait_thr|
    #Open3.popen3("#{command}") do |scriptin, scriptout, scripterr, wait_thr|
      error_output = scripterr.read
      exit_status = wait_thr.value.exitstatus
      output = scriptout.read
    end

    puts "#### error_output:"
    pp error_output
    puts "#### exit_status:"
    pp exit_status
    puts "#### output:"
    pp output

  end

end


#use lims2-devel
#
#cd /nfs/users/nfs_r/re4/dev/htgt_root/HTGT-QC-Common/bin
#
#export DEFAULT_CRISPR_DAMAGE_QC_DIR=/nfs/users/nfs_r/re4/scf_analysis_output
#
#time perl -I ../lib ./crispr_damage_analysis.pl --target-start 139237069 --target-end 139237133 --target-chr 1 --target-strand -1 --species Mouse  --scf-file /nfs/users/nfs_r/re4/scf_analysis/test-2.scf
