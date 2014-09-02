require 'pp'
require 'tempfile'

class Colony < ActiveRecord::Base

  acts_as_audited
  acts_as_reportable

  belongs_to :mi_attempt

  has_one :colony_qc, :inverse_of => :colony, :dependent => :destroy

  accepts_nested_attributes_for :colony_qc, :allow_destroy => true

  validates :name, :presence => true, :uniqueness => true

  has_attached_file :trace_file, :storage => :database

  do_not_validate_attachment_file_type :trace_file

  validate do |colony|
    if !mi_attempt_id.blank? and !mi_attempt.es_cell_id.blank?
      if Colony.where("mi_attempt_id = #{colony.mi_attempt_id} #{if !colony.id.blank?; "and id != #{colony.id}"; end}").count == 1
        colony.errors.add :base, 'Multiple Colonies are not allowed for Mi Attempts micro-injected with an ES Cell clone'
      end
    end
  end

  before_save :check_changed

  def check_changed
    self.file_alignment = nil if trace_file_file_name_changed?
  end
  protected :check_changed

  before_save :set_genotype_confirmed

  def set_genotype_confirmed
    if !mi_attempt.blank? && !mi_attempt.status.blank?
      if !mi_attempt.es_cell.blank? && mi_attempt.status.code == 'gtc'
        self.genotype_confirmed = true
      end
    end
  end
  protected :set_genotype_confirmed

  def self.readable_name
    return 'colony'
  end

  #TARGET_TYPES = [
  #  :alignment,
  #  :filtered_analysis_vcf,
  #  :variant_effect_output_txt,
  #  :reference,
  #  :mutant_fa,
  #  :primer_reads_fa,
  #  :insertions,
  #  :deletions
  #]

  SYNC = false
  VERBOSE = true
  KEEP_GENERATED_FILES = true

  SCRIPT_RUNREMOTE = "#{Rails.root}/script/runremote.sh"
  SCRIPT_SCF = "#{Rails.root}/script/scf.sh"

  FOLDER_IN = "/nfs/team87/imits/trace_files_output/#{Rails.env}/#{ENV['USER']}"

  #SCF_FILES = %W{
  #  alignment.txt
  #  filtered_analysis.vcf
  #  variant_effect_output.txt
  #  reference.fa
  #  mutated.fa
  #  primer_reads.fa
  #  alignment_data.yaml
  #}

  def trace_data_pending
    file_alignment.blank? && ! self.trace_file_file_name.blank?
  end

  def trace_data_available
    ! file_alignment.blank?
  end

  def run_cmd options
    command_pre = ""
    command = ""
    command += "#{SCRIPT_RUNREMOTE}" if options[:remote]
    command += " #{SCRIPT_SCF} bash " + ENV['USER'] + " t87-dev " +
    "-s #{options[:start]} -e #{options[:end]} -c #{options[:chr]} " +
    "-t #{options[:strand]} -x #{options[:species]} -f #{options[:file]} -d #{options[:dir]} -q #{FOLDER_IN}"
    command_post = ""

    puts "#### #{command_pre} #{command} #{command_post}"

    "#{command_pre} #{command} #{command_post}"
  end

  def scf options = {}

    # we only run this if it's not already been processed

    if ! options[:force] && ! self.file_alignment.blank?
      puts "#### trace output already exists (#{self.id})!"
      return
    end

    if ! self.trace_file || self.trace_file_file_name.blank?
      puts "#### no trace file!"
      return
    end

    FileUtils.mkdir_p FOLDER_IN

    options[:remote] = true
    options[:chr] = mi_attempt.mi_plan.gene.chr if ! options[:chr]
    # TODO: check me!
    options[:strand] = "#{mi_attempt.mi_plan.gene.strand_name}1" if ! options[:strand]
    options[:species] = "Mouse"
    options[:dir] = self.id

    if ! options[:start] || ! options[:end]
      s = 0
      e = 0
      self.mi_attempt.crisprs.each do |crispr|
        s = crispr.start.to_i if s == 0 || crispr.start.to_i < s.to_i
        e = crispr.end.to_i if e == 0 || crispr.end.to_i > e  .to_i
      end

      options[:start] = s
      options[:end] = e
    end

    filename = Dir::Tmpname.make_tmpname "#{FOLDER_IN}/", nil
    self.trace_file.copy_to_local_file('original', filename)

    puts "#### filename: #{filename}"

    options[:file] = filename

    [:start, :end, :chr, :strand, :species, :file, :dir].each do |flag|
      raise "#### cannot find flag '#{flag}'!" if ! options.has_key? flag
    end

    error_output = nil
    exit_status = nil
    output = nil

    cmd = run_cmd options

    Open3.popen3("#{cmd}") do |scriptin, scriptout, scripterr, wait_thr|
      error_output = scripterr.read
      exit_status = wait_thr.value.exitstatus
      output = scriptout.read
    end

    FileUtils.rm(filename, :force => true)

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

  def save_files_1
    Colony.transaction do
      folder_in = "#{FOLDER_IN}/#{self.id}"
      # FileUtils.mkdir_p folder_in

      filename = "#{folder_in}/alignment.txt"
      if File.exists?(filename)
        self.file_alignment = File.open(filename).read
      end

      filename = "#{folder_in}/filtered_analysis.vcf"
      if File.exists?(filename)
        self.file_filtered_analysis_vcf = File.open(filename).read
      end

      filename = "#{folder_in}/variant_effect_output.txt"
      if File.exists?(filename)
        self.file_variant_effect_output_txt = File.open(filename).read
      end

      filename = "#{folder_in}/reference.fa"
      if File.exists?(filename)
        self.file_reference_fa = File.open(filename).read
      end

      filename = "#{folder_in}/mutated.fa"
      if File.exists?(filename)
        self.file_mutant_fa = File.open(filename).read
      end

      filename = "#{folder_in}/primer_reads.fa"
      if File.exists?(filename)
        contents = File.open(filename).read
        data = contents.lines.to_a[1..-1].join
        data.gsub!(/\s+/, "")
        self.file_primer_reads_fa = data
      end

      filename = "#{folder_in}/alignment_data.yaml"
      if File.exists?(filename)
        self.file_alignment_data_yaml = File.open(filename).read
      end

      self.save!

      return if KEEP_GENERATED_FILES

      FileUtils.rm(Dir.glob("#{folder_in}/merge_vcf/*.*"), :force => true)
      FileUtils.rmdir("#{folder_in}/merge_vcf")
      FileUtils.rm(Dir.glob("#{folder_in}/*.*"), :force => true)
      FileUtils.rmdir("#{folder_in}", :verbose => true)
    end
  end

  def save_files
    Colony.transaction do
      folder_in = "#{FOLDER_IN}/#{self.id}"

      self.file_alignment = save_file "#{folder_in}/alignment.txt"
      self.file_filtered_analysis_vcf = save_file "#{folder_in}/filtered_analysis.vcf"
      self.file_variant_effect_output_txt = save_file "#{folder_in}/variant_effect_output.txt"
      self.file_reference_fa = save_file "#{folder_in}/reference.fa"
      self.file_mutant_fa = save_file "#{folder_in}/mutated.fa"
      self.file_alignment_data_yaml = save_file "#{folder_in}/alignment_data.yaml"

      filename = "#{folder_in}/primer_reads.fa"
      if File.exists?(filename)
        contents = File.open(filename).read
        data = contents.lines.to_a[1..-1].join
        data.gsub!(/\s+/, "")
        self.file_primer_reads_fa = data
      end

      self.save!

      return if KEEP_GENERATED_FILES

      FileUtils.rm(Dir.glob("#{folder_in}/merge_vcf/*.*"), :force => true)
      FileUtils.rmdir("#{folder_in}/merge_vcf")
      FileUtils.rm(Dir.glob("#{folder_in}/*.*"), :force => true)
      FileUtils.rmdir("#{folder_in}", :verbose => true)
    end
  end

  def save_file(filename)
    return File.open(filename).read if File.exists?(filename)

    nil
  end

  #def save_file(filename, attribute)
  #  puts "#### save_file: '#{filename}'" if VERBOSE
  #  if File.exists?(filename)
  #    puts "#### save_file: processing '#{filename}'" if VERBOSE
  #    attribute = File.open(filename).read
  #  end
  #end
  #
  #def save_files_new
  #
  #  Colony.transaction do
  #    folder_in = "#{FOLDER_IN}/#{self.id}"
  #
  #    save_file "#{folder_in}/alignment.txt", self.file_alignment
  #    save_file "#{folder_in}/filtered_analysis.vcf", self.file_filtered_analysis_vcf
  #    save_file "#{folder_in}/variant_effect_output.txt", self.file_variant_effect_output_txt
  #    save_file "#{folder_in}/reference.fa", self.file_reference_fa
  #    save_file "#{folder_in}/mutated.fa", self.file_mutant_fa
  #    save_file "#{folder_in}/primer_reads.fa", self.file_primer_reads_fa
  #    save_file "#{folder_in}/alignment_data.yaml", self.file_alignment_data_yaml
  #
  #    #if @files[:primer_reads_fa][:data]
  #    #  @files[:primer_reads_fa][:data] = @files[:primer_reads_fa][:data].lines.to_a[1..-1].join
  #    #  @files[:primer_reads_fa][:data].gsub!(/\s+/, "")
  #    #end
  #
  #    puts "#### begin file_primer_reads_fa!" if VERBOSE
  #    pp self.file_primer_reads_fa
  #
  #    if ! self.file_primer_reads_fa.blank?
  #      puts "#### start file_primer_reads_fa!" if VERBOSE
  #      data = self.file_primer_reads_fa.lines.to_a[1..-1].join
  #      data.gsub!(/\s+/, "")
  #      self.file_primer_reads_fa = data
  #    end
  #
  #    self.save!
  #
  #    return if KEEP_GENERATED_FILES
  #
  #    puts "#### remove folders!" if VERBOSE
  #
  #    puts "#### remove #{folder_in}/merge_vcf/*.*" if VERBOSE
  #    FileUtils.rm(Dir.glob("#{folder_in}/merge_vcf/*.*"), :force => true)
  #
  #    puts "#### remove #{folder_in}/merge_vcf" if VERBOSE
  #    FileUtils.rmdir("#{folder_in}/merge_vcf")
  #
  #    puts "#### remove #{folder_in}/*.*" if VERBOSE
  #    FileUtils.rm(Dir.glob("#{folder_in}/*.*"), :force => true)
  #
  #    puts "#### remove #{folder_in}" if VERBOSE
  #    FileUtils.rmdir("#{folder_in}", :verbose => true)
  #  end
  #end

  def insertions
    @alignment_data = {}
    @alignment_data = YAML.load(self.file_alignment_data_yaml) if ! self.file_alignment_data_yaml.blank?

    @insertions = []

    if @alignment_data.has_key? 'insertions'
      @alignment_data['insertions'].keys.each do |kk|
        array = @alignment_data['insertions'][kk]
        array.each do |frame|
          @insertions.push "#{kk}: length: #{frame['length']} - read: #{frame['read']} - seq: #{frame['seq']}"
        end
      end
    end

    return @insertions
  end

  def deletions
    @alignment_data = {}
    @alignment_data = YAML.load(self.file_alignment_data_yaml) if ! self.file_alignment_data_yaml.blank?

    puts "#### @alignment_data:"
    pp @alignment_data

    @deletions = []

    if @alignment_data.has_key? 'deletions'
      @alignment_data['deletions'].keys.each do |kk|
        array = @alignment_data['deletions'][kk]
        array.each do |frame|
          @deletions.push "#{kk}: length: #{frame['length']} - read: #{frame['read']} - seq: #{frame['seq']}"
        end
      end
    end

    return @deletions
  end

end

# == Schema Information
#
# Table name: colonies
#
#  id                             :integer          not null, primary key
#  name                           :string(255)      not null
#  mi_attempt_id                  :integer
#  trace_file_file_name           :string(255)
#  trace_file_content_type        :string(255)
#  trace_file_file_size           :integer
#  trace_file_updated_at          :datetime
#  genotype_confirmed             :boolean          default(FALSE)
#  file_alignment                 :text
#  file_filtered_analysis_vcf     :text
#  file_variant_effect_output_txt :text
#  file_reference_fa              :text
#  file_mutant_fa                 :text
#  file_primer_reads_fa           :text
#  file_alignment_data_yaml       :text
#
# Indexes
#
#  colony_name_index  (name) UNIQUE
#
