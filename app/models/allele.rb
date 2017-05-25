class Allele < ApplicationModel
  include ::Public::Serializable

  acts_as_audited
  acts_as_reportable

  FULL_ACCESS_ATTRIBUTES = %w{
    mgi_allele_symbol_without_impc_abbreviation
    mgi_allele_symbol_superscript
    mgi_allele_accession_id
    allele_type
    allele_subtype
    contains_lacZ
    mutant_fa
    production_centre_qc_attributes
  }

  READABLE_ATTRIBUTES = %w{
    id
  } + FULL_ACCESS_ATTRIBUTES

  ALLELE_OPTIONS = {
    'a' => 'a - Knockout-first - Reporter Tagged Insertion',
    'b' => 'b - Knockout-First, Post-Cre - Reporter Tagged Deletion',
    'c' => 'c - Knockout-First, Post-Flp - Conditional',
    'd' => 'd - Knockout-First, Post-Flp and Cre - Deletion, No Reporter',
    'e' => 'e - Targeted Non-Conditional',
    'e.1' => 'e.1 - Promoter excision from tm1e mouse',
    '1' => "'' - Reporter Tagged Deletion",
    '.1' => '.1 - Promoter excision from Deletion/Point Mutation ',
    '.2' => '.2 - Promoter excision from Deletion/Point Mutation '
  }.freeze


  CRISPR_ALLELE_OPTIONS = {
    'NHEJ' => 'NHEJ - CRISPR Injection; Mutation resulted from Non Homology End Joining',
    'Deletion' => 'Deletion - CRISPR Injection; Exon Deletion resulted from Non Homology End Joining',
    'HR' => 'HR - CRISPR Injection; Homology directed repair using targeting vector',
    'HDR' => 'HDR - CRISPR Injection; Homology directed repair using oligos',
  }.freeze

  CRISPR_ALLELE_SUB_TYPE_OPTIONS = [
    'Small Deletion',
    'Large Deletion',
    'Exon Deletion',
    'Conditional Ready',
    'Point Mutation'
  ].freeze

  TEMPLATE_CHARACTER = '@'

  attr_accessible(*FULL_ACCESS_ATTRIBUTES)

  belongs_to :es_cell, :class_name => 'TargRep::EsCell'
  belongs_to :colony, :class_name => 'Colony'

  has_one :production_centre_qc, :inverse_of => :allele, :dependent => :destroy

  accepts_nested_attributes_for :production_centre_qc, :update_only =>true

### MODEL VALIDATION
  validates :allele_type, :inclusion => { :in => ALLELE_OPTIONS.keys + CRISPR_ALLELE_OPTIONS.keys }, :allow_nil => true
  validates :allele_subtype, :inclusion => { :in => CRISPR_ALLELE_SUB_TYPE_OPTIONS}, :allow_nil => true
  
  validate do |allele|
    if es_cell.blank? && colony.blank?
      allele.errors.add :base, 'An allele must be assigned to either a Colony or an ES Cell.'
    elsif !es_cell.blank? && !colony.blank?
      allele.errors.add :base, 'An allele cannot be assigned to both an ES Cell and a Colony.'
    end
    return true
  end

  validates_format_of :mgi_allele_accession_id,
    :with      => /^MGI\:\d+$/,
    :message   => "is not a valid MGI Allele ID",
    :allow_nil => true


### CALLBACKS

  before_validation do |allele|
    return true if allele.production_centre_qc.blank?
    return true if allele.colony.mi_attempt.blank? || allele.colony.mi_attempt.es_cell_id.blank?
    return true if allele.colony.mi_attempt.es_cell.allele.mutation_type.try(:code) == 'cki'

    es_cell_allele = allele.colony.mi_attempt.es_cell.alleles[0]

    if allele.production_centre_qc.loxp_confirmation == 'fail' && es_cell_allele.allele_type == 'a'
      allele.allele_type = 'e'
    elsif allele.allele_type == 'e' and (allele.production_centre_qc.loxp_confirmation == 'pass')
      allele.allele_type = 'a'
    end
    return true
  end

  before_validation do |allele|
  # set_default_production_qc
    if allele.production_centre_qc.blank?
      # TO DO should create a new allele for each mutagenesis_factor or one if es_cell_id is not blank
       production_centre_qc_attr = {}
       allele.production_centre_qc_attributes = production_centre_qc_attr
     end
     return true
  end

  before_validation do |allele|
    # auto_assign_allele_for_es_cells
    if allele.belongs_to_colony?
    # Check how allele was created
      # Created by Micro-injection of ES CELL
      if !allele.colony.mi_attempt.blank? && !allele.colony.mi_attempt.es_cell_id.blank?
        es_cell = allele.colony.mi_attempt.es_cell
        if allele.allele_type.blank? || allele.allele_type == es_cell.alleles[0].allele_type
          allele.same_as_es_cell = true
          allele.allele_type = es_cell.alleles[0].allele_type
          allele.genbank_file_id = es_cell.alleles[0].genbank_file_id
          allele.mgi_allele_symbol_superscript = es_cell.alleles[0].mgi_allele_symbol_superscript
          allele.allele_symbol_superscript_template = es_cell.alleles[0].allele_symbol_superscript_template
          allele.mgi_allele_accession_id = es_cell.alleles[0].mgi_allele_accession_id
        else
          allele.same_as_es_cell = false
          
          # Questionable whether we shoud do this. Maybe best to have nothing.
          sql = <<-EOF
            SELECT a1.*
            FROM targ_rep_alleles AS a1
              JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = a2.mutation_type_id
            WHERE 
              a1.cassette = '#{es_cell.allele.cassette}' AND
              a1.homology_arm_start = #{es_cell.allele.homology_arm_start} AND
              a1.homology_arm_end = #{es_cell.allele.homology_arm_end} AND
              a1.cassette_start = #{es_cell.allele.cassette_start} AND
              a1.cassette_end = #{es_cell.allele.cassette_end} AND
              a1.id != #{es_cell.allele.id} AND
              targ_rep_mutation_types.allele_code = '#{allele.allele_type}'
          EOF
          targ_rep_alleles = TargRep::Allele.find_by_sql(sql)

          if targ_rep_alleles.length > 1
            allele.genebank_file_id = targ_rep_alleles[0].allele_genbank_file_id
          end

        end
      # Created by mouse allele mod
      elsif !allele.colony.mouse_allele_mod.blank? && !allele.colony.mouse_allele_mod.parent_colony.mi_attempt.es_cell_id.blank? 
        if !allele.allele_type.blank?
          parent_colony_allele = allele.colony.mouse_allele_mod.parent_colony.alleles[0]
  
          allele.genbank_file_id = parent_colony_allele.genbank_file_id
          if allele.mgi_allele_accession_id.blank?
            allele.allele_symbol_superscript_template = parent_colony_allele.allele_symbol_superscript_template
            allele.mgi_allele_symbol_superscript = parent_colony_allele.allele_symbol_superscript_template.gsub(/\@/, allele.allele_type)     
          end

        end
      end
    end
    return true
  end

  after_save do |allele|
    # sync downstream alleles
    if allele.belongs_to_es_cell?
      mi_cols = Colony.joins(:mi_attempt, :alleles).where("mi_attempts.es_cell_id = #{allele.es_cell_id} AND alleles.same_as_es_cell = true")
      mi_cols.each do |mi_col|
        next if mi_col.alleles.count > 1
        mi_allele = Allele.find(mi_col.alleles.first.id)
        mi_allele.genbank_file_id = allele.genbank_file_id
        mi_allele.mgi_allele_symbol_superscript = allele.mgi_allele_symbol_superscript
        mi_allele.allele_symbol_superscript_template = allele.allele_symbol_superscript_template
        mi_allele.mgi_allele_accession_id = allele.mgi_allele_accession_id
        mi_allele.allele_type = allele.allele_type
        mi_allele.save
      end

    elsif allele.belongs_to_colony?
      mam_cols = Colony.joins(:mouse_allele_mod).where("mouse_allele_mods.parent_colony_id = #{allele.colony.id}")
      mam_cols.each do |mam_col|
        next if mam_col.alleles.count > 1
        mam_allele = Allele.find(mam_col.alleles.first.id)
        mam_allele.genbank_file_id = allele.genbank_file_id
        if mam_allele.mgi_allele_accession_id.blank? && !mam_allele.allele_type.blank?
          mam_allele.allele_symbol_superscript_template = allele.allele_symbol_superscript_template
          mam_allele.mgi_allele_symbol_superscript = allele.allele_symbol_superscript_template.gsub(/\@/, mam_allele.allele_type)     
        end
      end
    else
      raise 'This should not be possible'
    end
  end

  def belongs_to_es_cell?
    return true unless es_cell.blank?
    return false
  end

  def belongs_to_colony?
    return true unless colony.blank?
    return false
  end

  def production_centre_qc_attributes
    json_options = {
    :except => ['id', 'allele_id']
    }
    return production_centre_qc.as_json(json_options)
  end

  def allele_symbol_superscript_template
    self.class.extract_symbol_superscript_template(mgi_allele_symbol_superscript)[0]
  end

  def self.extract_symbol_superscript_template(mgi_allele_symbol_superscript)
    return [nil, nil] if mgi_allele_symbol_superscript.blank?

    symbol_superscript_template = nil
    type = nil

    md = /\A(tm\d+|em\d+|Gt)([a-e]|.\d+|e.\d+)?(\(\w+\))?(\w+)\Z/.match(mgi_allele_symbol_superscript)

    if md
      if 'tm' == md[1][0..1]
        symbol_superscript_template = md[1] + TEMPLATE_CHARACTER + md[3] + md[4]
        type = md[2].blank? ? 1 : md[2]
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
#  colony_id                                   :integer
#  auto_allele_description                     :text
#  allele_description                          :text
#  mutant_fa                                   :text
#  genbank_transition                          :string(255)
#  same_as_es_cell                             :boolean
#  transition_of_es_cell_allele                :boolean
#  transition_of_colony_allele                 :boolean
#  allele_subtype                              :string(255)
#  contains_lacZ                               :boolean          default(FALSE)
#
