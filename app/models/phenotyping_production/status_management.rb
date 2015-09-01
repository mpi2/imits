# encoding: utf-8

module PhenotypingProduction::StatusManagement
  extend ActiveSupport::Concern

  ss = ApplicationModel::StatusManager.new(PhenotypingProduction)

  ss.add('Phenotyping Production Registered') do |pt|
    !pt.phenotyping_experiments_started.blank?
  end

  ss.add('Phenotype Attempt Registered') { |pt| true }

  ss.add('Rederivation Started') do |pt|
    pt.rederivation_started == true && pt.parent_colony.genotype_confirmed == true
  end

  ss.add('Rederivation Complete', 'Rederivation Started') do |pt|
    pt.rederivation_complete == true
  end

  ss.add('Phenotyping Started') do |pt|
    pt.phenotyping_started? && pt.parent_colony.genotype_confirmed == true
  end

  ss.add('Phenotyping Complete', 'Phenotyping Started') do |pt|
    pt.phenotyping_complete?
  end

  ss.add('Phenotype Production Aborted') do |pt|
    ! pt.is_active?
  end

  included do
    @@status_manager = ss
    cattr_reader :status_manager
  end

  module ClassMethods
    def status_stamps_order_sql
      status_manager.status_stamps_order_sql
    end
  end

  def change_status
    self.status = PhenotypingProduction::Status.find_by_name!(status_manager.get_status_for(self))
  end

  def manage_status_stamps
    status_manager.manage_status_stamps_for(self)
  end

end
