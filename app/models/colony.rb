require 'pp'

class Colony < ActiveRecord::Base

  class Observer < ActiveRecord::Observer
    observe :colony

    def initialize
      super
    end

    def after_save(c)
      puts "#### Colony::Observer after_save"
      # TODO: get these params from somewhere
     # c.scf({ :start => 139237069, :end => 139237133, :chr => 1, :strand => -1})
    end

    def after_destroy(c)
      puts "#### Colony::Observer after_destroy"
   #   c.remove
    end

    public_class_method :new
  end

  acts_as_audited
  acts_as_reportable

  belongs_to :mi_attempt

  validates :name, :presence => true, :uniqueness => true

  has_attached_file :trace_file, :storage => :database

  do_not_validate_attachment_file_type :trace_file

  belongs_to :mi_attempt

  validate do |colony|
    if !mi_attempt.blank? and !mi_attempt.es_cell.blank?
      if Colony.where("mi_attempt_id = #{colony.mi_attempt_id} #{if !colony.id.blank?; "and id = #{colony.id}"; end}").count == 1
        colony.errors.add :base, 'Multiple Colonies are not allowed for Mi Attempts micro-injected with an ES Cell clone'
      end
    end
  end

  def self.readable_name
    return 'colony'
  end

  VERBOSE = true

  SCRIPT_RUNREMOTE = "#{Rails.root}/script/runremote.sh"
  SCRIPT_SCF = "#{Rails.root}/script/scf.sh"
  FOLDER_IN = "#{Rails.root}/tmp/trace_files_output"
  FOLDER_OUT = "#{Rails.root}/public/trace_files"
  FOLDER_TMP = "#{Rails.root}/tmp/trace_files"
  SCF_FILES = %W{
    alignment.txt
    filtered_analysis.vcf
    analysis.pileup
    variant_effect_output.txt
    variant_effect_output.txt_summary.html
    mutated.fa
  }

  def remove
    folder_out = "#{FOLDER_OUT}/#{self.id}"

    return if ! File.exists?(folder_out)

    SCF_FILES.each { |file| FileUtils.rm "#{folder_out}/#{file}", :force => true }

    FileUtils.rmdir folder_out, :force => true
  end

  def run_cmd options
    command_pre = ""
    command = ""
    command += "#{SCRIPT_RUNREMOTE}" if options[:remote]
    command += " #{SCRIPT_SCF} bash re4 t87-dev " +
      "-s #{options[:start]} -e #{options[:end]} -c #{options[:chr]} " +
      "-t #{options[:strand]} -x #{options[:species]} -f #{options[:file]} -d #{options[:dir]}"
    command_post = ""

    "#{command_pre} #{command} #{command_post}"
  end

  def scf options = {}

    if ! self.trace_file
      puts "#### no trace file!"
      return
    end

    options[:remote] = true
    options[:species] = "Mouse"
    options[:dir] = self.id

    folder = FOLDER_TMP
    filename = "#{folder}/tmp.scf"
    self.trace_file.copy_to_local_file('original', filename)

    options[:file] = filename

    FileUtils.mkdir_p FOLDER_IN
    FileUtils.mkdir_p FOLDER_TMP

    [:start, :end, :chr, :strand, :species, :file, :dir].each do |flag|
      raise "#### cannot find #{flag}!" if ! options.has_key? flag
    end

    error_output = nil
    exit_status = nil
    output = nil

    cmd = run_cmd options

    puts "#### '#{cmd}'" if VERBOSE

    Open3.popen3("#{cmd}") do |scriptin, scriptout, scripterr, wait_thr|
      error_output = scripterr.read
      exit_status = wait_thr.value.exitstatus
      output = scriptout.read
    end

    #output = output.gsub(/\\n/, "\n")
    #error_output = error_output.gsub(/\\n/, "\n")

    if VERBOSE
      puts "#### error_output:"
      pp error_output
      puts "#### exit_status:"
      pp exit_status
      puts "#### output:"
      pp output
    end

  end

  def save_files

    colony = self

    folder_in = "#{FOLDER_IN}/#{colony.id}"
    FileUtils.mkdir_p folder_in

    folder_out = "#{FOLDER_OUT}/#{colony.id}"
    FileUtils.mkdir_p folder_out

    file_count = 0
    SCF_FILES.each do |file|
      source = "#{folder_in}/#{file}"

      if File.exists?(source)
        FileUtils.cp(source, folder_out)

        file_count += 1
      end
    end

    FileUtils.mv(filename, "#{FOLDER_TMP}/#{colony.id}/#{colony.trace_file_file_name}")

    puts "#### file_count: #{file_count}" if VERBOSE
  end

  #def self.run
  #
  #  colony = self
  #
  #  folder = FOLDER_IN
  #  FileUtils.mkdir_p folder
  #
  #  folder = FOLDER_TMP
  #  FileUtils.mkdir_p folder
  #
  #  @colonies = Colony.all if colony == nil
  #  @colonies = [colony] if colony != nil
  #
  #  @colonies.each do |colony|
  #    if colony.trace_file
  #      filename = "#{folder}/tmp.scf"
  #      colony.trace_file.copy_to_local_file('original', filename)
  #
  #      if VERBOSE
  #        s1 = colony.trace_file.size
  #        s2 = File.size(filename)
  #        puts "#### filename: #{filename}"
  #        puts "#### size: (" + s1.to_s + "/" + s2.to_s + ")"
  #      end
  #
  #      scf({ :start => 139237069, :end => 139237133, :chr => 1, :strand => -1, :species => "Mouse", :file => filename, :dir => colony.id})
  #
  #      save_files colony
  #    end
  #  end
  #
  #end

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
