# encoding: utf-8

module MiAttempt::StatusManagement
  extend ActiveSupport::Concern

  ss = ApplicationModel::StatusManager.new(MiAttempt)

  ss.add('Micro-injection in progress') { |mi| true }

  ss.add('Chimeras obtained') do |mi|
    mi.total_male_chimeras.to_i > 0
  end

  ss.add('Genotype confirmed', 'Chimeras obtained') do |mi|
    if mi.production_centre_name == 'WTSI'
      mi.is_released_from_genotyping?
    else
      mi.number_of_het_offspring.to_i != 0 or mi.number_of_chimeras_with_glt_from_genotyping.to_i != 0
    end
  end

  ss.add('Micro-injection aborted') do |mi|
    ! mi.is_active?
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
    self.status = MiAttempt::Status.find_by_name!(status_manager.get_status_for(self))
  end

  def manage_status_stamps
    status_manager.manage_status_stamps_for(self)
  end

end
