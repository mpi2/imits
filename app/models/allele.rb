class Allele < ActiveRecord::Base
  include ::Public::Serializable

  acts_as_audited
  acts_as_reportable

  FULL_ACCESS_ATTRIBUTES = %w{
    mgi_allele_symbol_without_impc_abbreviation
    mgi_allele_symbol_superscript
    mgi_allele_accession_id
    allele_type
    auto_allele_description
    allele_description
    mutant_fa
    production_centre_qc_attributes
  }

  READABLE_ATTRIBUTES = %w{
    id
  }

  attr_accessible(*FULL_ACCESS_ATTRIBUTES)

  belongs_to :colony
  belongs_to :es_cell, :class_name => 'TargRepEsCell'

  has_many :vcf_modifications

  has_one :production_centre_qc, :inverse_of => :allele, :dependent => :destroy

  accepts_nested_attributes_for :production_centre_qc, :update_only =>true


  validates :allele_type, :inclusion => { :in => MOUSE_ALLELE_OPTIONS.keys + CRISPR_MOUSE_ALLELE_OPTIONS.keys }
  validate :set_allele_symbol_superscript
  validates_format_of :mgi_allele_accession_id,
    :with      => /^MGI\:\d+$/,
    :message   => "is not a valid MGI Allele ID",
    :allow_nil => true

  def production_centre_qc_attributes
    json_options = {
    :except => ['id']
    }
    return mutagenesis_factor.as_json(json_options)
  end
  # before_save :check_changed
  # after_save :change_colony_allele_description


#  validate do |colony|
#    return if mi_attempt_id.blank? && mouse_allele_mod_id.blank?
#    if !mgi_allele_symbol_superscript.blank?
#      mi_attempt = self.mi_attempt || mouse_allele_mod.parent_colony.mi_attempt
#      
#      if mi_attempt.es_cell.blank?
#
#        if mgi_allele_symbol_without_impc_abbreviation == false && /em\d*/
#          colony.errors.add :mgi_allele_symbol_superscript, "is invalid. Must have the following format em{Serial number from the laboratory of origin}{ILAR code} e.g. em1J"
#          colony.errors.add :mgi_allele_symbol_superscript, "cannot be blank if mouse colony has been set to Genotype Confirmed."
#        elsif /em\d+(IMPC)*/
#          colony.errors.add :mgi_allele_symbol_superscript, "is invalid. Must have the following format em{Serial number from the laboratory of origin}(IMPC){ILAR code} e.g. em1(IMPC)J"
#          colony.errors.add :mgi_allele_symbol_superscript, "must contain IMPC unless marked project abbreviation."       
#        end
#      else
#
#
#      end
#     
#     mgi_allele_symbol_without_impc_abbreviation == true
#      colony.errors.add :mgi_allele_symbol_superscript, "cannot be blank if mouse colony has been set to Genotype Confirmed."
#    end
#  end

#  def get_template
#    return allele_symbol_superscript_template unless allele_symbol_superscript_template.blank?
#
#    if mi_attempt_id
#
#      if mi_attempt.es_cell_id
#        return mi_attempt.es_cell.allele_symbol_superscript_template
#      elsif mi_attempt.mutagenesis_factor && !mgi_allele_symbol_superscript.blank?
#          return mgi_allele_symbol_superscript
#      else
#        return nil
#      end
#
#    elsif mouse_allele_mod_id
#
#      return mouse_allele_mod.try(:parent_colony).try(:get_template)
#
#    else
#      return nil
#    end
#  end
# # protected :get_template
#
#  def get_type
#    return allele_type unless allele_type.nil?
#
#    if mi_attempt_id
#
#      if mi_attempt.es_cell_id
#        return mi_attempt.es_cell.allele_type
#      else
#        return 'None'
#      end
#
#    elsif mouse_allele_mod_id
#
#      return mouse_allele_mod.try(:parent_colony).try(:get_type)
#
#    else
#      return 'None'
#    end
#  end
  #protected :get_type

#  def set_allele_symbol_superscript
#    return if self.allele_symbol_superscript_template_changed?
#
#    if self.mgi_allele_symbol_superscript.blank? || self.mgi_allele_symbol_superscript =~ /em/
#      self.allele_symbol_superscript_template = nil
#      return
#    end
#
#    # if targeted allele.
#    new_template, new_allele_type, errors = TargRep::Allele.extract_symbol_superscript_template(mgi_allele_symbol_superscript)
#
#    #prevent MGI from incorrectly overiding the allele name if the allele type does not match that stated by the centres.
#    if !self.allele_type.nil? && self.allele_type == new_allele_type
#      self.allele_symbol_superscript_template = new_template
#    else
#      self.mgi_allele_symbol_superscript = nil
#    end
#
#    if errors.count > 0
#      self.errors.add errors.first[0], errors.first[1]
#    end
#  end
#
#
#  def allele_symbol_superscript
#    template = get_template
#    type = get_type.to_s
#
#    return nil if template.nil?
#
#    if template =~ /#{TargRep::Allele::TEMPLATE_CHARACTER}/
#      if type == 'None'
#        return nil
#      else
#        return template.sub(TargRep::Allele::TEMPLATE_CHARACTER, type)
#      end
#    else
#      return template
#    end
#  end

#  def allele_symbol
#    if allele_symbol_superscript
#      return "#{self.gene.marker_symbol}<sup>#{allele_symbol_superscript}</sup>"
#    else
#      return nil
#    end
#  end


  #### may not work, should this be in trace call model
#  def get_mutant_nucleotide_sequence_features
#    unless allele_call.allele_call_vcf_modifications.count > 0
#      if allele_call.file_filtered_analysis_vcf
#        vcf_data = allele_call.parse_filtered_vcf_file
#        if vcf_data && vcf_data.length > 0
#          vcf_data.each do |vcf_feature|
#            if vcf_feature.length >= 6
#              tc_mod = TraceCallVcfModification.new(
#                :allele_call_id => allele_call.id,
#                :mod_type      => vcf_feature['mod_type'],
#                :chr           => vcf_feature['chr'],
#                :start         => vcf_feature['start'],
#                :end           => vcf_feature['end'],
#                :ref_seq       => vcf_feature['ref_seq'],
#                :alt_seq       => vcf_feature['alt_seq']
#              )
#              tc_mod.save!
#            else
#              puts "ERROR: unexpected length of VCF data for trace call id #{self.id}"
#            end
#          end
#        end
#      end
#    end
#
#    mut_seq_features = []
#
#    allele_call.allele_call_vcf_modifications.each do |tc_mod|
#      mut_seq_feature = {
#        'chr'          => mi_attempt.mi_plan.gene.chr,
#        'strand'       => mi_attempt.mi_plan.gene.strand_name,
#        'start'        => tc_mod.start,
#        'end'          => tc_mod.end,
#        'ref_sequence' => tc_mod.ref_seq,
#        'alt_sequence' => tc_mod.alt_seq,
#        'sequence'     => tc_mod.alt_seq,
#        'mod_type'     => tc_mod.mod_type
#      }
#      mut_seq_features.push( mut_seq_feature.as_json )
#    end
#
#    return mut_seq_features
#  end



### CALLBACK METHODS

  # def check_changed
  #   if trace_file_file_name_changed?
  #     self.file_alignment = nil
  #     self.file_return_code = nil
  #     self.file_exception_details = nil
  #   end
  # end
  # protected :check_changed

  # def change_colony_allele_description
  #   colony = self.colony

  #   allele_mutation_summary = {}

  #   [colony.trace_call].each do |tc|
  #     next if tc.allele_call_vcf_modifications.count == 0

  #     allele_mutation_summary[self.exon_id] = {'ins' => 0, 'del' => 0}
  #     tc.allele_call_vcf_modifications.each do |tcvm|

  #       next unless ['ins', 'del'].include?(tcvm.mod_type)
  #       allele_mutation_summary[self.exon_id][tcvm.mod_type] += (tcvm.alt_seq.length - tcvm.ref_seq.length).abs
  #     end
  #   end

  #   description = allele_mutation_summary.map{|exon, mutation| "#{ mutation['del'] != 0 ? "#{mutation['del']}bp deletion" : '' }#{ mutation['del'] != 0 && mutation['ins'] != 0 ? " and " : ''}#{ mutation['ins'] != 0 ? "#{mutation['ins']}bp insertion" : '' }#{!exon.blank? ? " in #{exon}" : '' }"}.join(' and ')

  #   if !description.blank?
  #     colony.update_column(:auto_allele_description, "Frameshift mutation caused by a #{description}")
  #   end

  # end
  # protected :change_colony_allele_description




### VALIDATION METHODS

  # SYNC                 = false
  # VERBOSE              = false
  # KEEP_GENERATED_FILES = false
  # USER                 = (ENV['USER'] || `whoami`).chomp

  # FOLDER_IN = "/nfs/team87/imits/trace_files_output/#{Rails.env}/#{USER}"

  # def trace_data_pending
  #   file_alignment.blank? && ! self.trace_file_file_name.blank?
  # end

  # def trace_data_available
  #   ! file_alignment.blank?
  # end

  # def trace_data_error
  #   file_return_code.to_i != 0
  # end

  # def file_error
  #   return nil if file_return_code.to_i == 0

  #   data = file_trace_error.to_s.lines.to_a[-1..-1].join
  #   data.gsub!(/\s+at\s+.+/, "")
  #   data.chomp
  # end

  # def run_cmd options

  #   file_flag = "--scf-file"
  #   file_flag = "--het-scf-file" if self.is_het?

  #   command = "ssh -o CheckHostIP=no t87-dev /bin/bash << EOF\n" +
  #     "source /opt/t87/global/conf/bashrc;\n" +
  #     "use lims2-devel;\n" +
  #     "export DEFAULT_CRISPR_DAMAGE_QC_DIR=#{FOLDER_IN};\n" +
  #     "crispr_damage_analysis.pl #{file_flag} #{options[:file]} --target-start #{options[:start]} --target-end #{options[:end]} --target-chr #{options[:chr]} --target-strand #{options[:strand]} --species #{options[:species]} --dir #{options[:dir]}\n" +
  #     "EOF\n"

  #     if VERBOSE
  #       puts "#### COMMAND:"
  #       puts command
  #       puts "#### USER: '#{USER}'"
  #     end

  #    command
  # end

  # def target_region
  #   s = 0
  #   e = 0
  #   self.colony.mi_attempt.crisprs.each do |crispr|
  #     s = crispr.start.to_i if s == 0 || crispr.start.to_i < s.to_i
  #     e = crispr.end.to_i if e == 0 || crispr.end.to_i > e  .to_i
  #   end

  #   s -= 10
  #   e += 10

  #   return [s, e]
  # end

  # def crispr_damage_analysis options = {}

  #   if ! options[:force] && ! self.file_alignment.blank?
  #     puts "#### trace output already exists ( colony #{self.colony.id} trace call #{self.id})!" if VERBOSE
  #     return
  #   end

  #   if ! self.trace_file || self.trace_file_file_name.blank?
  #     puts "#### no trace file!" if VERBOSE
  #     return
  #   end

  #   options[:keep_generated_files] ||= KEEP_GENERATED_FILES

  #   output = error_output = exception = nil

  #   begin
  #     FileUtils.mkdir_p FOLDER_IN

  #     options[:remote] = true
  #     options[:chr] = self.colony.mi_attempt.mi_plan.gene.chr if ! options[:chr]

  #     strand_name = self.colony.mi_attempt.mi_plan.gene.strand_name == '-' ? '-' : ''
  #     options[:strand] = "#{strand_name}1" if ! options[:strand]

  #     options[:species] = "Mouse"
  #     options[:dir] = "#{self.colony.id}/#{self.id}"

  #     if ! options[:start] || ! options[:end]
  #       options[:start], options[:end] = self.target_region
  #     end

  #     filename = Dir::Tmpname.make_tmpname "#{FOLDER_IN}/", nil
  #     self.trace_file.copy_to_local_file('original', filename)

  #     puts "#### filename: #{filename}" if VERBOSE

  #     options[:file] = filename

  #     [:start, :end, :chr, :strand, :species, :file, :dir].each do |flag|
  #       raise "#### cannot find flag '#{flag}'!" if ! options.has_key? flag
  #     end

  #     error_output = nil
  #     exit_status = nil
  #     output = nil

  #     cmd = run_cmd options

  #     require "open3"

  #     Open3.popen3("#{cmd}") do |scriptin, scriptout, scripterr, wait_thr|
  #       error_output = scripterr.read
  #       exit_status  = wait_thr.value.exitstatus
  #       output       = scriptout.read
  #     end

  #     FileUtils.rm(filename, :force => true)

  #     if VERBOSE
  #       puts "#### error_output:"
  #       puts error_output
  #       puts "#### exit_status:"
  #       puts exit_status
  #       puts "#### output:"
  #       puts output
  #     end

  #   rescue => e
  #     exception = e
  #     Rails.logger.error("#### crispr_damage_analysis: exception: #{e}")
  #     puts("#### crispr_damage_analysis: exception: #{e}")
  #   end

  #   output_colony_dir                   = "#{FOLDER_IN}/#{self.colony.id}"
  #   output_trace_call_dir               = "#{FOLDER_IN}/#{self.colony.id}/#{self.id}"

  #   self.file_trace_output              = output
  #   self.file_trace_error               = error_output
  #   self.file_exception_details         = exception
  #   self.file_return_code               = exit_status

  #   self.file_alignment                 = save_file "#{output_trace_call_dir}/alignment.txt"
  #   self.file_filtered_analysis_vcf     = save_file "#{output_trace_call_dir}/filtered_analysis.vcf"
  #   self.variant_effect_predictor_output = save_file "#{output_trace_call_dir}/variant_effect_output.txt"
  #   self.file_reference_fa              = save_file "#{output_trace_call_dir}/reference.fa"
  #   self.file_mutant_fa                 = save_file "#{output_trace_call_dir}/mutated.fa"
  #   self.file_alignment_data_yaml       = save_file "#{output_trace_call_dir}/alignment_data.yaml"
  #   self.file_merged_variants_vcf       = save_file "#{output_trace_call_dir}/merge_vcf/merged_variants.vcf"

  #   filename                            = "#{output_trace_call_dir}/primer_reads.fa"

  #   if File.exists?(filename)
  #     contents                  = File.open(filename).read
  #     data                      = contents.lines.to_a[1..-1].join
  #     data.gsub!(/\s+/, "")
  #     self.file_primer_reads_fa = data
  #   end

  #   parse_filtered_vep_file

  #   updated = self.save!

  #   # parse some details from the filtered_analysis file
  #   if self.file_filtered_analysis_vcf
  #     vcf_data = parse_filtered_vcf_file
  #     if vcf_data && vcf_data.length > 0
  #       vcf_data.each do |vcf_feature|
  #         if vcf_feature.length >= 6
  #           tc_mod = TraceCallVcfModification.new(
  #             :trace_call_id => self.id,
  #             :mod_type      => vcf_feature['mod_type'],
  #             :chr           => vcf_feature['chr'],
  #             :start         => vcf_feature['start'],
  #             :end           => vcf_feature['end'],
  #             :ref_seq       => vcf_feature['ref_seq'],
  #             :alt_seq       => vcf_feature['alt_seq']
  #           )
  #           tc_mod.save!
  #         else
  #           puts "ERROR: unexpected length of VCF data for trace call id #{self.id}"
  #         end
  #       end
  #     end
  #   end

  #   if options[:keep_generated_files]
  #     puts "#### check folder #{output_trace_call_dir}"
  #     return updated
  #   end

  #   change_colony_allele_description

  #   FileUtils.rm(Dir.glob("#{output_trace_call_dir}/scf_to_seq/*.*"), :force => true)
  #   FileUtils.rmdir("#{output_trace_call_dir}/scf_to_seq")

  #   FileUtils.rm(Dir.glob("#{output_trace_call_dir}/merge_vcf/*.*"), :force => true)
  #   FileUtils.rmdir("#{output_trace_call_dir}/merge_vcf")
  #   FileUtils.rm(Dir.glob("#{output_trace_call_dir}/*.*"), :force => true)
  #   FileUtils.rmdir("#{output_trace_call_dir}", :verbose => true)
  #   FileUtils.rmdir("#{output_colony_dir}", :verbose => true)

  #   cmd = nil

  #   return updated
  # end

  # def save_file(filename)
  #   return File.open(filename).read if File.exists?(filename)

  #   nil
  # end

  # def insertions_deletions type
  #   alignment_data = {}
  #   alignment_data = YAML.load(self.file_alignment_data_yaml) if ! self.file_alignment_data_yaml.blank?

  #   list = []

  #   if alignment_data.has_key? type
  #     if ['deletions', 'insertions'].include?(type)
  #       alignment_data[type].keys.each do |kk|
  #         array = alignment_data[type][kk]
  #         array.each do |frame|
  #           list.push "#{kk}: length: #{frame['length']} - read: #{frame['read']} - seq: #{frame['seq']}"
  #         end
  #       end
  #     else
  #       return alignment_data[type].to_i
  #     end
  #   end

  #   list
  # end

  # def only_select_target_region(seq_type)
  #   if seq_type == 'reference'
  #     seq = self.file_alignment.split("\n")[0]
  #   else
  #     seq = self.file_alignment.split("\n")[1]
  #   end
  #   target_start, target_end = self.target_region
  #   alignment_start = target_start - self.target_sequence_start
  #   alignment_length = target_end - target_start

  #   return seq[alignment_start, alignment_length]
  # end

  # def insertions
  #   insertions_deletions 'insertions'
  # end

  # def deletions
  #   insertions_deletions 'deletions'
  # end

  # def target_sequence_start
  #   insertions_deletions 'target_sequence_start'
  # end

  # def targeted_reference_sequence
  #   only_select_target_region('reference')
  # end

  # def targeted_mutated_sequence
  #   only_select_target_region('mutated')
  # end

  # def targeted_file_alignment
  #   return "#{targeted_reference_sequence}\n#{targeted_mutated_sequence}"
  # end

  # def parse_filtered_vep_file

  #   return if self.variant_effect_predictor_output.blank?

  #   self.variant_effect_predictor_output.each_line do |line|
  #     stripped_line = line.strip
  #     next if stripped_line[0] == '#'

  #     parsed_fields = stripped_line.split("\t")

  #     if parsed_fields.length >= 4
  #       self.exon_id = parsed_fields[4]
  #     end
  #   end
  # end


  # def parse_filtered_vcf_file
  #   vcf_data = []

  #   self.file_filtered_analysis_vcf.each_line do |line|
  #       stripped_line = line.strip
  #       next if stripped_line[0] == '#'

  #       parsed_fields = stripped_line.split("\t")
  #       # break

  #       if parsed_fields.length >= 4
  #         ref_seq = parsed_fields[3]
  #         alt_seq = parsed_fields[4]

  #         # compare sequences to determine whether snp, or indel
  #         if alt_seq.length == ref_seq.length
  #           mod_type   = 'snp'
  #           seq_length = alt_seq.length
  #         elsif ref_seq.length > alt_seq.length
  #           mod_type   = 'del'
  #           seq_length = ref_seq.length - alt_seq.length
  #         elsif ref_seq.length < alt_seq.length
  #           mod_type   = 'ins'
  #           seq_length = alt_seq.length - ref_seq.length
  #         else
  #           puts "ERROR: cannot understand this line"
  #           puts line
  #           next
  #         end

  #         vcf_data.push({
  #           'chr'      => parsed_fields[0],
  #           'start'    => parsed_fields[1].to_i + 1,
  #           'end'      => parsed_fields[1].to_i + seq_length,
  #           'ref_seq'  => ref_seq,
  #           'alt_seq'  => alt_seq,
  #           'mod_type' => mod_type
  #         })
  #       end
  #   end

  #   return vcf_data
  # end


  # def get_mutant_nucleotide_sequence_features
  #   unless trace_call.allele_call_vcf_modifications.count > 0
  #     if trace_call.file_filtered_analysis_vcf
  #       vcf_data = trace_call.parse_filtered_vcf_file
  #       if vcf_data && vcf_data.length > 0
  #         vcf_data.each do |vcf_feature|
  #           if vcf_feature.length >= 6
  #             tc_mod = TraceCallVcfModification.new(
  #               :trace_call_id => trace_call.id,
  #               :mod_type      => vcf_feature['mod_type'],
  #               :chr           => vcf_feature['chr'],
  #               :start         => vcf_feature['start'],
  #               :end           => vcf_feature['end'],
  #               :ref_seq       => vcf_feature['ref_seq'],
  #               :alt_seq       => vcf_feature['alt_seq']
  #             )
  #             tc_mod.save!
  #           else
  #             puts "ERROR: unexpected length of VCF data for trace call id #{self.id}"
  #           end
  #         end
  #       end
  #     end
  #   end

  #   mut_seq_features = []

  #   trace_call.allele_call_vcf_modifications.each do |tc_mod|
  #     mut_seq_feature = {
  #       'chr'          => mi_attempt.mi_plan.gene.chr,
  #       'strand'       => mi_attempt.mi_plan.gene.strand_name,
  #       'start'        => tc_mod.start,
  #       'end'          => tc_mod.end,
  #       'ref_sequence' => tc_mod.ref_seq,
  #       'alt_sequence' => tc_mod.alt_seq,
  #       'sequence'     => tc_mod.alt_seq,
  #       'mod_type'     => tc_mod.mod_type
  #     }
  #     mut_seq_features.push( mut_seq_feature.as_json )
  #   end

  #   return mut_seq_features
  # end

end

# == Schema Information
#
# Table name: alleles
#
#  id                                          :integer          not null, primary key
#  colony_id                                   :integer          not null
#  allele_confirmed                            :boolean          default(FALSE), not null
#  mgi_allele_symbol_without_impc_abbreviation :boolean
#  mgi_allele_symbol_superscript               :string(255)
#  mgi_allele_accession_id                     :string(255)
#  allele_type                                 :string(255)
#  auto_allele_description                     :text
#  allele_description                          :text
#  mutant_fa                                   :text
#  reference_fa                                :text
#  mutant_protein_fa                           :text
#  reference_protein_fa                        :text
#  alignment                                   :text
#  filtered_analysis_vcf                       :text
#  merged_variants_vcf                         :text
#  variant_effect_predictor_output             :text
#  primer_reads_fa                             :text
#  alignment_data_yaml                         :text
#  trace_output                                :text
#  trace_error                                 :text
#  exception_details                           :text
#  return_code                                 :integer
#  exon_id                                     :string(255)
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null
#
