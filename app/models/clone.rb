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

  class NotFoundError < RuntimeError; end

  def self.update_or_create_from_marts_by_clone_name(clone_name)
    query = IDCC_TARG_REP_DATASET.search(
      :filters => { "escell_clone" => [clone_name] },
      :attributes => [
        "escell_clone",
        "pipeline",
        "mgi_accession_id",
        "allele_symbol_superscript"
      ],
      :process_results => true,
      :timeout => 300,
      :federate => [
        {
          :dataset => DCC_DATASET,
          :filters => {},
          :attributes => ['marker_symbol']
        }
      ]
    )

    if query.blank?
      raise NotFoundError, clone_name.inspect
    end

    clone = Clone.create!(
      :clone_name => query[0]['escell_clone'],
      :marker_symbol => query[0]['marker_symbol'],
      :allele_name_superscript => query[0]['allele_symbol_superscript'],
      :pipeline => Pipeline.find_by_name!(query[0]['pipeline']),
      :mgi_accession_id => query[0]['mgi_accession_id']
    )
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

