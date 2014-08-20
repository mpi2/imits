require 'test_helper'

class ColonyQcTest < ActiveSupport::TestCase
	context 'ColonyQc' do

	  	context "validations" do
		    should "have a colony id" do
		    	validate_presence_of :colony_id
		    end
		end

		context "relationships" do
		    should "belong to a colony" do
	    		belong_to :colony
	    	end
	    end


	    # MiAttempt::QC_FIELDS.each do |qc_field|

     #      should "have #{qc_field}_result association accessor" do
     #        default_mi_attempt.send("#{qc_field}_result=", 'pass')
     #        assert_equal 'pass', default_mi_attempt.send("#{qc_field}_result")

     #        default_mi_attempt.send("#{qc_field}_result=", 'na')
     #        assert_equal 'na', default_mi_attempt.send("#{qc_field}_result")
     #      end

     #      should "default to 'na' if #{qc_field} is assigned a blank" do
     #        default_mi_attempt.send("#{qc_field}_result=", '')
     #        assert default_mi_attempt.valid?
     #        assert_equal 'na', default_mi_attempt.send("#{qc_field}_result")
     #        assert_equal 'na', default_mi_attempt.send(qc_field).try(:description)
     #      end

     #    end

	    context "db columns" do

	    	should 'have colony_id' do
        		assert_should have_db_column(:colony_id).of_type(:integer).with_options(:null => false)
      		end

	    	MiAttempt::QC_FIELDS.each do |qc_field|
	    		should "have #{qc_field} db column" do
	        		assert_should have_db_column(qc_field).of_type(:string).with_options(:null => false)
	      		end
	    	end

	    end

	    context "model creation" do

	    	setup do
	    		# create an mi_attempt with an es_cell
	          	@mi_with_es_cell = Factory.create(:mi_attempt2)
	        end

			should "create a default colony for an mi_attempt with an es_cell" do
				assert_not_nil @mi_with_es_cell.colony
			end

			should "create a default colony qc for the colony" do
				assert_not_nil @mi_with_es_cell.colony.colony_qc
			end

			should "set colony qc fields to na by default" do
				MiAttempt::QC_FIELDS.each do |qc_field|
					assert_true @mi_with_es_cell.colony.colony_qc.send(qc_field) == 'na'
				end
			end

			should "allow update of qc field to only na, pass or fail" do

				MiAttempt::QC_FIELDS.each do |qc_field|
					@mi_with_es_cell.colony.colony_qc.send("#{qc_field}=", 'blah')
					assert_false @mi_with_es_cell.colony.colony_qc.valid?
			    	assert_false @mi_with_es_cell.colony.colony_qc.save

			    	@mi_with_es_cell.colony.colony_qc.send("#{qc_field}=", 'pass')
			    	assert_true @mi_with_es_cell.colony.colony_qc.valid?
			    	assert_true @mi_with_es_cell.colony.colony_qc.save

			    	@mi_with_es_cell.colony.colony_qc.send("#{qc_field}=", 'fail')
			    	assert_true @mi_with_es_cell.colony.colony_qc.valid?
			    	assert_true @mi_with_es_cell.colony.colony_qc.save

			    	@mi_with_es_cell.colony.colony_qc.send("#{qc_field}=", 'na')
			    	assert_true @mi_with_es_cell.colony.colony_qc.valid?
			    	assert_true @mi_with_es_cell.colony.colony_qc.save
				end
			end

			# should "allow access of qc fields via mi_attempt accessors" do

			# 	# use setters
			# 	MiAttempt::QC_FIELDS.each do |qc_field|
			# 		@mi_with_es_cell.send("#{qc_field}_result=", 'pass')
			# 	end

			# 	assert_true @mi_with_es_cell.colony.colony_qc.save

			# 	# test getters
			# 	MiAttempt::QC_FIELDS.each do |qc_field|
			# 		assert_equal 'pass', @mi_with_es_cell.send("#{qc_field}_result")
			# 	end
			# end
		end

  	end
end
