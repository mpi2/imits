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
  has_many :distribution_centres, :class_name => 'DistributionCentre', :dependent => :destroy
  has_many :trace_files, :dependent => :destroy
  has_many :alleles,  :dependent => :destroy

  access_association_by_attribute :background_strain, :name

  accepts_nested_attributes_for :trace_files, :allow_destroy => true
  accepts_nested_attributes_for :alleles, :allow_destroy => true
  accepts_nested_attributes_for :distribution_centres, :allow_destroy => true
  accepts_nested_attributes_for :phenotyping_productions, :allow_destroy => true

  validates :name, :presence => true
  # bit of a bodge but works.
  # would have liked to do
  ##  validates_uniqueness_of :name, conditions: -> { where("mi_attempt_id  IS NOT NULL") }
  ##  validates_uniqueness_of :name, conditions: -> { where("mouse_allele_mod_id  IS NOT NULL") }
#  validates_uniqueness_of :name, scope: :mi_attempt_id
#  validates_uniqueness_of :name, scope: :mouse_allele_mod_id



#  validate do |colony|
#    if mouse_allele_mod_id.blank? and mi_attempt_id.blank?
#      colony.errors.add :base, 'A Colony can only be produced via a Micro-Injection or an Allele Modification.'
#    end
#  end

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
    if alleles.all?{|a| a.allele_confirmed == false} && genotype_confirmed == true
      colony.errors.add :genotype_confirmed, "cannot be set to true unless the allele has been confirmed."
    end
  end

  before_save :set_default_background_strain_for_crispr_produced_colonies
  after_save :add_default_distribution_centre

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

end

# == Schema Information
#
# Table name: colonies
#
#  id                                          :integer          not null, primary key
#  name                                        :string(255)      not null
#  mi_attempt_id                               :integer
#  genotype_confirmed                          :boolean          default(FALSE)
#  report_to_public                            :boolean          default(FALSE)
#  mouse_allele_mod_id                         :integer
#  background_strain_id                        :integer
#  mgi_allele_symbol_without_impc_abbreviation :boolean          default(FALSE)
#
# Indexes
#
#  mouse_allele_mod_colony_name_uniqueness_index  (name,mi_attempt_id,mouse_allele_mod_id) UNIQUE
#
