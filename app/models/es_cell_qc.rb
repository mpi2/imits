# encoding: utf-8

class EsCellQc < ApplicationModel
  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute
  include EsCellQc::StatusManagement
  include ApplicationModel::HasStatuses
  include ApplicationModel::BelongsToMiPlan

  belongs_to :plan
  belongs_to :sub_project
  belongs_to :priority
  belongs_to :status
  belongs_to :comment, :class_name => 'EsCellQc::Comment'
  belongs_to :es_cells_received_from, :class_name => 'TargRep::CentrePipeline'

  has_many   :status_stamps, :order => "#{EsCellQc::StatusStamp.table_name}.created_at ASC", dependent: :destroy

  access_association_by_attribute :status, :name
  access_association_by_attribute :es_cells_received_from, :name  
  access_association_by_attribute :comment, :name
  access_association_by_attribute :priority, :name

  accepts_nested_attributes_for :status_stamps

  protected :status=

  before_validation :change_status
  before_validation :set_default_number_of_es_cells_starting_qc
  
  before_save :manage_plan_and_intentions

 

  def manage_plan_and_intentions
    # if validation has pass then all nessary attributes have been set

    if self.plan.blank?
      new_plan = Plan.joins(:gene, :production_centre, :consortium).where("genes.marker_symbol = #{self.marker_symbol} AND consortia.name = #{self.consortium_name} AND centres.name = #{self.production_centre_name}")
      if plan.blank?
        new_plan = Plan.new(:marker_symbol => self.marker_symbol, :consortium_name => self.consortium_name, :production_centre_name => self.production_centre_name)
        raise 'Could not save Plan' unless new_plan.save
      end
      self.plan = new_plan
    end

    return if self.number_of_es_cells_starting_qc.blank? && self.number_of_es_cells_passing_qc.blank?

    es_qc_intention = self.plan.qc_es_cell_intention
    if es_qc_intention.blank?
      es_qc_intention = Plan::Intention.new(:plan => self.plan, :intention_name => 'ES Cell QC', :assign => true)
    else
      #ensure es cell qc intention is assigned and not withdrawn if production is active
      if ['ES Cell QC In Progress', 'ES Cell QC Complete'].include?(self.status_name)
        es_qc_intention.assign = true
        es_qc_intention.withdrawn = false
      end
    end

    raise "Could not save new ES Cell QC Intention: #{es_qc_intention.errors.messages}" unless es_qc_intention.save
  end  # this method is in belongs_to_mi_plan
  private :manage_plan_and_intentions

  after_save :manage_status_stamps


## BEFORE VALIDATION METHODS

  def set_default_number_of_es_cells_starting_qc
    if number_of_es_cells_starting_qc.nil? && !number_of_es_cells_passing_qc.nil?
      self.number_of_es_cells_starting_qc = number_of_es_cells_passing_qc
    end
  end

  def update_es_cell_received
    if number_of_es_cells_received.blank? && number_of_es_cells_starting_qc.to_i > 0
      return if centre_pipeline.blank?
      return if es_cell_qc_in_progress_date.blank?
      self.number_of_es_cells_received = number_of_es_cells_starting_qc
      self.es_cells_received_on = es_cell_qc_in_progress_date if self.es_cells_received_on.blank?
      self.es_cells_received_from_name = centre_pipeline if self.es_cells_received_from_name.blank?
    end
  end

  def centre_pipeline
    @centre_pipeline ||= TargRep::CentrePipeline.all.find{|p| p.centres.include?(default_pipeline.try(:name)) }.try(:name)
  end
  private :centre_pipeline

  def default_pipeline
    @default_pipeline ||= self.plan.es_cell_mi_attempts.first.try(:es_cell).try(:pipeline)
  end
  private :default_pipeline

  def es_cell_qc_in_progress_date
    status_stamp = self.status_stamps.where(status_id: EsCellQc::Status['ES Cell QC In Progress'].id).first
    status_stamp.created_at.to_date if status_stamp
  end
  private :es_cell_qc_in_progress_date

## VALIDATION
  validates :status, :presence => true

  validate do |es_cell_qc|
    if es_cell_qc.plan.nil?
      es_cell_qc.errors.add(:consortium_name, 'must be set')
      es_cell_qc.errors.add(:centre_name, 'must be set')
      return
    end
  end

  validate do |es_cell_qc|
    if !es_cell_qc.number_of_es_cells_received.blank?
      if es_cell_qc.es_cells_received_on.blank?
        es_cell_qc.errors.add(:es_cells_received_on, 'cannot be blank if \'number_of_es_cells_received\' has a value')
      end

      if es_cell_qc.es_cells_received_from_id.blank?
        es_cell_qc.errors.add(:es_cells_received_from, 'cannot be blank if \'number_of_es_cells_received\' has a value')
      end
    end
  end

  validate do |es_cell_qc|
    if ! es_cell_qc.number_of_es_cells_starting_qc.blank? && ! es_cell_qc.number_of_es_cells_passing_qc.blank?
      if es_cell_qc.number_of_es_cells_starting_qc < es_cell_qc.number_of_es_cells_passing_qc
        es_cell_qc.errors.add :number_of_es_cells_passing_qc, "passing qc exceeds starting qc"
      end
    end
  end
## BEFORE SAVE METHODS


## METHODS
  def gene
    plan.try(:gene)
  end


## BEFORE VALIDATION FUNCTIONS

## INSTANCE METHODS

  def es_cell_qc_in_progress_date
    status_stamp = self.status_stamps.where(status_id: MiPlan::Status['Assigned - ES Cell QC In Progress'].id).first
    status_stamp.created_at.to_date if status_stamp
  end

  def es_cell_qc_completion_date
    status_stamp = self.status_stamps.where(status_id: MiPlan::Status['ES Cell QC Complete'].id).first
    status_stamp.created_at.to_date if status_stamp
  end

  def es_cell_qc_fail_date
    status_stamp = self.status_stamps.where(status_id: MiPlan::Status['ES Cell QC Failed'].id).first
    status_stamp.created_at.to_date if status_stamp
  end


## CLASS METHODS
  def self.readable_name
    'es cell qc'
  end
end

# == Schema Information
#
# Table name: es_cell_qcs
#
#  id                             :integer          not null, primary key
#  plan_id                        :integer          not null
#  sub_project_id                 :integer
#  status_id                      :integer          not null
#  number_of_es_cells_received    :integer
#  es_cells_received_on           :date
#  es_cells_received_from_id      :integer
#  number_of_es_cells_starting_qc :integer
#  number_of_es_cells_passing_qc  :integer
#  comment_id                     :integer
#
