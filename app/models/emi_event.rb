class EmiEvent < ActiveRecord::Base
  set_table_name 'emi_event'

  belongs_to :clone
  belongs_to :distribution_centre, :class_name => 'Centre', :foreign_key => :distribution_centre_id
end
