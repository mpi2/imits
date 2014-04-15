require 'pp'
require 'test_helper'

class TargRep::TargetedAlleleTest < ActiveSupport::TestCase
  setup do
    @allele = Factory.create(:allele)
    # allele has been saved successfully here
  end


  should 'inherit from TargRep::Allele' do
    # If I am removed you must write the coresponding tests that appear in TargRep::Allele
    assert_true TargRep::TargetedAllele < TargRep::Allele
  end


  should validate_uniqueness_of(:project_design_id).scoped_to([
      :gene_id, :assembly, :chromosome, :strand,
      :cassette, :backbone,
      :homology_arm_start, :homology_arm_end,
      :cassette_start, :cassette_end,
      :loxp_start, :loxp_end
    ]).with_message("must have unique design features")


  [ :gene, :assembly, :chromosome,
    :strand, :mutation_type, :mutation_method, :homology_arm_start, :homology_arm_end,
    :cassette,:cassette_start, :cassette_end, :cassette_type
  ].each do |attribute|
    should validate_presence_of(attribute)
  end


  [ :homology_arm_start, :homology_arm_end, :cassette_start, :cassette_end,
    :loxp_start, :loxp_end
  ].each do |attribute|
    should validate_numericality_of(attribute).is_greater_than(0)
  end

  [:loxp_start, :loxp_end].each do |attribute|
    should allow_value(nil).for(attribute)
  end


  should ensure_inclusion_of(:cassette_type).in_array(["Promotorless", "Promotor Driven"]).with_message("Cassette Type can only be 'Promotorless' or 'Promotor Driven'")


  context "An Allele" do

    context "check normal creation" do
      should "be saved" do
        allele = Factory.build :allele
        assert allele.save, "Targeted allele saves for a normal entry"
        attributes_after_save = allele.attributes
        allele_after_select = TargRep::TargetedAllele.find( allele.id )
        attributes_after_reselect = allele_after_select.attributes
        assert_equal attributes_after_reselect, attributes_after_save
      end
    end

    context "with mutation type 'Deletion' and LoxP set" do
      should "not be saved" do
        allele = Factory.build(:allele, {
            :mutation_type        => TargRep::MutationType.find_by_code!('del'),
            :strand             => '+',
            :loxp_start         => 100,
            :loxp_end           => 130
          })
        assert !allele.save, "Allele validates presence of LoxP for mutation_type 'Deletion'"
      end
    end

    context "with mutation type 'Insertion' and LoxP set" do
      should "not be saved" do
        allele = Factory.build(:allele, {
            :mutation_type        => TargRep::MutationType.find_by_code!('ins'),
            :strand             => '+',
            :loxp_start         => 100,
            :loxp_end           => 130
          })
        assert !allele.save, "Allele validates presence of LoxP for mutation_type 'cre-knock-in'"
      end
    end
  end

  should 'default allele types to false' do
    assert_true @allele.class.targeted_allele?
    assert_false @allele.class.gene_trap?
    assert_false @allele.class.hdr_allele?
    assert_false @allele.class.nhej_allele?
    assert_false @allele.class.crispr_targeted_allele?
  end
end
