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

  access_association_by_attribute :colony_background_strain, :name
  access_association_by_attribute :parent_colony, :name

  accepts_nested_attributes_for :status_stamps


  protected :status=

  before_validation :allow_override_of_plan
  before_validation :change_status

  after_save :manage_status_stamps
## VALIDATION

  #mi_plan validatation
  validate do |pp|
    if pp.mi_plan.nil?
      pp.errors.add(:consortium_name, 'must be set')
      pp.errors.add(:centre_name, 'must be set')
      return
    end

    other_ids = PhenotypingProduction.includes(:mi_plan).where("
      mi_plans.consortium_id = #{pp.mi_plan.consortium_id} AND
      mi_plans.production_centre_id = #{pp.mi_plan.production_centre_id} AND
      parent_colony_id = #{pp.parent_colony_id}").map{|a| a.id}

    other_ids -= [self.id]
    if(other_ids.count != 0)
      pp.errors[:already] << 'has production for this consortium & production centre'
    end
  end

  validates :parent_colony, :presence => true
  validates :colony_name, :presence => true, :uniqueness => {:case_sensitive => false}, :allow_nil => false


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

## BEFORE VALIDATION FUNCTIONS
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

  def status_name; status.name; end

## CLASS METHODS

  def self.create_or_update_from_phenotype_attempt(phenotype_attempt)
    raise PhenotypeAttemptError, "Must pass phenotype_attempt as a parameter." if phenotype_attempt.blank?
    params = {:mi_plan_id                       => phenotype_attempt.mi_plan_id,
              :parent_colony                    => phenotype_attempt.parent_colony,
              :phenotyping_experiments_started  => phenotype_attempt.phenotyping_experiments_started,
              :ready_for_website                => phenotype_attempt.ready_for_website,
              :phenotyping_started              => phenotype_attempt.phenotyping_started,
              :phenotyping_complete             => phenotype_attempt.phenotyping_complete,
              :colony_name                      => phenotype_attempt.colony_name,
              :is_active                        => phenotype_attempt.is_active,
              :report_to_public                 => phenotype_attempt.report_to_public,
              :consortium_name                  => phenotype_attempt.consortium_name,
              :production_centre_name           => phenotype_attempt.production_centre_name
              }
    pap = phenotype_attempt.phenotyping_productions.includes(:mi_plan).where("mi_plans.consortium_id = #{phenotype_attempt.mi_plan.consortium_id} AND mi_plans.production_centre_id = #{phenotype_attempt.mi_plan.production_centre_id}")
    if pap.count == 1
    pap = pap.first
    else
      pap = PhenotypingProduction.new
    end
    pap.update_attributes(params)
    if pap.valid?

      status_mapping = {
                        'Phenotype Attempt Registered'      => 'Phenotype Attempt Registered',
                        'Phenotyping Production Registered' => 'Phenotype Attempt Registered',
                        'Phenotyping Started'               => 'Phenotyping Started',
                        'Phenotyping Complete'              => 'Phenotyping Complete',
                        'Phenotype Production Aborted'      => 'Phenotype Attempt Aborted'
                       }
      phenotype_status_stamps = {}
      pap.phenotype_attempt.status_stamps.includes(:status).each{|stamp| phenotype_status_stamps[stamp.status.name] = stamp.created_at}
      pap.status_stamps.includes(:status).each{|stamp| stamp.update_attributes(:created_at => phenotype_status_stamps[status_mapping[stamp.status.name]]) if phenotype_status_stamps.has_key?(status_mapping[stamp.status.name])}
    else
      raise PhenotypeAttemptError, "failed to save Phenotyping Production #{pap.errors.messages}."
    end
  end


  def self.readable_name
    'phenotyping productions'
  end

  def self.phenotype_attempt_updatable_fields
    {'phenotyping_experiments_started' => nil, 'ready_for_website' => nil, 'phenotyping_started' => false, 'phenotyping_complete' => false}
  end
end

# == Schema Information
#
# Table name: phenotyping_productions
#
#  id                              :integer          not null, primary key
#  mi_plan_id                      :integer          not null
#  mouse_allele_mod_id             :integer          not null
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
#  rederivation_started            :boolean
#  rederivation_complete           :boolean
#
