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
  should allow_value(nil,true,false).for(:has_issue)

  context "An Allele" do
    context "check normal creation" do
      should "be saved" do
        allele = Factory.build :allele
        assert allele.save, "Targeted allele saves for a normal entry"
        attributes_after_save = allele.attributes
        allele_after_select = TargRep::TargetedAllele.find( allele.id )
        attributes_after_reselect = allele_after_select.attributes

        assert_equal attributes_after_reselect.keys.size, attributes_after_save.keys.size

        attributes_after_reselect.keys.each do |key|
          assert_equal attributes_after_reselect[key], attributes_after_save[key]
        end
      end
    end
  end
end