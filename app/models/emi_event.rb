# encoding: utf-8

class EmiEvent < ApplicationModel
  set_table_name 'emi_event'

  belongs_to :clone
  belongs_to :distribution_centre, :class_name => 'Centre', :foreign_key => :distribution_centre_id

  before_save :audit_on_save
end
