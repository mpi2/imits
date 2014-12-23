require 'tempfile'

class Colony < ActiveRecord::Base

  acts_as_audited
  acts_as_reportable

  belongs_to :mi_attempt
  belongs_to :mouse_allele_mod

  has_many :allele_modifications, :class_name => 'MouseAlleleMod', :foreign_key => 'parent_colony_id'
  has_many :phenotyping_productions, :class_name => 'PhenotypingProduction', :foreign_key => 'parent_colony_id'

  has_one :colony_qc, :inverse_of => :colony, :dependent => :destroy
  has_one :trace_call, :inverse_of =>:colony, :dependent => :destroy, :class_name => "TraceCall"

  accepts_nested_attributes_for :colony_qc
  accepts_nested_attributes_for :trace_call

  validates :name, :presence => true
  validates_uniqueness_of :name, conditions: -> { where("mi_attempt_id IS NOT NULL") }
  validates_uniqueness_of :name, conditions: -> { where("mouse_allele_mod_id  IS NOT NULL") }

  validate :set_allele_symbol_superscript

  validate do |colony|
    if mouse_allele_mod_id.blank? and mi_attempt_id.blank?
      colony.errors.add :base, 'A Colony can only be produced via a Micro-Injection or an Allele Modification.'
    end
  end

  validate do |colony|
    if !mouse_allele_mod_id.blank? and !mi_attempt_id.blank?
      colony.errors.add :base, 'A Colony can only be produced either though a Micro-Injection or an Allele Modification, not both.'
    end
  end

  validate do |colony|
    if !mi_attempt_id.blank? and !mi_attempt.es_cell_id.blank?
      if Colony.where("mi_attempt_id = #{colony.mi_attempt_id} #{if !colony.id.blank?; "and id != #{colony.id}"; end}").count == 1
        colony.errors.add :base, 'Multiple Colonies are not allowed for Mi Attempts Micro-Injected with an ES Cell clone'
      end
    end
  end

  validate do |colony|
    if colony.unwanted_allele and colony.genotype_confirmed
      colony.errors.add :base, ": Colony '#{name}' cannot be marked as both 'Genotype Confirmed' and 'Unwanted Allele'"
    end
  end

  before_save :set_genotype_confirmed



  def set_genotype_confirmed
    if !mi_attempt.blank? && !mi_attempt.status.blank?
      if !mi_attempt.es_cell.blank? && mi_attempt.status.code == 'gtc'
        self.genotype_confirmed = true
      end
    elsif !mouse_allele_mod.blank? && !mouse_allele_mod.status.blank? && mouse_allele_mod.status.code == 'cec'
      self.genotype_confirmed = true
    end
  end
  protected :set_genotype_confirmed


  def get_template
    return allele_symbol_superscript_template unless allele_symbol_superscript_template.nil?

    if mi_attempt_id

      if mi_attempt.es_cell_id
        return mi_attempt.es_cell.allele_symbol_superscript_template
      elsif mi_attempt.mutagenesis_factor
        return "em1(IMPC)#{production_centre.superscript}"
      else
        return nil
      end

    elsif mouse_allele_mod_id

      return mouse_allele_mod.try(:parent_colony).try(:get_template)

    else
      return nil
    end
  end
 # protected :get_template

  def get_type
    return allele_type unless allele_type.nil?

    if mi_attempt_id

      if mi_attempt.es_cell_id
        return mi_attempt.es_cell.allele_type
      elsif mi_attempt.mutagenesis_factor
        return 'NHEJ'
      else
        return nil
      end

    elsif mouse_allele_mod_id

      return mouse_allele_mod.try(:parent_colony).try(:get_type)

    else
      return nil
    end
  end
  #protected :get_type


  def gene
    return mi_attempt.mi_plan.gene if !mi_attempt_id.blank?
    return mouse_allele_mod.mi_plan.gene if !mouse_allele_mod_id.blank?
    return nil
  end

  def mi_plan
    return mi_attempt.mi_plan if !mi_attempt_id.blank?
    return mouse_allele_mod.mi_plan if !mouse_allele_mod_id.blank?
    return nil
  end


  def set_allele_symbol_superscript
    return if allele_symbol_superscript_template_changed?

    if mgi_allele_symbol_superscript.blank?
      allele_symbol_superscript_template = nil
      return
    end

    allele_symbol_superscript_template, allele_type, errors = TargRep::Allele.extract_symbol_superscript_template(mgi_allele_symbol_superscript)

    if errors.count > 0
      self.errors.add errors.first[0], errors.first[1]
    end
  end


  def allele_symbol_superscript
    template = get_template
    type = get_type

    return nil if template.nil?

    if template =~ /#{TargRep::Allele::TEMPLATE_CHARACTER}/
      if type.nil?
        return nil
      else
        return template.sub(TargRep::Allele::TEMPLATE_CHARACTER, type)
      end
    else
      return template
    end
  end

  def allele_symbol
    if allele_symbol_superscript
      return "#{self.gene.marker_symbol}<sup>#{allele_symbol_superscript}</sup>"
    else
      return nil
    end
  end


  def self.readable_name
    return 'colony'
  end


end

# == Schema Information
#
# Table name: colonies
#
#  id                                 :integer          not null, primary key
#  name                               :string(255)      not null
#  mi_attempt_id                      :integer
#  genotype_confirmed                 :boolean          default(FALSE)
#  report_to_public                   :boolean          default(FALSE)
#  unwanted_allele                    :boolean          default(FALSE)
#  unwanted_allele_description        :text
#  mouse_allele_mod_id                :integer
#  mgi_allele_symbol_superscript      :string(255)
#  mgi_allele_id                      :string(255)
#  allele_symbol_superscript_template :string(255)
#  allele_type                        :string(255)
#
# Indexes
#
#  mouse_allele_mod_colony_name_uniqueness_index  (name,mi_attempt_id,mouse_allele_mod_id) UNIQUE
#
