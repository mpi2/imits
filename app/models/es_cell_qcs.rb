class EsCellQc < ActiveRecord::Base
  acts_as_reportable
  acts_as_audited

  extend AccessAssociationByAttribute
  include EsCellQc::StatusManagement
  include ApplicationModel::HasStatuses
  include ApplicationModel::BelongsToMiPlan

  belongs_to :mi_plan
  belongs_to :sub_project
  belongs_to :status
  belongs_to :comment
  belongs_to :es_cells_received_from, :class_name => 'TargRep::CentrePipeline'
  has_many :status_stamps, :order => "#{EsCellQc::StatusStamp.table_name}.created_at ASC",
          :dependent => :destroy

  access_association_by_attribute :es_cells_received_from, :name
  accepts_nested_attributes_for :status_stamps

  validates :mi_plan, :presence => true
  validates :status, :presence => true

  validate do |plan|
    update_es_cell_received

    if !plan.number_of_es_cells_received.blank?
      if es_cells_received_on.blank?
        plan.errors.add(:es_cells_received_on, 'cannot be blank if \'number_of_es_cells_received\' has a value')
      end

      if es_cells_received_from_id.blank?
        plan.errors.add(:es_cells_received_from, 'cannot be blank if \'number_of_es_cells_received\' has a value')
      end
    end
  end

  def update_es_cell_received
    if number_of_es_cells_received.blank? && number_of_es_cells_starting_qc.to_i > 0
      return if centre_pipeline.blank?
      return if es_cell_qc_in_progress_date.blank?
      self.number_of_es_cells_received = number_of_es_cells_starting_qc
      self.es_cells_received_on = es_cell_qc_in_progress_date
      self.es_cells_received_from_name = centre_pipeline
    end
  end
  private :update_es_cell_received

  def centre_pipeline
    @centre_pipeline ||= TargRep::CentrePipeline.all.find{|p| p.centres.include?(default_pipeline.try(:name)) }.try(:name)
  end

  def default_pipeline
    @default_pipeline ||= self.plan.mi_attempts.first.try(:es_cell).try(:pipeline)
  end

  def es_cell_qc_in_progress_date
    status_stamp = self.status_stamps.where(status_id: EsCellQc::Status['ES Cell QC In Progress'].id).first
    status_stamp.created_at.to_date if status_stamp
  end
end
