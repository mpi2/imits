class TargRep::TargetedAllele < TargRep::Allele

  validates :homology_arm_start, :presence => true, :numericality => {:only_integer => true, :greater_than => 0}
  validates :homology_arm_end,   :presence => true, :numericality => {:only_integer => true, :greater_than => 0}

  after_save :check_and_set_type

  protected
    def check_and_set_type
      if mutation_type.gene_trap?
        update_attribute(:type, 'TargRep::GeneTrap')
      end
    end

end

# == Schema Information
#
# Table name: targ_rep_alleles
#
#  id                  :integer         not null, primary key
#  gene_id             :integer
#  assembly            :string(50)      default("NCBIM37"), not null
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
#

