# encoding: utf-8

class Old::EmiEvent < Old::ModelBase
  set_table_name 'emi_event'

  belongs_to :clone
  belongs_to :distribution_centre, :class_name => 'Old::Centre', :foreign_key => :distribution_centre_id
end
