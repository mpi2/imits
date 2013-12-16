# encoding: utf-8

module MouseAlleleMod::StatusManagement
  extend ActiveSupport::Concern

  ss = ApplicationModel::StatusManager.new(MouseAlleleMod)

  ss.add('Mouse Allele Modification Registered') do |pt|
    pt.no_modification_required == false
  end

  ss.add('Phenotype Attempt Registered') { |pt| true }

  ss.add('Rederivation Started') do |pt|
    pt.rederivation_started?
  end

  ss.add('Rederivation Complete', 'Rederivation Started') do |pt|
    pt.rederivation_complete?
  end

  ss.add('Cre Excision Started', 'Mouse Allele Modification Registered') do |pt|
    ! pt.deleter_strain.blank?
  end

  ss.add('Cre Excision Complete', 'Cre Excision Started') do |pt|
    ((!pt.deleter_strain.blank? && pt.number_of_cre_matings_successful.to_i > 0) || pt.tat_cre) && ['b', '.1', 'e.1'].include?(pt.mouse_allele_type) && ! pt.colony_background_strain.nil?
  end

  ss.add('Mouse Allele Modification Aborted') do |pt|
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
    self.status = MouseAlleleMod::Status.find_by_name!(status_manager.get_status_for(self))
  end

  def manage_status_stamps
    status_manager.manage_status_stamps_for(self)
  end

end
