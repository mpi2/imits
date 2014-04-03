class TargRep::GeneTrap < TargRep::Allele
  include TargRep::Allele::CassetteValidation

  validates :intron, :presence => true
  validates :cassette_start,     :presence => true, :numericality => {:only_integer => true, :greater_than => 0}
  validates :cassette_end,       :presence => true, :numericality => {:only_integer => true, :greater_than => 0}
  validates :cassette,           :presence => true
  validates :cassette_type,      :presence => true

  validates_inclusion_of :cassette_type,
    :in => ['Promotorless','Promotor Driven'],
    :message => "Cassette Type can only be 'Promotorless' or 'Promotor Driven'"

  validates_uniqueness_of :project_design_id,
    :scope => [
      :gene_id, :assembly, :chromosome, :strand,
      :cassette, :backbone,
      :homology_arm_start, :homology_arm_end,
      :cassette_start, :cassette_end,
      :loxp_start, :loxp_end
    ],
    :message => "must have unique design features"

  before_validation :set_mutation_types
  after_save :check_and_set_type

  def missing_fields?
    assembly.blank? ||
    chromosome.blank? ||
    strand.blank? ||
    mutation_type.blank? ||
    cassette_start.blank? ||
    cassette_end.blank? ||
    intron.blank?
  end

  def self.gene_trap?; true; end

  protected
    def check_and_set_type
      if !mutation_type.gene_trap?
        update_attribute(:type, 'TargRep::TargetedAllele')
      end
    end

    def set_mutation_types
      self.mutation_method_name = 'Gene Trap'
      self.mutation_type_name = 'Gene Trap'
    end

end




# == Schema Information
#
# Table name: targ_rep_alleles
#
#  id                  :integer         not null, primary key
#  gene_id             :integer
#  assembly            :string(255)     default("GRCm38"), not null
#  chromosome          :string(2)       not null
#  strand              :string(1)       not null
#  homology_arm_start  :integer
#  homology_arm_end    :integer
#  loxp_start          :integer
#  loxp_end            :integer
#  cassette_start      :integer
#  cassette_end        :integer
#  cassette            :string(100)
#  backbone            :string(100)
#  subtype_description :string(255)
#  floxed_start_exon   :string(255)
#  floxed_end_exon     :string(255)
#  project_design_id   :integer
#  reporter            :string(255)
#  mutation_method_id  :integer
#  mutation_type_id    :integer
#  mutation_subtype_id :integer
#  cassette_type       :string(50)
#  created_at          :datetime        not null
#  updated_at          :datetime        not null
#  intron              :integer
#  type                :string(255)     default("TargRep::TargetedAllele")
#  sequence            :text
#

