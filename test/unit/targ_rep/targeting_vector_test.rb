require 'test_helper'

class TargRep::TargetingVectorTest < ActiveSupport::TestCase
  setup do
    Factory.create :targeting_vector
  end

  should belong_to(:pipeline)
  should belong_to(:allele)

  should have_many(:es_cells)

  should validate_uniqueness_of(:name)

  should validate_presence_of(:name)
  should validate_presence_of(:allele)

  context "TargRep::TargetingVector" do
    should "not be saved if it has empty attributes" do
      targ_vec = Factory.build :invalid_targeting_vector
      assert !targ_vec.valid?, "Targeting vector validates an empty entry"
      assert !targ_vec.save, "Targeting vector validates the creation of an empty entry"
    end

    should "set mirKO ikmc_project_ids to 'mirKO' + self.allele_id" do
      allele   = Factory.create :allele
      pipeline = TargRep::Pipeline.find_by_name! 'mirKO'
      targ_vec = Factory.create :targeting_vector, :pipeline => pipeline, :allele => allele, :ikmc_project_id => nil
      assert targ_vec.valid?
      assert_equal "mirKO#{ allele.id }", targ_vec.ikmc_project_id

      targ_vec2 = Factory.create :targeting_vector, :pipeline => pipeline, :allele => allele, :ikmc_project_id => 'mirKO'
      assert_equal "mirKO#{ allele.id }", targ_vec2.ikmc_project_id
    end
  end
end

