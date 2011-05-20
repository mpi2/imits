# encoding: utf-8

class Clone < ActiveRecord::Base
  TEMPLATE_CHARACTER = '@'

  belongs_to :pipeline
  has_many :mi_attempts

  validates :clone_name, :presence => true, :uniqueness => true
  validates :marker_symbol, :presence => true
  validates :allele_name_superscript_template, :presence => true
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
    re = /\A(tm\d)([a-e])?(\(\w+\)\w+)\Z/

    md = re.match(text)

    if ! md
      raise AlleleNameSuperscriptFormatUnrecognizedError, "Bad allele name superscript #{text}"
    end

    if md[2].blank?
      self.allele_name_superscript_template = md[1] + md[3]
      self.allele_type = nil
    else
      self.allele_name_superscript_template = md[1] + TEMPLATE_CHARACTER + md[3]
      self.allele_type = md[2]
    end
  end

  def allele_name
    return "#{marker_symbol}<sup>#{allele_name_superscript}</sup>"
  end

  IDCC_TARG_REP_DATASET = Biomart::Dataset.new(
    "http://www.knockoutmouse.org/biomart",
    { :name => "idcc_targ_rep" }
  )

  DCC_DATASET = Biomart::Dataset.new(
    "http://www.knockoutmouse.org/biomart",
    { :name => "dcc" }
  )

  def self.federated_query(clone_names)
    return IDCC_TARG_REP_DATASET.search(
      :filters => { "escell_clone" => clone_names },
      :attributes => [
        "escell_clone",
        "pipeline",
        "mgi_accession_id",
        "allele_symbol_superscript"
      ],
      :process_results => true,
      :timeout => 600,
      :federate => [
        {
          :dataset => DCC_DATASET,
          :filters => {},
          :attributes => ['marker_symbol']
        }
      ]
    )
  end

  class NotFoundError < RuntimeError; end

  def self.update_or_create_from_marts_by_clone_name(clone_name)
    clones = create_all_from_marts_by_clone_names([clone_name])
    if clones.empty?
      raise NotFoundError, clone_name.inspect
    end
    return clones.first
  end

  def self.create_all_from_marts_by_clone_names(clone_names)
    query = federated_query(clone_names.to_a)

    return query.map do |clone_data|
      pipeline = Pipeline.find_by_name(clone_data['pipeline'])
      if(!pipeline)
        pipeline = Pipeline.create!(:name => clone_data['pipeline'])
      end

      Clone.create!(
        :clone_name => clone_data['escell_clone'],
        :marker_symbol => clone_data['marker_symbol'],
        :allele_name_superscript => clone_data['allele_symbol_superscript'],
        :pipeline => pipeline,
        :mgi_accession_id => clone_data['mgi_accession_id']
      )
    end
  end

end



# == Schema Information
# Schema version: 20110421150000
#
# Table name: clones
#
#  id                               :integer         not null, primary key
#  clone_name                       :text            not null
#  marker_symbol                    :text            not null
#  allele_name_superscript_template :text            not null
#  allele_type                      :text
#  pipeline_id                      :integer         not null
#  created_at                       :datetime
#  updated_at                       :datetime
#

