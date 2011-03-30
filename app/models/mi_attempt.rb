# encoding: utf-8

class MiAttempt < ApplicationModel
  set_table_name 'emi_attempt'

  # The include does not work in postgres, which seems to ignore it, and breaks
  # on oracle
  belongs_to :emi_event, :class_name => 'EmiEvent',
          :foreign_key => :event_id # , :include => [:clone]

  belongs_to :mi_attempt_status, :foreign_key => 'status_dict_id'

  delegate :clone, :proposed_mi_date, :distribution_centre, :to => :emi_event

  delegate :clone_name, :gene_symbol, :allele_name, :to => :clone

  scope :search, proc { |terms|
    terms.map(&:upcase!)
    terms = terms.dup.delete_if {|i| i.strip.empty?}
    if terms.empty?
      scoped
    else
      joins(:emi_event => :clone).where(
        'UPPER(emi_clone.clone_name) IN (?) OR ' +
        'UPPER(emi_clone.gene_symbol) IN (?) OR ' +
        'UPPER(colony_name) IN (?)',
        terms, terms, terms
      )
    end
  }

  scope :sort_by_clone_name, proc { |direction|
    joins(:emi_event => :clone).order("emi_clone.clone_name #{direction}")
  }

  scope :sort_by_gene_symbol, proc { |direction|
    joins(:emi_event => :clone).order("emi_clone.gene_symbol #{direction}")
  }

  scope :sort_by_allele_name, proc { |direction|
    joins(:emi_event => :clone).order("emi_clone.allele_name #{direction}")
  }

  scope :sort_by_mi_attempt_status, proc { |direction|
    joins(:mi_attempt_status).order("emi_status_dict.name #{direction}")
  }

  scope :sort_by_distribution_centre_name, proc { |direction|
    joins(:emi_event => :distribution_centre).order("per_centre.name #{direction}")
  }

  before_validation :integerify_fields

  before_save :audit_on_save

  before_save :sum_up_total_chimeras

  def integerify_fields
    self.num_blasts = num_blasts.to_i
    self.num_transferred = num_transferred.to_i
    self.total_f1_mice = total_f1_mice.to_i
  end

  def sum_up_total_chimeras
    self.total_chimeras = number_male_chimeras.to_i + number_female_chimeras.to_i
  end

  def set_distribution_centre_by_name(name, event_edited_by)
    return emi_event.update_attributes(:distribution_centre => Centre.find_by_name!(name),
                                       :edited_by => event_edited_by)
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
