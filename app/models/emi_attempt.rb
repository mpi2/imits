class EmiAttempt < ActiveRecord::Base
  set_table_name 'emi_attempt'

  belongs_to :emi_event, :class_name => 'EmiEvent',
          :foreign_key => :event_id, :include => [:emi_clone]

  def emi_clone; emi_event.emi_clone; end

  scope :by_clone_name, proc { |clone_name| joins({:emi_event => :emi_clone}).where(:emi_clone => {:clone_name => clone_name}) }
end
