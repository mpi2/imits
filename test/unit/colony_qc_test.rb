require 'test_helper'

class ColonyQcTest < ActiveSupport::TestCase
	context 'ColonyQc' do

	  	context "Validations" do
		    should "check for prescence of colony id during validation" do
		    	validate_presence_of :colony_id
		    end
		end

		context "Assocations" do
		    should "belong to a colony" do
	    		belong_to :colony
	    	end
	    end

	 #    def default_mi_attempt
		#     @default_mi_attempt ||= Factory.create(:mi_attempt2)
		# end

	    context "Model creation" do

	    	setup do
	          @mi = Factory.create(:mi_attempt2)
	        end

	        # should "validate the mi_attempt" do
	        # 	@mi.validate
	        # end

	        # should "save the mi_attempt" do
	        # 	@mi.save
	        # end

		    # basic creation should work
			should "create a default colony for the mi_attempt" do
				assert_not_nil @mi.colony
			end

			should "create a default colony qc for the colony" do
				assert_not_nil @mi.colony.colony_qc
			end

		    # basic creation should set qc fields to 'na'
		    # assert_equal 'na',

		    # creation with qc values of 'pass' or 'fail' or 'na' should work

		    # should_not allow_value("blah").for(:qc_field)

		end

	    # should "add two numbers for the sum" do
	    #   assert_equal 4, @calculator.sum(2, 2)
	    # end
  	end
end
