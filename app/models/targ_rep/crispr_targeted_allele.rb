class TargRep::CrisprTargetedAllele < TargRep::Allele
  include TargRep::Allele::CassetteValidation
  include TargRep::Allele::FeatureValidation

  def pipeline_names
    nil
  end

  def self.crispr_targeted_allele?; true; end

end

# == Schema Information
#
# Table name: targ_rep_alleles
#
#  id                  :integer          not null, primary key
#  gene_id             :integer
#  assembly            :string(255)      default("GRCm38"), not null
#  chromosome          :string(2)        not null
#  strand              :string(1)        not null
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
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  intron              :integer
#  type                :string(255)      default("TargRep::TargetedAllele")
#  sequence            :text
#  has_issue           :boolean          default(FALSE), not null
#  issue_description   :text
#
