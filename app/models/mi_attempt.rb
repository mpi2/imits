class MiAttempt < ActiveRecord::Base
  set_table_name 'emi_attempt'

  # The include does not work in postgres, which seems to ignore it, and breaks
  # on oracle
  belongs_to :emi_event, :class_name => 'EmiEvent',
          :foreign_key => :event_id # , :include => [:emi_clone]

  delegate :emi_clone, :proposed_mi_date, :distribution_centre, :to => :emi_event

  delegate :clone_name, :gene_symbol, :allele_name, :to => :emi_clone

  scope :by_clone_names, proc { |clone_names| joins({:emi_event => :emi_clone}).where(:emi_clone => {:clone_name => clone_names}) }

  scope :by_gene_symbols, proc { |gene_symbols| joins({:emi_event => :emi_clone}).where(:emi_clone => {:gene_symbol => gene_symbols}) }

  def set_distribution_centre_by_name(name)
    return emi_event.update_attributes(:distribution_centre => Centre.find_by_name!(name))
  end

  def distribution_centre_name
    return emi_event.distribution_centre.name
  end

  def emma?
    return (self.emma == '1')
  end

  def emma_status
    if emma?
      if is_emma_sticky? then return :force_on else return :on end
    else
      if is_emma_sticky? then return :force_off else return :off end
    end
  end

  class EmmaStatusError < RuntimeError; end

  def emma_status=(status)
    case status.to_sym
    when :on then
      self.emma = '1'
      self.is_emma_sticky = false

    when :off then
      self.emma = '0'
      self.is_emma_sticky = false

    when :force_on then
      self.emma = '1'
      self.is_emma_sticky = true

    when :force_off then
      self.emma = '0'
      self.is_emma_sticky = true

    else
      raise EmmaStatusError, "Invalid status '#{status.inspect}'"
    end
  end
end
