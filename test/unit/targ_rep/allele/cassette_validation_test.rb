require 'pp'
require 'test_helper'

class TargRep::Allele::CassetteValidationTest < ActiveSupport::TestCase

  context 'TargRep::Allele::CassetteValidation' do

    [:allele, :gene_trap, :crispr_targeted_allele].each do |model|
      context "#{model}" do
        setup do
          @allele = Factory.create(model)
          # allele has been saved successfully here
        end

        context "An Allele" do

          should "not be saved with the wrong 'cassette_type' for a KNOWN cassette" do
            allele = Factory.build model, { :cassette => 'L1L2_st1', :cassette_type => 'Promotor Driven' }
            assert !allele.save, "Allele 'has_correct_cassette_type' validation did not work for L1L2_st1!"

            allele = Factory.build model, { :cassette => 'L1L2_Bact_P', :cassette_type => 'Promotorless' }
            assert !allele.save, "Allele 'has_correct_cassette_type' validation did not work for L1L2_Bact_P!"
          end

          should "be saved when the correct 'cassette_type' is entered though..." do
            allele = Factory.build model, { :cassette => 'L1L2_st1', :cassette_type => 'Promotorless' }
            assert allele.save, "Allele 'has_correct_cassette_type' is not accepting L1L2_st1 as a Promotorless cassette!"
          end
        end
      end
    end
  end
end