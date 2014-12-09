class TraceCall < ActiveRecord::Base

  acts_as_audited
  acts_as_reportable

  belongs_to :colony

  has_attached_file :trace_file, :storage => :database
  do_not_validate_attachment_file_type :trace_file
  attr_accessible :trace_file
  attr_accessible :is_het

  before_save :check_changed

  def check_changed
    if trace_file_file_name_changed?
      self.file_alignment = nil
      self.file_return_code = nil
      self.file_exception_details = nil
    end
  end
  protected :check_changed

  SYNC = false
  VERBOSE = false
  KEEP_GENERATED_FILES = false
  USER = (ENV['USER'] || `whoami`).chomp

  puts "USER is #{USER}"

  FOLDER_IN = "/nfs/team87/imits/trace_files_output/#{Rails.env}/#{USER}"
  # TODO remove: FOLDER_IN = "/Users/as28/tmp/trace_files_output/#{Rails.env}/#{USER}"

  def trace_data_pending
    file_alignment.blank? && ! self.trace_file_file_name.blank?
  end

  def trace_data_available
    ! file_alignment.blank?
  end

  def trace_data_error
    file_return_code.to_i != 0
  end

  def file_error
    return nil if file_return_code.to_i == 0

    data = file_trace_error.to_s.lines.to_a[-1..-1].join
    data.gsub!(/\s+at\s+.+/, "")
    data.chomp
  end

  def run_cmd options

    file_flag = "--scf-file"
    file_flag = "--het-scf-file" if self.is_het?

    command = "ssh -o CheckHostIP=no t87-dev /bin/bash << EOF\n" +
      "source /opt/t87/global/conf/bashrc;\n" +
      "use lims2-devel;\n" +
      "export DEFAULT_CRISPR_DAMAGE_QC_DIR=#{FOLDER_IN};\n" +
      "crispr_damage_analysis.pl #{file_flag} #{options[:file]} --target-start #{options[:start]} --target-end #{options[:end]} --target-chr #{options[:chr]} --target-strand #{options[:strand]} --species #{options[:species]} --dir #{options[:dir]}\n" +
      "EOF\n"

      if VERBOSE
        puts "#### COMMAND:"
        puts command
        puts "#### USER: '#{USER}'"
      end

     command
  end

  def target_region
    s = 0
    e = 0
    self.colony.mi_attempt.crisprs.each do |crispr|
      s = crispr.start.to_i if s == 0 || crispr.start.to_i < s.to_i
      e = crispr.end.to_i if e == 0 || crispr.end.to_i > e  .to_i
    end

    s -= 10
    e += 10

    return [s, e]
  end

  def crispr_damage_analysis options = {}

    if ! options[:force] && ! self.file_alignment.blank?
      puts "#### trace output already exists ( colony #{self.colony.id} trace call #{self.id})!" if VERBOSE
      return
    end

    if ! self.trace_file || self.trace_file_file_name.blank?
      puts "#### no trace file!" if VERBOSE
      return
    end

    options[:keep_generated_files] ||= KEEP_GENERATED_FILES

    output = error_output = exception = nil

    begin
      FileUtils.mkdir_p FOLDER_IN

      options[:remote] = true
      options[:chr] = self.colony.mi_attempt.mi_plan.gene.chr if ! options[:chr]

      strand_name = self.colony.mi_attempt.mi_plan.gene.strand_name == '-' ? '-' : ''
      options[:strand] = "#{strand_name}1" if ! options[:strand]

      options[:species] = "Mouse"
      options[:dir] = self.colony.id

      if ! options[:start] || ! options[:end]
        options[:start], options[:end] = self.target_region
      end

      filename = Dir::Tmpname.make_tmpname "#{FOLDER_IN}/", nil
      self.trace_file.copy_to_local_file('original', filename)

      puts "#### filename: #{filename}" if VERBOSE

      options[:file] = filename

      [:start, :end, :chr, :strand, :species, :file, :dir].each do |flag|
        raise "#### cannot find flag '#{flag}'!" if ! options.has_key? flag
      end

      error_output = nil
      exit_status = nil
      output = nil

      cmd = run_cmd options

      require "open3"

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

    rescue => e
      exception = e
      Rails.logger.error("#### crispr_damage_analysis: exception: #{e}")
      puts("#### crispr_damage_analysis: exception: #{e}")
    end

    folder_in                           = "#{FOLDER_IN}/#{self.colony.id}/#{self.id}"

    self.file_trace_output              = output
    self.file_trace_error               = error_output
    self.file_exception_details         = exception
    self.file_return_code               = exit_status

    self.file_alignment                 = save_file "#{folder_in}/alignment.txt"
    self.file_filtered_analysis_vcf     = save_file "#{folder_in}/filtered_analysis.vcf"
    self.file_variant_effect_output_txt = save_file "#{folder_in}/variant_effect_output.txt"
    self.file_reference_fa              = save_file "#{folder_in}/reference.fa"
    self.file_mutant_fa                 = save_file "#{folder_in}/mutated.fa"
    self.file_alignment_data_yaml       = save_file "#{folder_in}/alignment_data.yaml"
    self.file_merged_variants_vcf       = save_file "#{folder_in}/merge_vcf/merged_variants.vcf"

    filename                            = "#{folder_in}/primer_reads.fa"
    if File.exists?(filename)
      contents = File.open(filename).read
      data     = contents.lines.to_a[1..-1].join
      data.gsub!(/\s+/, "")
      self.file_primer_reads_fa = data
    end

    self.save!

    if options[:keep_generated_files]
      puts "#### check folder #{folder_in}"
      return
    end

    FileUtils.rm(Dir.glob("#{folder_in}/scf_to_seq/*.*"), :force => true)
    FileUtils.rmdir("#{folder_in}/scf_to_seq")

    FileUtils.rm(Dir.glob("#{folder_in}/merge_vcf/*.*"), :force => true)
    FileUtils.rmdir("#{folder_in}/merge_vcf")
    FileUtils.rm(Dir.glob("#{folder_in}/*.*"), :force => true)
    FileUtils.rmdir("#{folder_in}", :verbose => true)
  end

  def save_file(filename)
    return File.open(filename).read if File.exists?(filename)

    nil
  end

  def insertions_deletions type
    alignment_data = {}
    alignment_data = YAML.load(self.file_alignment_data_yaml) if ! self.file_alignment_data_yaml.blank?

    list = []

    if alignment_data.has_key? type
      if ['deletions', 'insertions'].include?(type)
        alignment_data[type].keys.each do |kk|
          array = alignment_data[type][kk]
          array.each do |frame|
            list.push "#{kk}: length: #{frame['length']} - read: #{frame['read']} - seq: #{frame['seq']}"
          end
        end
      else
        return alignment_data[type].to_i
      end
    end

    list
  end

  def only_select_target_region(seq_type)
    if seq_type == 'reference'
      seq = self.file_alignment.split("\n")[0]
    else
      seq = self.file_alignment.split("\n")[1]
    end
    target_start, target_end = self.target_region
    alignment_start = target_start - self.target_sequence_start
    alignment_length = target_end - target_start

    return seq[alignment_start, alignment_length]
  end

  def insertions
    insertions_deletions 'insertions'
  end

  def deletions
    insertions_deletions 'deletions'
  end

  def target_sequence_start
    insertions_deletions 'target_sequence_start'
  end

  def target_sequence_end
    insertions_deletions  'target_sequence_end'
  end

  def targeted_reference_sequence
    only_select_target_region('reference')
  end

  def targeted_mutated_sequence
    only_select_target_region('mutated')
  end

  def targeted_file_alignment
    return "#{targeted_reference_sequence}\n#{targeted_mutated_sequence}"
  end

  #TODO remove
  # this in shared/_colony_fields.html.erb <% ftc.object.save_trace_file_to_filepath('/Users/as28/tmp') %>
  # def save_trace_file_to_filepath( directory )
  #   return if self.trace_file_file_name.nil?

  #   begin
  #     puts "Saving trace file for colony #{self.colony.name} with id #{self.colony.id} and trace call #{self.id}"
  #     filename = Dir::Tmpname.make_tmpname "#{directory}/", nil
  #     self.trace_file.copy_to_local_file('original', filename)
  #   rescue => e
  #     puts "Exception:"
  #     puts e.inspect
  #     puts e.backtrace.join("\n")
  #   end
  # end

end

# == Schema Information
#
# Table name: trace_calls
#
#  id                             :integer          not null, primary key
#  colony_id                      :integer          not null
#  file_alignment                 :text
#  file_filtered_analysis_vcf     :text
#  file_variant_effect_output_txt :text
#  file_reference_fa              :text
#  file_mutant_fa                 :text
#  file_primer_reads_fa           :text
#  file_alignment_data_yaml       :text
#  file_trace_output              :text
#  file_trace_error               :text
#  file_exception_details         :text
#  file_return_code               :integer
#  file_merged_variants_vcf       :text
#  is_het                         :boolean          default(FALSE), not null
#  trace_file_file_name           :string(255)
#  trace_file_content_type        :string(255)
#  trace_file_file_size           :integer
#  trace_file_updated_at          :datetime
#
