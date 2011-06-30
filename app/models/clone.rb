# encoding: utf-8

class Clone < ActiveRecord::Base
  acts_as_reportable

  TEMPLATE_CHARACTER = '@'

  belongs_to :pipeline
  has_many :mi_attempts

  validates :clone_name, :presence => true, :uniqueness => true
  validates :marker_symbol, :presence => true
  validates :pipeline, :presence => true

  attr_protected :allele_name_superscript_template

  def allele_name_superscript
    if allele_type
      return allele_name_superscript_template.sub(TEMPLATE_CHARACTER, allele_type)
    else
      return allele_name_superscript_template
    end
  end

  class AlleleNameSuperscriptFormatUnrecognizedError < RuntimeError; end

  def allele_name_superscript=(text)
    if text.nil?
      self.allele_name_superscript_template = nil
      self.allele_type = nil
      return
    end

    md = /\A(tm\d)([a-e])?(\(\w+\)\w+)\Z/.match(text)

    if md
      if md[2].blank?
        self.allele_name_superscript_template = md[1] + md[3]
        self.allele_type = nil
      else
        self.allele_name_superscript_template = md[1] + TEMPLATE_CHARACTER + md[3]
        self.allele_type = md[2]
      end
    else
      md = /\AGt\(\w+\)\w+\Z/.match(text)
      if md
        self.allele_name_superscript_template = text
        self.allele_type = nil
      else
        raise AlleleNameSuperscriptFormatUnrecognizedError, "Bad allele name superscript #{text}"
      end
    end

  end

  def allele_name
    return "#{marker_symbol}<sup>#{allele_name_superscript}</sup>"
  end

  # BEGIN Mart Operations

  IDCC_TARG_REP_DATASET = Biomart::Dataset.new(
    'http://www.knockoutmouse.org/biomart',
    { :name => 'idcc_targ_rep' }
  )

  DCC_DATASET = Biomart::Dataset.new(
    'http://www.knockoutmouse.org/biomart',
    { :name => 'dcc' }
  )

  def self.get_clones_from_marts_by_clone_names(clone_names)
    raise ArgumentError, 'Need array of clones please' unless clone_names.kind_of?(Array)
    return DCC_DATASET.search(
      :filters => {},
      :attributes => ['marker_symbol'],
      :process_results => true,
      :timeout => 600,
      :federate => [
        {
          :dataset => IDCC_TARG_REP_DATASET,
          :filters => { 'escell_clone' => clone_names },
          :attributes => [
            'escell_clone',
            'pipeline',
            'mgi_accession_id',
            'allele_symbol_superscript',
            'mutation_subtype',
            'production_qc_loxp_screen'
          ],
        }
      ]
    )
  end

  def self.create_clone_from_mart_data(mart_data)
    clone = self.new
    clone.assign_attributes_from_mart_data(mart_data)
    clone.save!
    return clone
  end

  def assign_attributes_from_mart_data(mart_data)
    pipeline = Pipeline.find_or_create_by_name(mart_data['pipeline'])
    self.attributes = {
      :clone_name => mart_data['escell_clone'],
      :marker_symbol => mart_data['marker_symbol'],
      :allele_name_superscript => mart_data['allele_symbol_superscript'],
      :pipeline => pipeline,
      :mgi_accession_id => mart_data['mgi_accession_id']
    }
  end

  def self.create_all_from_marts_by_clone_names(clone_names)
    result = get_clones_from_marts_by_clone_names(clone_names.to_a)

    return result.map do |mart_data|
      begin
        self.create_clone_from_mart_data(mart_data)
      rescue Exception => e
        e2 = e.class.new("Error while importing #{mart_data['escell_clone']}: #{e.message}")
        e2.set_backtrace(e.backtrace)
        raise e2
      end
    end
  end

  def self.find_or_create_from_marts_by_clone_name(clone_name)
    clone = self.find_by_clone_name(clone_name)
    return clone if(clone)

    return nil if clone_name.blank?

    result = get_clones_from_marts_by_clone_names([clone_name])
    if(result.empty?)
      return nil
    else
      return self.create_clone_from_mart_data(result[0])
    end
  end

  def self.get_clones_from_marts_by_marker_symbol(marker_symbol)
    return nil if marker_symbol.blank?
    return IDCC_TARG_REP_DATASET.search(
      :filters => {},
      :attributes => [
        'escell_clone',
        'pipeline',
        'production_qc_loxp_screen',
        'mutation_subtype'
      ],
      :required_attributes => ['escell_clone'],
      :process_results => true,
      :timeout => 600,
      :federate => [
        {
          :filters => { 'marker_symbol' => [marker_symbol] },
          :attributes => [
            'marker_symbol'
          ],
          :dataset => DCC_DATASET,
        }
      ]
    ).sort_by {|i| i['escell_clone']}
  end

  def self.sync_all_with_marts
    all_clones = Clone.all
    all_clones_data = get_clones_from_marts_by_clone_names all_clones.map(&:clone_name)

    all_clones_data.each do |clone_data|
      clone = all_clones.detect {|c| c.clone_name == clone_data['escell_clone']}
      clone.assign_attributes_from_mart_data(clone_data)
      clone.save!
    end
  end

  # END Mart Operations

end

# == Schema Information
# Schema version: 20110527121721
#
# Table name: clones
#
#  id                               :integer         not null, primary key
#  clone_name                       :text            not null
#  marker_symbol                    :text            not null
#  allele_name_superscript_template :text
#  allele_type                      :text
#  pipeline_id                      :integer         not null
#  mgi_accession_id                 :text
#  created_at                       :datetime
#  updated_at                       :datetime
#
# Indexes
#
#  index_clones_on_clone_name  (clone_name) UNIQUE
#
