class EmiAttempt < ActiveRecord::Base
  set_table_name 'emi_attempt'

  # The include does not work in postgres, which seems to ignore it, and breaks
  # on oracle
  belongs_to :emi_event, :class_name => 'EmiEvent',
          :foreign_key => :event_id # , :include => [:emi_clone]

  def emi_clone; emi_event.emi_clone; end

  def clone_name; emi_clone.clone_name; end

  scope :by_clone_name, proc { |clone_name| joins({:emi_event => :emi_clone}).where(:emi_clone => {:clone_name => clone_name}) }
end
