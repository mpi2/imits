# encoding: utf-8

class PhenotypingProduction < ApplicationModel
  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute
  include PhenotypingProduction::StatusManagement
  include ApplicationModel::HasStatuses
  include ApplicationModel::BelongsToMiPlan

  belongs_to :mouse_allele_mod
  belongs_to :mi_plan
  belongs_to :phenotype_attempt
  belongs_to :status
  has_many   :status_stamps, :order => "#{PhenotypingProduction::StatusStamp.table_name}.created_at ASC", dependent: :destroy

  accepts_nested_attributes_for :status_stamps

  protected :status=

  before_validation :allow_override_of_plan
  before_validation :set_mouse_allele_mod_if_blank
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
      mouse_allele_mod_id = #{pp.mouse_allele_mod_id}").map{|a| a.id}

    other_ids -= [self.id]
    if(other_ids.count != 0)
      pp.errors[:already] << 'has production for this consortium & production centre'
    end
  end

  validates :mouse_allele_mod, :presence => true
  validates :phenotype_attempt, :presence => true
  validates :colony_name, :presence => true, :uniqueness => {:case_sensitive => false}, :allow_nil => false


#  validates :mouse_allele_modification, :presence => true
#  validates :colony_name, :uniqueness => {:case_sensitive => false}

  # validate mi_plan
#  validate do |me|
#    if validate_plan

#      if !me.mi_plan.phenotype_only and me.mi_attempt and me.mi_attempt.mi_plan != me.mi_plan
#        me.errors.add(:mi_plan, 'must be either the same as the mi_attempt OR phenotype_only')
#      end

#    end
#  end


#  validate do |me|
#    if me.mi_attempt and me.mi_attempt.status != MiAttempt::Status.genotype_confirmed
#      me.errors.add(:mi_attempt, "Status must be 'Genotype confirmed' (is currently '#{me.mi_attempt.status.try(:name)}')")
#    end
#  end

  # BEGIN Callbacks
#  before_validation do |pa|
#    if ! pa.colony_name.nil?
#      pa.colony_name = pa.colony_name.to_s.strip || pa.colony_name
#      pa.colony_name = pa.colony_name.to_s.gsub(/\s+/, ' ')
#    end
#  end

#  after_initialize :set_mi_plan # need to set mi_plan if blank before authorize_user_production_centre is fired in controller.
#  before_validation :set_mi_plan # this is here if mi_plan is edited after initialization
#  before_save :deal_with_unassigned_or_inactive_plans # this method is in belongs_to_mi_plan
#  before_save :generate_colony_name_if_blank
#  after_save :set_phenotyping_experiments_started_if_blank

## METHODS
  def gene
    if mi_plan.try(:gene)
      return mi_plan.gene
    elsif phenotype_attempt.try(:gene)
      return phenotype_attempt.gene
    else
      return nil
    end
  end

## BEFORE VALIDATION FUNCTIONS
  def allow_override_of_plan
    return if self.consortium_name.nil? or self.production_centre_name.nil?
    set_plan = MiPlan.find_or_create_plan(self, {:gene => self.gene, :consortium_name => self.consortium_name, :production_centre_name => self.production_centre_name, :phenotype_only => true}) do |pa|
      plan = pa.phenotype_attempt.mi_plan
      if !plan.blank? and plan.consortium.try(:name) == self.consortium_name and plan.production_centre.try(:name) == self.production_centre_name
        plan = [plan]
      else
        plan = MiPlan.includes(:consortium, :production_centre, :gene).where("genes.marker_symbol = '#{self.gene.marker_symbol}' AND consortia.name = '#{self.consortium_name}' AND centres.name = '#{self.production_centre_name}' AND phenotype_only = true")
      end
    end
    self.mi_plan = set_plan
  end

  def set_mouse_allele_mod_if_blank
    if self.mouse_allele_mod_id.blank?
      return if self.phenotype_attempt_id.blank? or self.phenotype_attempt.mouse_allele_mod.blank?
      self.mouse_allele_mod_id = phenotype_attempt.mouse_allele_mod.id
    end
  end

  def status_name; status.name; end

  def mouse_allele_mod_status_name; mouse_allele_mod.status.name; end

## CLASS METHODS

  def self.create_or_update_from_phenotype_attempt(phenotype_attempt)
    raise PhenotypeAttemptError, "Must pass phenotype_attempt as a parameter." if phenotype_attempt.blank?
    params = {:mi_plan_id                       => phenotype_attempt.mi_plan_id,
              :phenotype_attempt_id             => phenotype_attempt.id,
              :mouse_allele_mod_id              => phenotype_attempt.mouse_allele_mod.id,
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
#
