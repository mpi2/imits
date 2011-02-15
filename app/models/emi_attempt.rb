class EmiAttempt < ActiveRecord::Base
  set_table_name 'emi_attempt'

  # The include does not work in postgres, which seems to ignore it, and breaks
  # on oracle
  belongs_to :emi_event, :class_name => 'EmiEvent',
          :foreign_key => :event_id # , :include => [:emi_clone]

  delegate :emi_clone, :proposed_mi_date, :to => :emi_event

  delegate :clone_name, :gene_symbol, :allele_name, :to => :emi_clone

  scope :by_clone_names, proc { |*clone_names| joins({:emi_event => :emi_clone}).where(:emi_clone => {:clone_name => clone_names}) }
end
