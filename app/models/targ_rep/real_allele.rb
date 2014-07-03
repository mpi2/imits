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
  has_many   :targ_rep_targeting_vectors, :dependent => :destroy, :foreign_key => 'real_allele_id'

  delegate :mgi_accession_id, :to => :gene
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
  validates_inclusion_of :allele_type,
    :in => ['a','b','c','d','e','e.1', nil],
    :message => "Allele Type can only be 'a','b','c','d','e','e.1', or nil for deletions"

  # set allele type from allele name
  def check_allele_type
    unless allele_name.blank?
      # fetch the allele type from the name e.g. from tm1a(EUCOMM)Wtsi is 'a'
      part1, part2, part3 = ""
      if match = /\A(tm\d)([a-e]|[a-e].\d|\d)?(\(\w+\)\w+)\Z/.match(allele_name)
        part1, part2, part3 = match.captures
      else
        # error, not a matching allele name
        self.errors.add :allele_name, "Unexpected allele name format, cannot determine allele type from '#{allele_name}'"
      end

      if ( part2.nil? || part2.empty? )
        self.allele_type = nil
      else
        self.allele_type = part2
      end
    end
  end
end

# == Schema Information
#
# Table name: targ_rep_real_alleles
#
#  id          :integer          not null, primary key
#  gene_id     :integer          not null
#  allele_name :string(20)       not null
#  allele_type :string(10)
#
# Indexes
#
#  real_allele_logical_key  (gene_id,allele_name) UNIQUE
#
