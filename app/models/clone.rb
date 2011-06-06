# encoding: utf-8

class Clone < ActiveRecord::Base
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

  IDCC_TARG_REP_DATASET = Biomart::Dataset.new(
    "http://www.knockoutmouse.org/biomart",
    { :name => "idcc_targ_rep" }
  )

  DCC_DATASET = Biomart::Dataset.new(
    "http://www.knockoutmouse.org/biomart",
    { :name => "dcc" }
  )

  scope :all_in_targ_rep, :conditions => {:is_in_targ_rep => true}

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
      begin
        pipeline = Pipeline.find_or_create_by_name(clone_data['pipeline'])

        Clone.create!(
          :clone_name => clone_data['escell_clone'],
          :marker_symbol => clone_data['marker_symbol'],
          :allele_name_superscript => clone_data['allele_symbol_superscript'],
          :pipeline => pipeline,
          :mgi_accession_id => clone_data['mgi_accession_id'],
          :is_in_targ_rep => true
        )
      rescue Exception => e
        e2 = e.class.new("Error while importing #{clone_data['escell_clone']}: #{e.message}")
        e2.set_backtrace(e.backtrace)
        raise e2
      end
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

