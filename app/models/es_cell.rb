# encoding: utf-8

class EsCell < ActiveRecord::Base
  acts_as_reportable

  TEMPLATE_CHARACTER = '@'

  belongs_to :pipeline
  has_many :mi_attempts

  validates :name, :presence => true, :uniqueness => true
  validates :marker_symbol, :presence => true
  validates :pipeline, :presence => true

  attr_protected :allele_symbol_superscript_template

  def allele_symbol_superscript
    if allele_type
      return allele_symbol_superscript_template.sub(TEMPLATE_CHARACTER, allele_type)
    else
      return allele_symbol_superscript_template
    end
  end

  class AlleleSymbolSuperscriptFormatUnrecognizedError < RuntimeError; end

  def allele_symbol_superscript=(text)
    if text.nil?
      self.allele_symbol_superscript_template = nil
      self.allele_type = nil
      return
    end

    md = /\A(tm\d)([a-e])?(\(\w+\)\w+)\Z/.match(text)

    if md
      if md[2].blank?
        self.allele_symbol_superscript_template = md[1] + md[3]
        self.allele_type = nil
      else
        self.allele_symbol_superscript_template = md[1] + TEMPLATE_CHARACTER + md[3]
        self.allele_type = md[2]
      end
    else
      md = /\AGt\(\w+\)\w+\Z/.match(text)
      if md
        self.allele_symbol_superscript_template = text
        self.allele_type = nil
      else
        raise AlleleSymbolSuperscriptFormatUnrecognizedError, "Bad allele symbol superscript #{text}"
      end
    end

  end

  def allele_symbol
    if allele_symbol_superscript
      return "#{marker_symbol}<sup>#{allele_symbol_superscript}</sup>"
    else
      return nil
    end
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

  def self.get_es_cells_from_marts_by_names(names)
    raise ArgumentError, 'Need array of ES cell names please' unless names.kind_of?(Array)
    return DCC_DATASET.search(
      :filters => {},
      :attributes => ['marker_symbol'],
      :process_results => true,
      :timeout => 600,
      :federate => [
        {
          :dataset => IDCC_TARG_REP_DATASET,
          :filters => { 'escell_clone' => names },
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

  def self.create_es_cell_from_mart_data(mart_data)
    es_cell = self.new
    es_cell.assign_attributes_from_mart_data(mart_data)
    es_cell.save!
    return es_cell
  end

  def assign_attributes_from_mart_data(mart_data)
    pipeline = Pipeline.find_or_create_by_name(mart_data['pipeline'])
    self.attributes = {
      :name => mart_data['escell_clone'],
      :marker_symbol => mart_data['marker_symbol'],
      :allele_symbol_superscript => mart_data['allele_symbol_superscript'],
      :pipeline => pipeline,
      :mgi_accession_id => mart_data['mgi_accession_id']
    }
  end

  def self.create_all_from_marts_by_names(names)
    result = get_es_cells_from_marts_by_names(names.to_a)

    return result.map do |mart_data|
      begin
        self.create_es_cell_from_mart_data(mart_data)
      rescue Exception => e
        e2 = e.class.new("Error while importing #{mart_data['escell_clone']}: #{e.message}")
        e2.set_backtrace(e.backtrace)
        raise e2
      end
    end
  end

  def self.find_or_create_from_marts_by_name(name)
    es_cell = self.find_by_name(name)
    return es_cell if(es_cell)

    return nil if name.blank?

    result = get_es_cells_from_marts_by_names([name])
    if(result.empty?)
      return nil
    else
      return self.create_es_cell_from_mart_data(result[0])
    end
  end

  def self.get_es_cells_from_marts_by_marker_symbol(marker_symbol)
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
    all_es_cells = EsCell.all
    all_es_cells_data = get_es_cells_from_marts_by_names all_es_cells.map(&:name)

    all_es_cells_data.each do |es_cell_data|
      es_cell = all_es_cells.detect {|c| c.name == es_cell_data['escell_clone']}
      es_cell.assign_attributes_from_mart_data(es_cell_data)
      es_cell.save!
    end
  end

  # END Mart Operations

end

# == Schema Information
# Schema version: 20110527121721
#
# Table name: es_cells
#
#  id                                 :integer         not null, primary key
#  name                               :text            not null
#  marker_symbol                      :text            not null
#  allele_symbol_superscript_template :text
#  allele_type                        :text
#  pipeline_id                        :integer         not null
#  mgi_accession_id                   :text
#  created_at                         :datetime
#  updated_at                         :datetime
#
# Indexes
#
#  index_es_cells_on_name  (name) UNIQUE
#

