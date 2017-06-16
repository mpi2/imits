# encoding: utf-8

module PhenotypingProduction::LateAdultStatusManagement
  extend ActiveSupport::Concern

  ss = ApplicationModel::StatusManager.new(PhenotypingProduction, :LateAdultStatus, :late_adult_status_stamps)

  ss.add('Not Registered For Late Adult Phenotyping') { |pt| true }

  ss.add('Registered for Late Adult Phenotyping Production') do |pt|
    !pt.late_adult_phenotyping_experiments_started.blank?
  end

  ss.add('Late Adult Phenotyping Started') do |pt|
    pt.late_adult_phenotyping_started? && pt.parent_colony.genotype_confirmed == true
  end

  ss.add('Late Adult Phenotyping Complete', 'Late Adult Phenotyping Started') do |pt|
    pt.late_adult_phenotyping_complete?
  end

  ss.add('Late Adult Phenotype Production Aborted') do |pt|
    ! pt.late_adult_is_active?
  end

  included do
    @@late_adult_status_manager = ss
    cattr_reader :late_adult_status_manager
  end

  def late_adult_change_status
    self.late_adult_status = PhenotypingProduction::LateAdultStatus.find_by_name!(late_adult_status_manager.get_status_for(self))
  end

  def late_adult_manage_status_stamps
    status_manager.manage_status_stamps_for(self)
  end

end
