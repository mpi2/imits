require 'test_helper'

class TargRep::NhejAlleleTest < ActiveSupport::TestCase
  setup do
    @allele = Factory.create(:nhej_allele)
    # allele has been saved successfully here
  end

  should 'inherit from TargRep::Allele' do
    # If I am removed you must write the coresponding tests that appear in TargRep::Allele
    assert_true TargRep::HdrAllele < TargRep::Allele
  end

  # test validation

  should allow_value(nil).for(:backbone)
  should allow_value(nil).for(:homology_arm_start)
  should allow_value(nil).for(:homology_arm_end)
  should allow_value(nil).for(:cassette)
  should allow_value(nil).for(:cassette_type)
  should allow_value(nil).for(:cassette_start)
  should allow_value(nil).for(:cassette_end)
  should allow_value(nil).for(:floxed_start_exon)
  should allow_value(nil).for(:floxed_end_exon)
  should allow_value(nil).for(:loxp_start)
  should allow_value(nil).for(:loxp_end)

  should 'save' do
    assert_true @allele.save
  end

  should 'set default features to nil on validation' do
    @allele = Factory.build :nhej_allele,  {
    :backbone => 'backbone',
    :homology_arm_start => 1,
    :homology_arm_start => 110,
    :cassette => 'cassette 1',
    :cassette_type => 'Promotorless',
    :cassette_start => 30,
    :cassette_end => 50,
    :floxed_start_exon => 'floxed exon start',
    :floxed_end_exon => 'floxed exon end',
    :loxp_start => 70,
    :loxp_end => 80
    }

    @allele.valid?

    assert_nil @allele.homology_arm_start
    assert_nil @allele.homology_arm_end
    assert_nil @allele.cassette
    assert_nil @allele.cassette_type
    assert_nil @allele.cassette_start
    assert_nil @allele.cassette_end
    assert_nil @allele.floxed_start_exon
    assert_nil @allele.floxed_end_exon
    assert_nil @allele.loxp_start
    assert_nil @allele.loxp_end
  end

  should 'default allele types to false except for gene_trap' do
    assert_false @allele.class.targeted_allele?
    assert_false @allele.class.gene_trap?
    assert_false @allele.class.hdr_allele?
    assert_true @allele.class.nhej_allele?
    assert_false @allele.class.crispr_targeted_allele?
  end
end