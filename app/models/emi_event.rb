class EmiEvent < ActiveRecord::Base
  set_table_name 'emi_event'

  belongs_to :emi_clone, :class_name => 'EmiClone', :foreign_key => :clone_id
end
