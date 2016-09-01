# encoding: utf-8

module EsCellQc::StatusManagement
  extend ActiveSupport::Concern

  ss = ApplicationModel::StatusManager.new(EsCellQc)

  ss.add('ES Cell Received') { |es_qc| true }

  ss.add('ES Cell QC In Progress') do |es_qc| 
    !es_qc.number_of_es_cells_starting_qc.nil? && es_qc.number_of_es_cells_starting_qc > 0 
  end

  ss.add('ES Cell QC Complete', 'ES Cell QC In Progress') do |es_qc|
    !es_qc.number_of_es_cells_passing_qc.nil? && es_qc.number_of_es_cells_passing_qc > 0
  end

  ss.add('ES Cell QC Failed', 'ES Cell QC In Progress') do |es_qc|
    !es_qc.number_of_es_cells_passing_qc.nil? && es_qc.number_of_es_cells_passing_qc == 0
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
    self.status = EsCellQc::Status.find_by_name!(status_manager.get_status_for(self))
  end

  def manage_status_stamps
    status_manager.manage_status_stamps_for(self)
  end

end
