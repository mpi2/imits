class Colony < ActiveRecord::Base

  class Observer < ActiveRecord::Observer
    observe :colony

    def initialize
      super
    end

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
    #  runremote = "/nfs/users/nfs_r/re4/dev/imits15/script/runremote.sh"
    #  scf = "/nfs/users/nfs_r/re4/dev/imits15/script/scf.sh"
    #
    #  error_output = nil
    #  exit_status = nil
    #  output = nil
    #
    #  # /nfs/users/nfs_r/re4/dev/imits15/script/runremote.sh /nfs/users/nfs_r/re4/dev/imits15/script/scf.sh bash re4 t87-dev -s 139237069 -e 139237133 -c 1 -t -1 -x Mouse -f /nfs/users/nfs_r/re4/scf_analysis/test-2.scf
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
    #  # output = output.gsub(/\\n/, "\n")
    #  # error_output = error_output.gsub(/\\n/, "\n")
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
    ##alignment.txt <= alignment of mutant sequence against reference
    ##filtered_anaylst.vcf <= information about mutation
    ##ananlysis.pileup <= might be useful for storing mutation information in the NHEJ Allele
    ##variant_effect_output.txt <= mutation information i.e. frameshift etc.
    ##variant_effect_output.txt_summary.html <= static html page of summary information
    ##variant_seq.fa <= sequence of mutant trace
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
    #      #puts "#### cp #{source} #{folder_out}"
    #
    #      file_count += 1
    #    end
    #  end
    #
    #  puts "#### file_count: #{file_count}"
    #end
    #
    #def do_scf
    #  folder = "#{Rails.root}/tmp/trace_files_output"
    #  FileUtils.mkdir_p folder
    #
    #  folder = "#{Rails.root}/tmp/trace_files"
    #  FileUtils.mkdir_p folder
    #
    #  if colony.trace_file
    #    s1 = colony.trace_file.size
    #    dfilename = "#{colony.trace_file_file_name}"
    #    filename = "#{folder}/tmp.scf"
    #    colony.trace_file.copy_to_local_file('original', filename)
    #    s2 = File.size(filename)
    #    puts "#### filename: #{filename}"
    #    puts "#### size: (" + s1.to_s + "/" + s2.to_s + ")"
    #
    #    run_scf({ :start => 139237069, :end => 139237133, :chr => 1, :strand => -1, :species => "Mouse", :file => filename, :dir => colony.id})
    #
    #    manage_files colony
    #
    #    folder_out = "#{Rails.root}/public/trace_files/#{colony.id}"
    #    FileUtils.mv(filename, "#{folder_out}/#{colony.trace_file_file_name}")
    #  end
    #end

    def after_save(c)
      puts "#### Colony::Observer after_save"
    end

    def after_destroy(c)
      puts "#### Colony::Observer after_destroy"
    end

    public_class_method :new
  end

  acts_as_audited
  acts_as_reportable

  validates :name, :presence => true, :uniqueness => true

  has_attached_file :trace_file, :storage => :database
  #has_attached_file :trace_file, :storage => :database   #, :path => ":rails_root/public/trace_files/#{Rails.env}/attachments/:id/:style/:basename.:extension"
  #has_attached_file :trace_file, :path => ":rails_root/public/trace_files/#{Rails.env}/attachments/:id/:style/:basename.:extension"

  do_not_validate_attachment_file_type :trace_file

  belongs_to :mi_attempt

  def self.readable_name
    return 'colony'
  end
end

# == Schema Information
#
# Table name: colonies
#
#  id                      :integer          not null, primary key
#  name                    :string(20)       not null
#  mi_attempt_id           :integer
#  trace_file_file_name    :string(255)
#  trace_file_content_type :string(255)
#  trace_file_file_size    :integer
#  trace_file_updated_at   :datetime
#
# Indexes
#
#  colony_name_index  (name) UNIQUE
#
