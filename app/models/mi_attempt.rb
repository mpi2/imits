# encoding: utf-8

class MiAttempt < ActiveRecord::Base
  set_table_name 'emi_attempt'

  # The include does not work in postgres, which seems to ignore it, and breaks
  # on oracle
  belongs_to :emi_event, :class_name => 'EmiEvent',
          :foreign_key => :event_id # , :include => [:clone]

  belongs_to :mi_attempt_status, :foreign_key => 'status_dict_id'

  delegate :clone, :proposed_mi_date, :distribution_centre, :to => :emi_event

  delegate :clone_name, :gene_symbol, :allele_name, :to => :clone

  scope :by_clone_names, proc { |clone_names| joins({:emi_event => :clone}).where('UPPER(emi_clone.clone_name) IN (?)', clone_names.map(&:upcase)) }

  scope :by_gene_symbols, proc { |gene_symbols| joins({:emi_event => :clone}).where('UPPER(emi_clone.gene_symbol) IN (?)', gene_symbols.map(&:upcase)) }

  scope :by_colony_names, proc { |colony_names| where('UPPER(colony_name) IN (?)', colony_names.map(&:upcase))}

  def self.search(search_terms)
    (by_clone_names(search_terms).to_a + by_gene_symbols(search_terms).to_a + by_colony_names(search_terms).to_a).uniq
  end

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
      if is_emma_sticky? then return :suitable_sticky else return :suitable end
    else
      if is_emma_sticky? then return :unsuitable_sticky else return :unsuitable end
    end
  end

  class EmmaStatusError < RuntimeError; end

  def emma_status=(status)
    case status.to_sym
    when :suitable then
      self.emma = '1'
      self.is_emma_sticky = false

    when :unsuitable then
      self.emma = '0'
      self.is_emma_sticky = false

    when :suitable_sticky then
      self.emma = '1'
      self.is_emma_sticky = true

    when :unsuitable_sticky then
      self.emma = '0'
      self.is_emma_sticky = true

    else
      raise EmmaStatusError, "Invalid status '#{status.inspect}'"
    end
  end
end
