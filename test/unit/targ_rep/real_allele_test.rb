require 'test_helper'

class TargRep::AllelesRealTest < ActiveSupport::TestCase

  setup do
    @real_allele = Factory.create(:base_real_allele)
    # real allele has been saved successfully here
  end

  should 'save' do
    @real_allele = Factory.build(:base_real_allele)
    assert_true @real_allele.save
  end

end