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
  before_save :set_crispr_allele

  def set_genotype_confirmed
    if !mi_attempt.blank? && !mi_attempt.status.blank?
      if !mi_attempt.es_cell.blank? && mi_attempt.status.code == 'gtc'
        self.genotype_confirmed = true
      end
    end
  end
  protected :set_genotype_confirmed

  def set_crispr_allele
    if !mi_attempt.blank? && !mi_attempt.status.blank?
      if !mi_attempt.mutagenesis_factor_id.blank? && mi_attempt.status.code == 'gtc'
        n = 0
        gene = mi_attempt.marker_symbol
        while true
          n += 1
          test_allele_name = "em#{n}#{mi_attempt.production_centre.code}"
          break if Colony.joins(mi_attempt: {mi_plan: :gene}).where("genes.marker_symbol = '#{gene}' AND colonies.allele_name = '#{test_allele_name}'").blank?
        end

        self.allele_name = test_allele_name
      end
    end
  end
  protected :set_genotype_confirmed

  def self.readable_name
    return 'colony'
  end

  def get_mutant_nucleotide_sequence_features
    unless trace_call.trace_call_vcf_modifications.count > 0
      if trace_call.file_filtered_analysis_vcf
        vcf_data = trace_call.parse_filtered_vcf_file
        if vcf_data && vcf_data.length > 0
          vcf_data.each do |vcf_feature|
            if vcf_feature.length >= 6
              tc_mod = TraceCallVcfModification.new(
                :trace_call_id => trace_call.id,
                :mod_type      => vcf_feature['mod_type'],
                :chr           => vcf_feature['chr'],
                :start         => vcf_feature['start'],
                :end           => vcf_feature['end'],
                :ref_seq       => vcf_feature['ref_seq'],
                :alt_seq       => vcf_feature['alt_seq']
              )
              tc_mod.save!
            else
              puts "ERROR: unexpected length of VCF data for trace call id #{self.id}"
            end
          end
        end
      end
    end

    mut_seq_features = []

    trace_call.trace_call_vcf_modifications.each do |tc_mod|
      mut_seq_feature = {
        'chr'          => mi_attempt.gene.chr,
        'strand'       => mi_attempt.gene.strand_name,
        'start'        => tc_mod.start,
        'end'          => tc_mod.end,
        'ref_sequence' => tc_mod.ref_seq,
        'alt_sequence' => tc_mod.alt_seq,
        'sequence'     => tc_mod.alt_seq,
        'mod_type'     => tc_mod.mod_type
      }
      mut_seq_features.push( mut_seq_feature.as_json )
    end

    return mut_seq_features
  end
end

# == Schema Information
#
# Table name: colonies
#
#  id                                 :integer          not null, primary key
#  name                               :string(255)      not null
#  mi_attempt_id                      :integer
#  genotype_confirmed                 :boolean          default(FALSE)
#  report_to_public                   :boolean          default(FALSE)
#  unwanted_allele                    :boolean          default(FALSE)
#  unwanted_allele_description        :text
#  mgi_allele_id                      :string(255)
#  allele_name                        :string(255)
#  mouse_allele_mod_id                :integer
#  mgi_allele_symbol_superscript      :string(255)
#  allele_symbol_superscript_template :string(255)
#  allele_type                        :string(255)
#  background_strain_id               :integer
#
# Indexes
#
#  mouse_allele_mod_colony_name_uniqueness_index  (name,mi_attempt_id,mouse_allele_mod_id) UNIQUE
#
