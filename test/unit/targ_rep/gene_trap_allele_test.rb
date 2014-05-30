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
  should allow_value(nil,true,false).for(:has_issue)

  should 'default allele types to false except for gene_trap' do
    assert_false @allele.class.targeted_allele?
    assert_true @allele.class.gene_trap?
    assert_false @allele.class.hdr_allele?
    assert_false @allele.class.nhej_allele?
    assert_false @allele.class.crispr_targeted_allele?
  end

  context "An Allele - check normal creation" do
    should "be saved" do
      allele = Factory.build :gene_trap
      assert allele.save, "Targeted allele saves for a normal entry"
      attributes_after_save = allele.attributes
      allele_after_select = TargRep::GeneTrap.find( allele.id )
      attributes_after_reselect = allele_after_select.attributes

      assert_equal attributes_after_reselect.keys.size, attributes_after_save.keys.size

      #attributes_after_reselect.keys.each do |key|
      #  puts "#### test #{key}: '#{attributes_after_reselect[key]}'/'#{attributes_after_save[key]}'"
      #  if key == 'created_at' || key == 'updated_at'
      #    #puts "#### test 2 #{key}: (#{attributes_after_reselect[key].to_i}/#{attributes_after_save[key].to_i})"
      #    assert_equal attributes_after_reselect[key].to_i, attributes_after_save[key].to_i
      #    next
      #  end
      #  assert_equal attributes_after_reselect[key], attributes_after_save[key]
      #end

      attributes_after_reselect['created_at'] = attributes_after_reselect['created_at'].to_i
      attributes_after_reselect['updated_at'] = attributes_after_reselect['updated_at'].to_i

      attributes_after_save['created_at'] = attributes_after_save['created_at'].to_i
      attributes_after_save['updated_at'] = attributes_after_save['updated_at'].to_i

      assert_equal attributes_after_reselect, attributes_after_save
    end
  end
end

