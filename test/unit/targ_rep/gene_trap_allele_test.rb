require 'test_helper'

class TargRep::GeneTrapTest < ActiveSupport::TestCase
  setup do
    @allele = Factory.create(:gene_trap)
    # allele has been saved successfully here
  end

  should 'inherit from TargRep::Allele' do
    # If I am removed you must write the coresponding tests that appear in TargRep::Allele
    assert_true TargRep::GeneTrap < TargRep::Allele
  end

  # test validation
  should validate_presence_of(:intron)
  should validate_presence_of(:cassette)
  should validate_presence_of(:cassette_type)
  should validate_presence_of(:cassette_start)
  should validate_presence_of(:cassette_end)

  should_not allow_value(nil).for(:intron)
  should allow_value(nil).for(:homology_arm_start)
  should allow_value(nil).for(:homology_arm_end)
  should allow_value(nil).for(:backbone)
  should allow_value(nil).for(:floxed_start_exon)

  should 'save' do
    @allele = Factory.build(:gene_trap)
    assert_true @allele.save
  end

  should 'default allele types to false except for gene_trap' do
    assert_false @allele.class.targeted_allele?
    assert_true @allele.class.gene_trap?
    assert_false @allele.class.hdr_allele?
    assert_false @allele.class.nhej_allele?
    assert_false @allele.class.crispr_targeted_allele?
  end
end