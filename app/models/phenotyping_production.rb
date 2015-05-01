# encoding: utf-8

class PhenotypingProduction < ApplicationModel
  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute
  include PhenotypingProduction::StatusManagement
  include ApplicationModel::HasStatuses
  include ApplicationModel::BelongsToMiPlan

  belongs_to :mi_plan
  belongs_to :parent_colony, :class_name => 'Colony'
  belongs_to :status
  belongs_to :colony_background_strain, :class_name => 'Strain'

  has_many   :status_stamps, :order => "#{PhenotypingProduction::StatusStamp.table_name}.created_at ASC", dependent: :destroy

  access_association_by_attribute :parent_colony, :name
  access_association_by_attribute :colony_background_strain, :name

  accepts_nested_attributes_for :status_stamps


  protected :status=

  before_validation :allow_override_of_plan
  before_validation :change_status

  before_save :set_colony_background_strain
  before_save :set_phenotyping_experiments_started_if_blank
  before_save :set_phenotype_attempt_id
  after_save :manage_status_stamps


## BEFORE VALIDATION METHODS
  before_validation do |pp|
    if ! pp.colony_name.nil?
      pp.colony_name = pp.colony_name.to_s.strip || pp.colony_name
      pp.colony_name = pp.colony_name.to_s.gsub(/\s+/, ' ')
    end
  end

  def allow_override_of_plan
    return if self.consortium_name.blank? or self.production_centre_name.blank? or self.gene.blank?
    set_plan = MiPlan.find_or_create_plan(self, {:gene => self.gene, :consortium_name => self.consortium_name, :production_centre_name => self.production_centre_name, :phenotype_only => true}) do |pa|
      plan = pa.parent_colony.mi_plan
      if !plan.blank? and plan.consortium.try(:name) == self.consortium_name and plan.production_centre.try(:name) == self.production_centre_name
        plan = [plan]
      else
        plan = MiPlan.includes(:consortium, :production_centre, :gene).where("genes.marker_symbol = '#{self.gene.marker_symbol}' AND consortia.name = '#{self.consortium_name}' AND centres.name = '#{self.production_centre_name}' AND phenotype_only = true")
      end
    end
    self.mi_plan = set_plan
  end

## VALIDATION

  #mi_plan validatation
  validate do |pp|
    if pp.mi_plan.nil?
      pp.errors.add(:consortium_name, 'must be set')
      pp.errors.add(:centre_name, 'must be set')
      return
    end

    if mi_plan != parent_colony.mi_plan && mi_plan.phenotype_only == false
      pp.errors[:mi_plan] << 'must be either the same as the mouse production plan OR phenotype_only'
    end

    other_ids = []
    other_ids = PhenotypingProduction.includes(:mi_plan).where("
      mi_plans.consortium_id = #{pp.mi_plan.consortium_id} AND
      mi_plans.production_centre_id = #{pp.mi_plan.production_centre_id} AND
      parent_colony_id = #{pp.parent_colony_id}").map{|a| a.id} unless pp.parent_colony_id.blank?

    other_ids -= [self.id]
    if(other_ids.count != 0)
      pp.errors[:already] << 'has production for this consortium & production centre'
    end
  end

  validates :parent_colony, :presence => true
  validates :colony_name, :presence => true, :uniqueness => {:case_sensitive => false}, :allow_nil => false

  # colony_background_strain
  validate do |pp|
    if !colony_background_strain_name.blank? && Strain.find_by_name(colony_background_strain_name).blank?
      pp.errors.add(:colony_background_strain_name, 'Invalid colony background strain name')
    end
  end

  #genotype confirmed colony
  validate do |pp|
    if parent_colony && !(parent_colony.genotype_confirmed == true || parent_colony.mouse_allele_mod.try(:parent_colony).try(:genotype_confirmed) == true)
      pp.errors.add(:production_colony_name, "Must be 'Genotype confirmed'")
    end
  end

## BEFORE SAVE METHODS
  def set_colony_background_strain
    if colony_background_strain_name.blank?
      colony_background_strain = parent_colony.background_strain
    end
  end

  def set_phenotyping_experiments_started_if_blank
    #if phenotyping started or complete
    return unless self.phenotyping_experiments_started.blank?
    if ['pds', 'pdc'].include?(status.code)
      phenotyping_started_status_stamps = self.status_stamps.joins(:status).where("phenotyping_production_statuses.code = 'pds'")
      self.phenotyping_experiments_started = !phenotyping_started_status_stamps.blank? ? phenotyping_started_status_stamps.first.created_at : Time.now()
    end
  end
  protected :set_phenotyping_experiments_started_if_blank

  def set_phenotype_attempt_id
    return unless phenotype_attempt_id.blank?
    if !parent_colony.mouse_allele_mod_id.blank?
      self.phenotype_attempt_id = parent_colony.mouse_allele_mod.phenotype_attempt_id
    else
      paid = PhenotypeAttemptId.new
      paid.save
      self.phenotype_attempt_id = paid.id
    end
  end

  def generate_colony_name_if_blank
    return unless self.colony_name.blank?
    i = 0
    begin
      i += 1
      j = i > 0 ? "-#{i}" : ""
      new_colony_name = "#{self.parent_colony.name}_#{mi_plan.production_centre_name}#{j}"
    end until self.class.find_by_colony_name(new_colony_name).blank?
    self.colony_name = new_colony_name
  end


## METHODS
  def gene
    if mi_plan.try(:gene)
      return mi_plan.gene
    elsif parent_colony.try(:gene)
      return parent_colony.gene
    else
      return nil
    end
  end

  def status_name; status.try(:name); end

  def colony_background_strain_mgi_name
    colony_background_strain.try(:mgi_strain_name)
  end

  def colony_background_strain_mgi_accession
    colony_background_strain.try(:mgi_strain_accession_id)
  end

## CLASS METHODS

  def self.readable_name
    'phenotyping productions'
  end

end

# == Schema Information
#
# Table name: phenotyping_productions
#
#  id                              :integer          not null, primary key
#  mi_plan_id                      :integer          not null
#  status_id                       :integer          not null
#  colony_name                     :string(255)
#  phenotyping_experiments_started :date
#  phenotyping_started             :boolean          default(FALSE), not null
#  phenotyping_complete            :boolean          default(FALSE), not null
#  is_active                       :boolean          default(TRUE), not null
#  report_to_public                :boolean          default(TRUE), not null
#  phenotype_attempt_id            :integer
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  ready_for_website               :date
#  parent_colony_id                :integer
#  colony_background_strain_id     :integer
#  rederivation_started            :boolean          default(FALSE), not null
#  rederivation_complete           :boolean          default(FALSE), not null
#
