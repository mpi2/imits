require 'tempfile'

class Colony < ApplicationModel

  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute

  belongs_to :mi_attempt
  belongs_to :mouse_allele_mod
  belongs_to :background_strain, :class_name => 'Strain'

  has_many :micro_injection_attempts, :class_name => 'MiAttempt', :foreign_key => 'parent_colony_id'
  has_many :allele_modifications, :class_name => 'MouseAlleleMod', :foreign_key => 'parent_colony_id'
  has_many :phenotyping_productions, :class_name => 'PhenotypingProduction', :foreign_key => 'parent_colony_id'

  has_many :distribution_centres, :class_name => 'Colony::DistributionCentre', :inverse_of => :colony, :dependent => :destroy
  has_many :alleles, :dependent => :destroy, :inverse_of => :colony

  has_one :trace_call, :inverse_of =>:colony, :dependent => :destroy, :class_name => "TraceCall"

  access_association_by_attribute :background_strain, :name

  accepts_nested_attributes_for :trace_call
  accepts_nested_attributes_for :alleles, :allow_destroy => true 
  accepts_nested_attributes_for :distribution_centres, :allow_destroy => true
  accepts_nested_attributes_for :phenotyping_productions, :allow_destroy => true

  before_validation do |col|
    if !col.mi_attempt.blank? && !col.mi_attempt.es_cell_id.blank?
      if col.mi_attempt.colonies.count == 1 && col.mi_attempt.status_id == 2
        col.genotype_confirmed = true
      else
        col.genotype_confirmed = false
      end
    end
    return true
  end

  before_validation :set_default_alleles
  before_validation :set_default_trace_file

  before_save :set_default_background_strain_for_crispr_produced_colonies

  after_save :add_default_distribution_centre

  after_save do |col|

    if !mi_attempt_id.blank? 
      parent_class = MiAttempt.find(col.mi_attempt_id)
    elsif !mouse_allele_mod_id.blank?
      parent_class = MouseAlleleMod.find(col.mouse_allele_mod_id)
    else
      return true
    end

    parent_class.change_status
    unless parent_class.changes.blank?
      parent_class.save
      parent_class.reload
    end
    return true
  end


  validates :name, :presence => true

  validate do |colony|
    if !mouse_allele_mod.blank?
      not_uniq_col = ActiveRecord::Base.connection.execute("SELECT  1 AS one FROM colonies  WHERE colonies.name = '#{self.name}' AND colonies.mouse_allele_mod_id IS NOT NULL #{self.id.blank? ? '' : "AND colonies.id != #{self.id}"} LIMIT 1")
      colony.errors.add :name, 'has already been taken.' if not_uniq_col.count > 0
    end

    if !mi_attempt.blank?
      not_uniq_col = ActiveRecord::Base.connection.execute("SELECT  1 AS one FROM colonies  WHERE colonies.name = '#{self.name}' AND colonies.mi_attempt_id IS NOT NULL #{self.id.blank? ? '' : "AND colonies.id != #{self.id}"} LIMIT 1")
      colony.errors.add :name, 'has already been taken.' if not_uniq_col.count > 0
    end
  end

  validate do |colony|
    if !mouse_allele_mod_id.blank? and !mi_attempt_id.blank?
      colony.errors.add :base, 'A Colony can only be produced either though a Micro-Injection or an Allele Modification, not both.'
    end
  end

  validate do |colony|
    if !mi_attempt_id.blank? and !mi_attempt.es_cell_id.blank?
      if Colony.where("mi_attempt_id = #{colony.mi_attempt_id} #{if !colony.id.blank?; "and id != #{colony.id}"; end}").count == 1
        colony.errors.add :base, 'Multiple Colonies are not allowed for Mi Attempts Micro-Injected with an ES Cell clone'
      end
    end
  end

  validate do |colony|
    if colony.unwanted_allele and colony.genotype_confirmed
      colony.errors.add :base, ": Colony '#{name}' cannot be marked as both 'Genotype Confirmed' and 'Unwanted Allele'"
    end
  end

  def set_default_alleles
    if alleles.blank?
      # TO DO should create a new allele for each mutagenesis_factor or one if es_cell_id is not blank
       allele_attr = [{:colony => self}]
       self.alleles_attributes = allele_attr
     end
  end
  protected :set_default_alleles

  def set_default_trace_file
    if !mi_attempt_id.blank? && !mi_attempt.mutagenesis_factor.blank? && trace_call.blank?
       trace_call_attr = {}
       self.trace_call_attributes = trace_call_attr 
    end
  end
  protected :set_default_trace_file

  def set_default_background_strain_for_crispr_produced_colonies
    return unless self.background_strain_id.blank?
    return if self.mi_attempt_id.blank?
    return unless self.mi_attempt.es_cell.blank?

    self.background_strain_name = 'C57BL/6N'
  end
  protected :set_default_background_strain_for_crispr_produced_colonies

  def add_default_distribution_centre
    if self.genotype_confirmed and self.distribution_centres.count == 0
      centre = production_centre_name
      if centre == 'UCD'
        centre = 'KOMP Repo'
      end
      distribution_centre = Colony::DistributionCentre.new({:colony_id => self.id, :centre_name => centre, :deposited_material_name => 'Live mice'})
      if centre == 'TCP' && consortium_name == 'NorCOMM2'
        distribution_centre.distribution_network = 'CMMR'
      elsif centre == 'TCP' && ['UCD-KOMP', 'DTCC'].include?(consortium_name)
        distribution_centre.centre = Centre.find_by_name('KOMP Repo')
      elsif centre == 'WTSI' and ['EUCOMM', 'EUCOMMTools'].include?(pipeline_name)
        distribution_centre.distribution_network = 'EMMA'
      end
      raise "Could not save DEFAULT distribution Centre" if !distribution_centre.valid?
      distribution_centre.save
    end
  end
  protected :add_default_distribution_centre

  def gene
    return mi_attempt.mi_plan.gene if !mi_attempt_id.blank?
    return mouse_allele_mod.mi_plan.gene if !mouse_allele_mod_id.blank?
    return nil
  end

  def marker_symbol
    gene.try(:marker_symbol)
  end

  def mi_plan
    return mi_attempt.mi_plan if !mi_attempt_id.blank?
    return mouse_allele_mod.mi_plan if !mouse_allele_mod_id.blank?
    return nil
  end

  def production_centre_name
    return mouse_allele_mod.production_centre_name unless mouse_allele_mod.blank?
    return mi_attempt.production_centre_name unless mi_attempt.blank?
    return nil
  end

  def consortium_name
    return mouse_allele_mod.consortium_name unless mouse_allele_mod.blank?
    return mi_attempt.consortium_name unless mi_attempt.blank?
    return nil
  end

  def pipeline_name
    return mouse_allele_mod.parent_colony.pipeline_name unless mouse_allele_mod.blank?
    return mi_attempt.es_cell.try(:pipeline).try(:name) unless mi_attempt.blank? || mi_attempt.es_cell.blank?
    return nil
  end

  def distribution_centres_attributes
    return distribution_centres.map(&:as_json) unless distribution_centres.blank?
    return nil
  end

  def alleles_attributes
    return alleles.map(&:as_json) unless alleles.blank?
    return nil
  end

  def trace_call_attributes
    return trace_call(&:as_json) unless trace_call.blank?
    return nil
  end

  def distribution_centres_formatted_display
    output_string = ''
    self.distribution_centres.each do |distribution_centre|
      output_array = []
      if distribution_centre.distribution_network
        output_array << distribution_centre.distribution_network
      end
      output_array << distribution_centre.centre.name
      if !distribution_centre.deposited_material.name.nil?
        output_array << distribution_centre.deposited_material.name
      end
      output_string << "[#{output_array.join(', ')}] "
    end
    return output_string.strip
  end

  def create_phenotype_attempt_for_komp2
    consortia_to_check = ["BaSH", "DTCC", "JAX"]
    if !self.mi_attempt_id.blank? && genotype_confirmed == true && consortia_to_check.include?(mi_attempt.consortium.name)
      unless phenotype_attempts_count > 0
        phenotype_attempt_create
      end
    end
  end

  def phenotype_attempt_create
    return if mi_attempt_id.blank?
    colony_name = self.name
    i = 0
    begin
      i += 1
      j = i > 0 ? "-#{i}" : ""
      new_colony_name = "#{colony_name}#{j}"
    end until self.class.find_by_name(new_colony_name).blank?
    colony_name = new_colony_name

    pa = Public::PhenotypeAttempt.new ({:mi_attempt_colony_name => self.name, :mi_plan_id => self.mi_attempt.mi_plan_id, :colony_name => colony_name})
    pa.save
    raise "Could not create Phenotype Attempt #{pa.errors.messages}" unless pa.errors.messages.blank?
  end

  def phenotype_attempts_count
    self.allele_modifications.length + self.phenotyping_productions.length
  end

  def self.readable_name
    return 'colony'
  end

  def self.group_colonies_by_mi_attempt_sql
    return <<-EOF
                SELECT ordered_colonies.mi_attempt_id, string_agg(ordered_colonies.colony_name, ', ') AS colony_name
                FROM (
                    SELECT colonies.mi_attempt_id AS mi_attempt_id, colonies.name AS colony_name
                    FROM colonies
                    ORDER BY colonies.mi_attempt_id, colonies.genotype_confirmed
                    ) AS ordered_colonies
                GROUP BY ordered_colonies.mi_attempt_id
            EOF
  end


  #### may not work, should this be in trace call model
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
        'chr'          => mi_attempt.mi_plan.gene.chr,
        'strand'       => mi_attempt.mi_plan.gene.strand_name,
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
#  report_to_public                   :boolean          default(TRUE)
#  unwanted_allele                    :boolean          default(FALSE)
#  allele_description                 :text
#  mgi_allele_id                      :string(255)
#  allele_name                        :string(255)
#  mouse_allele_mod_id                :integer
#  mgi_allele_symbol_superscript      :string(255)
#  allele_symbol_superscript_template :string(255)
#  allele_type                        :string(255)
#  background_strain_id               :integer
#  allele_description_summary         :text
#  auto_allele_description            :text
#  is_released_from_genotyping        :boolean          default(FALSE)
#  genotyping_comment                 :text
#
# Indexes
#
#  mouse_allele_mod_colony_name_uniqueness_index  (name,mi_attempt_id,mouse_allele_mod_id) UNIQUE
#
