# encoding: utf-8

module PlanIntention::StatusManagement
  extend ActiveSupport::Concern

  ss = ApplicationModel::StatusManager.new(PlanIntention)

  ss.add('Register Interest') do |pi|
    true
  end

  ss.add('Assigned') do |pi|
    pi.assigned?
  end

  ss.add('Withdrawn') do |pi| 
    pi.withdrawn? 
  end

  included do
    @@status_manager = ss
    cattr_reader :status_manager

    attr_accessor :force_assignment
  end

  module ClassMethods
    def status_stamps_order_sql
      status_manager.status_stamps_order_sql
    end
  end

  def change_status
    self.status = PlanIntention::Status.find_by_name!(status_manager.get_status_for(self))
    return true
  end

  def manage_status_stamps
    status_manager.manage_status_stamps_for(self)
  end

end
