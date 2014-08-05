require 'pp'
require "open3"

namespace :scf do

  #def run_scf options = {}
  #
  #  raise "#### cannot find start!" if !options.has_key? :start
  #  raise "#### cannot find end!" if !options.has_key? :end
  #  raise "#### cannot find chr!" if !options.has_key? :chr
  #  raise "#### cannot find strand!" if !options.has_key? :strand
  #  raise "#### cannot find species!" if !options.has_key? :species
  #  raise "#### cannot find file!" if !options.has_key? :file
  #  raise "#### cannot find dir!" if !options.has_key? :dir
  #
  #  runremote = "#{Rails.root}/script/runremote.sh"
  #  scf = "#{Rails.root}/script/scf.sh"
  #
  #  error_output = nil
  #  exit_status = nil
  #  output = nil
  #
  #  command_pre = ""
  #  command = "#{runremote} #{scf} bash re4 t87-dev -s #{options[:start]} -e #{options[:end]} -c #{options[:chr]} -t #{options[:strand]} -x #{options[:species]} -f #{options[:file]} -d #{options[:dir]}"
  #  command_post = ""
  #
  #  puts "#### '#{command}'"
  #
  #  Open3.popen3("#{command_pre} #{command} #{command_post}") do |scriptin, scriptout, scripterr, wait_thr|
  #    error_output = scripterr.read
  #    exit_status = wait_thr.value.exitstatus
  #    output = scriptout.read
  #  end
  #
  #  # try to tidy output
  #
  #  # pp output
  #  # pp error_output
  #
  #  #output = output.gsub(/\\n/, " SWAP ")
  #  #error_output = error_output.gsub(/\\n/, " SWAP ")
  #
  #  output = output.gsub('\n', " SWAP ")
  #  error_output = error_output.gsub('\n', " SWAP ")
  #
  #  puts "#### error_output:"
  #  pp error_output
  #  puts "#### exit_status:"
  #  pp exit_status
  #  puts "#### output:"
  #  pp output
  #
  #end
  #
  #def manage_files colony
  #
  #  files = [
  #    'alignment.txt',
  #    'filtered_analysis.vcf',
  #    'analysis.pileup',
  #    'variant_effect_output.txt',
  #    'variant_effect_output.txt_summary.html',
  #    #'variant_seq.fa'
  #    'mutated.fa'
  #  ]
  #
  #  folder_in = "/nfs/users/nfs_r/re4/dev/imits15/tmp/trace_files_output/#{colony.id}"
  #  FileUtils.mkdir_p folder_in
  #
  #  folder_out = "#{Rails.root}/public/trace_files/#{colony.id}"
  #  FileUtils.mkdir_p folder_out
  #
  #  file_count = 0
  #  files.each do |file|
  #    source = "#{folder_in}/#{file}"
  #
  #    if File.exists?(source)
  #      FileUtils.cp(source, folder_out)
  #
  #      file_count += 1
  #    end
  #  end
  #
  #  puts "#### file_count: #{file_count}"
  #end
  #
  #desc 'run the scf process'
  #task :run => [:environment] do
  #
  #  folder = "#{Rails.root}/tmp/trace_files_output"
  #  FileUtils.mkdir_p folder
  #
  #  folder = "#{Rails.root}/tmp/trace_files"
  #  FileUtils.mkdir_p folder
  #
  #  Colony.all.each do |colony|
  #    if colony.trace_file
  #      s1 = colony.trace_file.size
  #      dfilename = "#{colony.trace_file_file_name}"
  #      filename = "#{folder}/tmp.scf"
  #      colony.trace_file.copy_to_local_file('original', filename)
  #      s2 = File.size(filename)
  #      puts "#### filename: #{filename}"
  #      puts "#### size: (" + s1.to_s + "/" + s2.to_s + ")"
  #
  #      run_scf({ :start => 139237069, :end => 139237133, :chr => 1, :strand => -1, :species => "Mouse", :file => filename, :dir => colony.id})
  #
  #      manage_files colony
  #
  #      folder_out = "#{Rails.root}/public/trace_files/#{colony.id}"
  #      FileUtils.mv(filename, "#{folder_out}/#{colony.trace_file_file_name}")
  #    end
  #  end
  #
  #end

  desc 'run the scf process'
  task :run => [:environment] do

    Colony.all.each do |colony|
      # TODO: get these params inside call?
      colony.scf({ :start => 139237069, :end => 139237133, :chr => 1, :strand => -1})
    end

  end

end
