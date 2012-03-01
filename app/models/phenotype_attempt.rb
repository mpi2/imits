# encoding: utf-8

class PhenotypeAttempt < ApplicationModel
  acts_as_audited

  include PhenotypeAttempt::StatusChanger

  belongs_to :mi_attempt
  belongs_to :mi_plan
  belongs_to :status
  has_many :status_stamps, :order => "#{PhenotypeAttempt::StatusStamp.table_name}.created_at ASC"

  validate :mi_attempt do |me|
    if me.mi_attempt and me.mi_attempt.mi_attempt_status != MiAttemptStatus.genotype_confirmed
      me.errors.add(:mi_attempt, "status must be genotype confirmed (is currently '#{me.mi_attempt.mi_attempt_status.description}')")
    end
  end

  validate :mi_plan do |me|
    if me.mi_attempt and me.mi_plan and me.mi_attempt.gene != me.mi_plan.gene
      me.errors.add(:mi_plan, 'must have same gene as mi_attempt')
    end
  end

  # BEGIN Callbacks

  before_validation :change_status
  before_validation :set_mi_plan
  before_save :record_if_status_was_changed
  before_save :generate_colony_name_if_blank
  before_save :ensure_plan_is_valid
  after_save :create_status_stamp_if_status_was_changed

  def set_mi_plan
    self.mi_plan ||= mi_attempt.try(:mi_plan)
  end

  def record_if_status_was_changed
    if self.changed.include? 'status_id'
      @new_status = self.status
    else
      @new_status = nil
    end
  end

  def generate_colony_name_if_blank
    return unless self.colony_name.blank?

    i = 0
    begin
      i += 1
      self.colony_name = "#{self.mi_attempt.colony_name}-#{i}"
    end until self.class.find_by_colony_name(self.colony_name).blank?
  end

  def ensure_plan_is_valid
    if ! mi_plan.assigned?
      mi_plan.status = MiPlan::Status['Assigned']
      mi_plan.save!
    end
    if self.is_active?
      self.mi_plan.is_active = true
      self.mi_plan.save!
    end
  end

  def create_status_stamp_if_status_was_changed
    if @new_status
      status_stamps.create!(:status => @new_status)
    end
  end

  # END Callbacks

  delegate :gene, :to => :mi_attempt

  def reportable_statuses_with_latest_dates
    retval = {}
    status_stamps.each do |status_stamp|
      status_stamp_date = status_stamp.created_at.utc.to_date
      if !retval[status_stamp.status.name] or
                status_stamp_date > retval[status_stamp.status.name]
        retval[status_stamp.status.name] = status_stamp_date
      end
    end
    return retval
  end

end

# == Schema Information
#
# Table name: phenotype_attempts
#
#  id                               :integer         not null, primary key
#  mi_attempt_id                    :integer         not null
#  status_id                        :integer         not null
#  is_active                        :boolean         default(TRUE), not null
#  rederivation_started             :boolean         default(FALSE), not null
#  rederivation_complete            :boolean         default(FALSE), not null
#  number_of_cre_matings_started    :integer         default(0), not null
#  number_of_cre_matings_successful :integer         default(0), not null
#  phenotyping_started              :boolean         default(FALSE), not null
#  phenotyping_complete             :boolean         default(FALSE), not null
#  created_at                       :datetime
#  updated_at                       :datetime
#  mi_plan_id                       :integer         not null
#  colony_name                      :string(125)     not null
#  mouse_allele_type                :string(1)
#
# Indexes
#
#  index_phenotype_attempts_on_colony_name  (colony_name) UNIQUE
#

