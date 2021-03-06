class TargRep::RealAllele < ActiveRecord::Base

  acts_as_audited

  before_validation :check_allele_type

  extend AccessAssociationByAttribute
  ##
  ## Associations
  ##
  belongs_to :gene

  access_association_by_attribute :gene, :mgi_accession_id

  has_many   :mi_attempts,                :dependent => :destroy, :foreign_key => 'real_allele_id'
  has_many   :phenotype_attempts,         :dependent => :destroy, :foreign_key => 'real_allele_id'
  has_many   :mouse_allele_mods,          :dependent => :destroy, :foreign_key => 'real_allele_id'
  has_many   :targ_rep_es_cells,          :dependent => :destroy, :foreign_key => 'real_allele_id'

  delegate :marker_symbol,    :to => :gene

  ##
  ## Validations
  ##
  validates                 :gene_id,           :presence => true
  validates                 :allele_name,       :presence => true

  # allele name needs to be unique for a gene id
  validates_uniqueness_of   :allele_name,
    :scope => [ :gene_id ],
    :message => "must have a unique combination of gene id and allele name"

  # allele type needs to be one of fixed selection
  # tm1a: KO first allele (reporter-tagged insertion allele)
  # tm1b: Reporter-tagged deletion allele (post-Cre)
  # tm1c: Conditional allele (post-Flp)
  # tm1d: Deletion allele (post-Flp and Cre with no reporter)
  # tm1e: targeted, non-conditional allele
  # tm1: Reporter-tagged deletion allele (with selection cassette)
  # tm1.1: Reporter-tagged deletion allele (post Cre, with no selection cassette)
  # tm1.2: Reporter-tagged deletion allele (post Flp, with no reporter and selection cassette)
  validates_inclusion_of :allele_type,
    :in => ['a','b','c','d','e','e.1','.1','.2', '', 'gt'],
    :message => "Allele Type can only be 'a','b','c','d','e','e.1','.1','.2', 'gt' or an empty string (for deletions), or nil"

    CRE_GUESS_MAPPING = {'a'                        => 'b',
                         'e'                        => 'e.1',
                         ''                         => '.1'
                        }
    FLP_GUESS_MAPPING = {'a'                        => 'c',
                         'e'                        => 'e.2',
                         ''                         => '.2'
                       }

    DRE_GUESS_MAPPING = {''                         => '.3'
                        }

    FLP_CRE_GUESS_MAPPING = {'a'                    => 'd'
                            }

  # set allele type from allele name
  def check_allele_type
    unless allele_name.blank?
      # fetch the allele type from the name e.g. from tm1a(EUCOMM)Wtsi is 'a'
      part1, part2, part3 = ""

      if match = /\A(tm\d)([a-e]|[a-e].\d|.\d|\d)?(\(\w+\)\w+)\Z/.match(allele_name)
        part1, part2, part3 = match.captures
        if ( part2.nil? || part2.empty? )
          # deletion set to empty string
          self.allele_type = ''
        else
          self.allele_type = part2
        end
      elsif match = /\A(tm\d)(([a-e])|(\(\w+\)))?\Z/.match(allele_name)
        # for 'guessed' allele names e.g. tm1, tm1a, tm1(Cre)
        part1, part2 = match.captures
        if ( part2.nil? || part2.empty? || part2 == '(Cre)')
          # deletion set to empty string
          self.allele_type = ''
        else
          self.allele_type = part2
        end
      elsif match = /\A([Gg]t)(\(\w+\)\w+)?\Z/.match(allele_name)
        # for gene traps e.g. gt, Gt(IST12471H5)Tigm
        self.allele_type = 'gt'
      else
        # error, not a matching allele name
        self.errors.add :allele_name, "Unexpected allele name format, cannot determine allele type from '#{allele_name}'"
      end

      # puts "check_allele_type : allele type #{self.allele_type}"
    end
  end

  def self.types
    ['a','b','c','d','e','e.1','.1','.2', '', 'gt']
  end


  def self.mutagenesis_url(data = {})
    mgi_accession_id = data['mgi_accession_id'] || nil
    allele_symbol = data['allele_symbol'] || nil
    allele_type = data['allele_type'] || nil
    if !data['pipeline'].blank?
      if data['pipeline'].class.name == Array
        pipelines = data['pipeline']
      else
        pipelines = [data['pipeline']]
      end
    else
      pipelines = data['pipeline'] || nil
    end

    return '' if mgi_accession_id.blank? || allele_symbol.blank?
    return '' if allele_type.nil? || pipelines.blank?
    return '' if pipelines.all?{|pipeline| ['NorCOMM', 'EUCOMMToolsCre', 'Mirko', 'KOMP-Regeneron'].include?(pipeline)}
    return '' unless ['a', 'c', 'e', ''].include?(allele_type)

    return "https://www.mousephenotype.org/phenotype-archive/mutagenesis/#{mgi_accession_id}/#{allele_symbol}"
  end

  def self.lrpcr_genotype_primers(mgi_accession_id, allele_symbol, allele_type)
    return '' if mgi_accession_id.blank? || allele_symbol.blank? || allele_type.blank? || !['a', 'e', ''].include?(allele_type)
    return "https://www.mousephenotype.org/phenotype-archive/lrpcr/#{mgi_accession_id}/#{allele_symbol}"
  end

  def self.genotype_primers_url(mgi_accession_id, allele_symbol, allele_type)
    return '' if mgi_accession_id.blank? || allele_symbol.blank? || allele_type.blank? || !['a', 'e', ''].include?(allele_type)
    return "https://www.mousephenotype.org/phenotype-archive/genotyping_primers/#{mgi_accession_id}/#{allele_symbol}"
  end

end

# == Schema Information
#
# Table name: targ_rep_real_alleles
#
#  id               :integer          not null, primary key
#  gene_id          :integer          not null
#  allele_name      :string(40)       not null
#  allele_type      :string(10)
#  mgi_accession_id :string(255)
#
# Indexes
#
#  real_allele_logical_key  (gene_id,allele_name) UNIQUE
#
