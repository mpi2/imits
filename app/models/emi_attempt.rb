class EmiAttempt < ActiveRecord::Base
  set_table_name 'emi_attempt'

  # The include does not work in postgres, which seems to ignore it, and breaks
  # on oracle
  belongs_to :emi_event, :class_name => 'EmiEvent',
          :foreign_key => :event_id # , :include => [:emi_clone]

  delegate :emi_clone, :proposed_mi_date, :distribution_centre, :to => :emi_event

  delegate :clone_name, :gene_symbol, :allele_name, :to => :emi_clone

  scope :by_clone_names, proc { |clone_names| joins({:emi_event => :emi_clone}).where(:emi_clone => {:clone_name => clone_names}) }

  def formatted_proposed_mi_date; proposed_mi_date.strftime('%d %B %Y'); end

  def formatted_actual_mi_date; actual_mi_date.strftime('%d %B %Y'); end

  def set_distribution_centre_by_name(name)
    return emi_event.update_attributes(:distribution_centre => Centre.find_by_name!(name))
  end

  def distribution_centre_name
    return emi_event.distribution_centre.name
  end
end
