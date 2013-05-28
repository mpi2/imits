require 'test_helper'

class TargRep::GeneTrapTest < ActiveSupport::TestCase
  setup do
    @allele = Factory.create(:gene_trap)
    # allele has been saved successfully here
  end

  should_not allow_value(nil).for(:intron)
  should allow_value(nil).for(:homology_arm_start)
  should allow_value(nil).for(:homology_arm_end)
  should allow_value(nil).for(:backbone)
  should allow_value(nil).for(:floxed_start_exon)

end