require 'tempfile'

class Colony < ActiveRecord::Base

  acts_as_audited
  acts_as_reportable

  belongs_to :mi_attempt

  has_one :colony_qc, :inverse_of => :colony, :dependent => :destroy
  has_one :trace_call, :inverse_of =>:colony, :dependent => :destroy, :class_name => "TraceCall"

  accepts_nested_attributes_for :colony_qc
  accepts_nested_attributes_for :trace_call

  validates :name, :presence => true, :uniqueness => true

  # has_attached_file :trace_file, :storage => :database

  # do_not_validate_attachment_file_type :trace_file

  validate do |colony|
    if !mi_attempt_id.blank? and !mi_attempt.es_cell_id.blank?
      if Colony.where("mi_attempt_id = #{colony.mi_attempt_id} #{if !colony.id.blank?; "and id != #{colony.id}"; end}").count == 1
        colony.errors.add :base, 'Multiple Colonies are not allowed for Mi Attempts micro-injected with an ES Cell clone'
      end
    end
  end

  validate do |colony|
    if colony.unwanted_allele and colony.genotype_confirmed
      colony.errors.add :base, ": Colony '#{name}' cannot be marked as both 'Genotype Confirmed' and 'Unwanted Allele'"
    end
  end

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

  def get_mutant_nucleotide_sequence_feature

    mut_seq_feature = {
      'chr'      => mi_attempt.mi_plan.gene.chr,
      'strand'   => mi_attempt.mi_plan.gene.strand_name
    }

    if trace_call.file_filtered_analysis_vcf
      vcf_data = trace_call.parse_filtered_vcf_file
      # example:
      # {"chr"=>"6",
      #  "strand"=>"-",
      #  "start"=>136781533,
      #  "end"=>136781560,
      #  "ref_seq"=>"TGAGAGGCCCAGAACACCATCAGCGCG",
      #  "alt_seq"=>"TG"}

      mut_seq_feature['start']        = vcf_data['start']
      mut_seq_feature['end']          = vcf_data['end']
      mut_seq_feature['ref_sequence'] = vcf_data['ref_seq']
      mut_seq_feature['alt_sequence'] = vcf_data['alt_seq']
      mut_seq_feature['sequence']     = vcf_data['alt_seq']
    end

    alignment_file = trace_call.targeted_file_alignment

    if alignment_file
      # determine start and end coordinates
      # tr_start, tr_end = trace_call.target_region

      index = 0
      # mut_seq_feature = {
      #   'mut_type' => '',
      #   'sequence' => '',

      #   # ,
      #   # 'start'    => tr_start,
      #   # 'end'      => tr_end
      # }

      alignment_file.each_line do |line|
        index += 1
        stripped_line = line.strip

        if index == 1
          if match = stripped_line.match(/\w*(-*)\w*/i)
            mut_seq_feature['type']               = 'insertion'
            mut_seq_feature['alignment_sequence'] = stripped_line
          end
        else
          if match = stripped_line.match(/\w*(-*)\w*/i)
            mut_seq_feature['type']               = 'deletion'
            mut_seq_feature['alignment_sequence'] = stripped_line
          end
        end
      end

      # e.g. for deletion: gap on btm
      # "TGCGCGACCTCCGAACGCCCACATGCTACTCCAGCTCCGCGG"
      # "TGCGCGACCTC----CGCCCACATGCTACTCCAGCTCCGCGG"

      # e.g. insertion? gap on top?
      # "TGCGCGACCTC----CGCCCACATGCTACTCCAGCTCCGCGG"
      # "TGCGCGACCTCCGAACGCCCACATGCTACTCCAGCTCCGCGG"

    else
      puts "ERROR: no alignment file found"
    end

    mut_seq_features = []
    mut_seq_features.push( mut_seq_feature.as_json )

    return mut_seq_features
  end
end

# == Schema Information
#
# Table name: colonies
#
#  id                          :integer          not null, primary key
#  name                        :string(255)      not null
#  mi_attempt_id               :integer
#  genotype_confirmed          :boolean          default(FALSE)
#  report_to_public            :boolean          default(FALSE)
#  unwanted_allele             :boolean          default(FALSE)
#  unwanted_allele_description :text
#
# Indexes
#
#  colony_name_index  (name) UNIQUE
#
