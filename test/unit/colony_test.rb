require 'test_helper'

class ColonyTest < ActiveSupport::TestCase
  	context 'Colony' do
	    context "validations" do
	    	should "have a name" do
	    		validate_presence_of :name
	    	end
		end

	    context "relationships" do
		    should "belong to an mi_attempt" do
	    		belong_to :mi_attempt
	    	end

	    	should "have one colony qc" do
	    		have_one(:colony_qc)
	    	end

	    	should "allow nested attributes for colony_qc" do
	    		accept_nested_attributes_for(:colony_qc)
	    	end
		end

		context "db columns" do
	      	should 'have name' do
        		assert_should have_db_column(:name).of_type(:string).with_options(:null => false)
      		end
      		should 'have mi_attempt_id' do
        		assert_should have_db_column(:mi_attempt_id).of_type(:integer)
      		end
      		should 'have genotype_confirmed' do
        		assert_should have_db_column(:genotype_confirmed).of_type(:boolean).with_options(:default => false)
      		end
      	end
  	end
end
