require 'pp'

class Colony < ActiveRecord::Base

  class Observer < ActiveRecord::Observer
    observe :colony

    def initialize
      super
    end

    def after_save(c)
      puts "#### Colony::Observer after_save (#{c.id})"
      c.scf if Colony::SYNC
    end

    def after_destroy(c)
      puts "#### Colony::Observer after_destroy (#{c.id})"
      c.remove_files
    end

    public_class_method :new
  end

  acts_as_audited
  acts_as_reportable

  belongs_to :mi_attempt

  validates :name, :presence => true, :uniqueness => true

  has_attached_file :trace_file, :storage => :database

  do_not_validate_attachment_file_type :trace_file

  validate do |colony|
    if !mi_attempt.blank? and !mi_attempt.es_cell.blank?
      if Colony.where("mi_attempt_id = #{colony.mi_attempt_id} #{if !colony.id.blank?; "and id = #{colony.id}"; end}").count == 1
        colony.errors.add :base, 'Multiple Colonies are not allowed for Mi Attempts micro-injected with an ES Cell clone'
      end
    end
  end

  before_save :check_files

  def check_files
    if trace_file_file_name_changed?
      puts "#### CHANGED!"
      self.remove_files
    else
      puts "#### UN-CHANGED!"
    end
  end

  def self.readable_name
    return 'colony'
  end

  SYNC = false
  VERBOSE = true

  SCRIPT_RUNREMOTE = "#{Rails.root}/script/runremote.sh"
  SCRIPT_SCF = "#{Rails.root}/script/scf.sh"
#  FOLDER_IN = "#{Rails.root}/tmp/trace_files_output"
  FOLDER_IN = '/nfs/team87/imits/trace_files_output'
  FOLDER_OUT = "#{Rails.root}/public/trace_files"
  FOLDER_TMP = "#{Rails.root}/tmp/trace_files"
  SCF_FILES = %W{
    alignment.txt
    filtered_analysis.vcf
    analysis.pileup
    variant_effect_output.txt
    variant_effect_output.txt_summary.html
    mutated.fa
    vep.log
    read_seq.fa
    variant_effect_output.txt
    primer_reads.fa
    alignment_data.yaml
    reference.fa
  }

  def trace_data_pending
    ! File.exists?("#{FOLDER_OUT}/#{self.id}") && ! self.trace_file_file_name.blank?
  end

  def trace_data_available
    File.exists?("#{FOLDER_OUT}/#{self.id}")
  end

  def remove_files
    folder_out = "#{FOLDER_OUT}/#{self.id}"

    return if ! File.exists?(folder_out)

    SCF_FILES.each { |file| FileUtils.rm "#{folder_out}/#{file}", :force => true }

   #FileUtils.rm "#{folder_out}/*.scf", :force => true
    FileUtils.rm(Dir.glob("#{folder_out}/*.scf"), :force => true)

    FileUtils.rmdir folder_out
  end

  def run_cmd options
    command_pre = ""
    command = ""
    command += "#{SCRIPT_RUNREMOTE}" if options[:remote]
    #command += " #{SCRIPT_SCF} bash re4 t87-dev " +
    command += " #{SCRIPT_SCF} bash $USER t87-dev " +
    "-s #{options[:start]} -e #{options[:end]} -c #{options[:chr]} " +
    "-t #{options[:strand]} -x #{options[:species]} -f #{options[:file]} -d #{options[:dir]}"
    command_post = ""

    puts "#### #{command_pre} #{command} #{command_post}"
    
    "#{command_pre} #{command} #{command_post}"
  end

  def scf options = {}

    # we only run this if there's no folder already there
    # the observer above clears out the folder in after_destroy

    if ! options[:force] && File.exists?("#{FOLDER_OUT}/#{self.id}")
      puts "#### trace output already exists (#{self.id})!"
      return
    end

    if ! self.trace_file || self.trace_file_file_name.blank?
      puts "#### no trace file!"
      return
    end

    FileUtils.mkdir_p FOLDER_IN
    FileUtils.mkdir_p FOLDER_TMP

    #      colony.scf({ :start => 139237069, :end => 139237133, :chr => 1, :strand => -1})

    options[:remote] = true
    options[:chr] = mi_attempt.mi_plan.gene.chr if ! options[:chr]
    # TODO: check me!
    options[:strand] = "#{mi_attempt.mi_plan.gene.strand_name}1" if ! options[:strand]
    options[:species] = "Mouse"
    options[:dir] = self.id

   # pp self.mi_attempt.crisprs

    if ! options[:start] || ! options[:end]
      s = 0
      e = 0
      self.mi_attempt.crisprs.each do |crispr|
        s = crispr.start.to_i if s == 0 || crispr.start.to_i < s.to_i
        e = crispr.end.to_i if e == 0 || crispr.end.to_i > e.to_i
      end

      options[:start] = s
      options[:end] = e
    end

    folder = FOLDER_TMP
    filename = "#{folder}/tmp.scf"
    self.trace_file.copy_to_local_file('original', filename)

    options[:file] = filename

    [:start, :end, :chr, :strand, :species, :file, :dir].each do |flag|
      raise "#### cannot find flag '#{flag}'!" if ! options.has_key? flag
    end

   # pp options

    error_output = nil
    exit_status = nil
    output = nil

    cmd = run_cmd options

    #puts "#### '#{cmd}'" if VERBOSE

    Open3.popen3("#{cmd}") do |scriptin, scriptout, scripterr, wait_thr|
      error_output = scripterr.read
      exit_status = wait_thr.value.exitstatus
      output = scriptout.read
    end

    if VERBOSE
      puts "#### error_output:"
      puts error_output
      puts "#### exit_status:"
      puts exit_status
      puts "#### output:"
      puts output
    end

    save_files

  end

  def save_files
    folder_in = "#{FOLDER_IN}/#{self.id}"
    FileUtils.mkdir_p folder_in

    folder_out = "#{FOLDER_OUT}/#{self.id}"
    FileUtils.mkdir_p folder_out

    file_count = 0
    SCF_FILES.each do |file|
      source = "#{folder_in}/#{file}"

      if File.exists?(source)
        FileUtils.cp(source, folder_out)

        file_count += 1
      end
    end

    FileUtils.mv("#{FOLDER_TMP}/tmp.scf", "#{folder_out}/#{self.trace_file_file_name}")

    puts "#### clearing out '#{folder_in}'" if VERBOSE

#    return

   #FileUtils.rm("#{folder_in}/merge_vcf/*.*", :force => true)
    FileUtils.rm(Dir.glob("#{folder_in}/merge_vcf/*.*"), :force => true)
    FileUtils.rmdir("#{folder_in}/merge_vcf")
    #FileUtils.rm("#{folder_in}/*.*", :force => true)
    FileUtils.rm(Dir.glob("#{folder_in}/*.*"), :force => true)
    FileUtils.rmdir("#{folder_in}")

    puts "#### file_count: #{file_count}" if VERBOSE
  end

end

# == Schema Information
#
# Table name: colonies
#
#  id                      :integer          not null, primary key
#  name                    :string(255)      not null
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
