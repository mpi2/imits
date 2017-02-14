class Allele < ApplicationModel
  include ::Public::Serializable

  acts_as_audited
  acts_as_reportable

  FULL_ACCESS_ATTRIBUTES = %w{
    mgi_allele_symbol_without_impc_abbreviation
    mgi_allele_symbol_superscript
    mgi_allele_accession_id
    allele_type
    mutant_fa
    production_centre_qc_attributes
  }

  READABLE_ATTRIBUTES = %w{
    id
  }

  attr_accessible(*FULL_ACCESS_ATTRIBUTES)

  belongs_to :es_cell, :class_name => 'TargRep::EsCell'

  has_one :production_centre_qc, :inverse_of => :allele, :dependent => :destroy

  accepts_nested_attributes_for :production_centre_qc, :update_only =>true


  validates :allele_type, :inclusion => { :in => MOUSE_ALLELE_OPTIONS.keys + CRISPR_MOUSE_ALLELE_OPTIONS.keys }

  validates_format_of :mgi_allele_accession_id,
    :with      => /^MGI\:\d+$/,
    :message   => "is not a valid MGI Allele ID",
    :allow_nil => true

  def production_centre_qc_attributes
    json_options = {
    :except => ['id']
    }
    return mutagenesis_factor.as_json(json_options)
  end

  def allele_symbol_superscript_template
    self.extract_symbol_superscript_template(mgi_allele_symbol_superscript)[0]
  end

  def self.allowed_to_be_blank
    return ['allele_type']
  end

  def self.extract_symbol_superscript_template(mgi_allele_symbol_superscript)
    return [nil, nil] if mgi_allele_symbol_superscript.blank?

    symbol_superscript_template = nil
    type = nil

    md = /\A(tm\d+|em\d+|Gt)([a-e]|.\d+|e.\d+)?(\(\w+\))?(\w+)\Z/.match(mgi_allele_symbol_superscript)

    if md
      if 'tm' == md[1][0..1]
        symbol_superscript_template = md[1] + TEMPLATE_CHARACTER + md[3] + md[4]
        type = ''
        type = md[2]
      else
        symbol_superscript_template = mgi_allele_symbol_superscript
      end
    else
      raise "Bad allele symbol superscript '#{mgi_allele_symbol_superscript}'"
    end

    return [symbol_superscript_template, type]
  end
end

# == Schema Information
#
# Table name: alleles
#
#  id                                          :integer          not null, primary key
#  es_cell_id                                  :integer
#  allele_confirmed                            :boolean          default(FALSE), not null
#  mgi_allele_symbol_without_impc_abbreviation :boolean
#  mgi_allele_symbol_superscript               :string(255)
#  allele_symbol_superscript_template          :string(255)
#  mgi_allele_accession_id                     :string(255)
#  allele_type                                 :string(255)
#  genbank_file_id                             :integer
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null
#
