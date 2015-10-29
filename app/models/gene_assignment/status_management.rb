# encoding: utf-8

module GeneAssignment::StatusManagement
  extend ActiveSupport::Concern

  ss = ApplicationModel::StatusManager.new(GeneAssignment)

  ss.add('Register Interest') { |ga| true }

  ss.add('Conflict', 'Register Interest') do |ga| 
    ga.conflict == true
  end

  ss.add('Assigned', 'Register Interest') do |ga|
    ga.assign == true
  end

  ss.add('Withdrawn', 'Register Interest') do |ga|
    ga.withdraw == true
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
    self.status = GeneAssignment::Status.find_by_name!(status_manager.get_status_for(self))
  end

  def manage_status_stamps
    status_manager.manage_status_stamps_for(self)
  end

end
