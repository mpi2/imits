#!/usr/bin/env ruby

# to run, be in imits directory and run command:
# $ script/runner script/scratch/copy_mi_colony_qc_data.rb

require 'pp'

##
# This script copies the mi attempt colony qc data from the fields in the mi table into the colony_qcs table.
##

# @sql_query = "SOME SQL WITH SPACE AT END LINE "\
# 	"SUBSEQUENT LINES;"

@sql_select_qc_result = "SELECT qc_results.description "\
	"FROM mi_attempts JOIN qc_results ON qc_results.id = mi_attempts.qc_southern_blot_id "\
	"WHERE mi_attempts.id = ?;"

QC_FIELDS = [
	:qc_southern_blot,
	:qc_five_prime_lr_pcr,
	:qc_five_prime_cassette_integrity,
	:qc_tv_backbone_assay,
	:qc_neo_count_qpcr,
	:qc_lacz_count_qpcr,
	:qc_neo_sr_pcr,
	:qc_loa_qpcr,
	:qc_homozygous_loa_sr_pcr,
	:qc_lacz_sr_pcr,
	:qc_mutant_specific_sr_pcr,
	:qc_loxp_confirmation,
	:qc_three_prime_lr_pcr,
	:qc_critical_region_qpcr,
	:qc_loxp_srpcr,
	:qc_loxp_srpcr_and_sequencing
].freeze

def initialise
  puts "initialise : start"
  @count_mi_attempts_processed             = 0
  @count_mi_attempts_with_es_cells         = 0
  @count_mi_attempts_failed_save           = 0
  @count_mi_plans_failed_save              = 0
  @count_mi_attempts_with_no_colony        = 0
  @count_mi_attempts_with_no_colony_qc     = 0
  @count_mi_attempts_with_colony_qc        = 0
  @count_mi_attempts_successful_data_save  = 0
  @count_mi_attempts_failed_data_save      = 0
  @count_mi_attempts_no_changes_made       = 0
  @count_mi_attempts_invalid               = 0
  @count_mi_attempts_inactive              = 0

  puts "initialise : end"
end


def process_es_cell_mi_attempts()
	puts "process_es_cell_mi_attempts : start"

	# iterate through ALL mi attempts
	Public::MiAttempt.find_each do |mi|

		# next unless mi.id == 3902

		puts "mi_attempt ID = #{mi.id}"

		@count_mi_attempts_processed += 1

		# ignore if mi does not have an es cell
		if mi.es_cell.blank?
			puts "no es cell, skipping"
			next
		end

		@count_mi_attempts_with_es_cells += 1

		# use_validation = true

		deactivate_plan = false

		unless mi.valid?
			puts "Mi Attempt is invalid, checking status"
			puts "#{mi.errors.messages}"
			puts "plan id = #{mi.mi_plan.id}"

			if mi.mi_plan.status.name == 'Inactive'
				@count_mi_attempts_inactive += 1

				puts "changing mi_plan status to active"
				mi.mi_plan.is_active = true
				if mi.mi_plan.valid?
					puts "plan valid"
				else
					puts "plan invalid"
				end

				begin
					mi.mi_plan.save
				rescue Exception=>e
					puts "process_es_cell_mi_attempts : ERROR : failed to save activated MI plan for Mi Attempt with ID #{mi.id}"
		      		puts "process_es_cell_mi_attempts : message : #{e.message}"
		      		@count_mi_plans_failed_save += 1
		      		next
				end

				mi.reload

				deactivate_plan = true
			else
				puts "ERROR : Mi Attempt is invalid and not in state Inactive or Withdrawn, skipping"
				@count_mi_attempts_invalid += 1
				next
			end
		end

		begin
			# save mi_attempt to auto-create a colony and colony_qc
			puts "plan status before save : #{mi.mi_plan.status.name}"
			mi.save
			puts "#{mi.errors.messages}"
			puts "Mi values after initial mi save:"
			display_mi_qc_values(mi)
		rescue Exception=>e
			puts "process_es_cell_mi_attempts : ERROR : failed to save MI attempt with ID #{mi.id}"
      		puts "process_es_cell_mi_attempts : message : #{e.message}"
      		@count_mi_attempts_failed_save += 1
      		next
		end

		if mi.colony.blank?
			puts "WARN: no colony for this mi attempt, skipping"
			@count_mi_attempts_with_no_colony += 1
			next
		end

		if mi.colony.colony_qc.blank?
			puts "WARN: no colony qc for this mi attempt, skipping"
			@count_mi_attempts_with_no_colony_qc += 1
			next
		end

		@count_mi_attempts_with_colony_qc += 1

		changes_made = 0

		QC_FIELDS.each do |qc_field|
			current_field_value_via_model = mi.send("#{qc_field}_result")
			current_field_id = mi.send("#{qc_field}_id")

			# puts "#{qc_field}: current value <#{current_field_value_via_model}> and id <#{current_field_id}>"

			case current_field_id
			when 1
			  if current_field_value_via_model.blank? or current_field_value_via_model != 'na'
			  	mi.send("#{qc_field}_result=", 'na')
			  	# puts "updating to: na"
			  	changes_made += 1
			  end
			when 2
              if current_field_value_via_model.blank? or current_field_value_via_model != 'fail'
			  	mi.send("#{qc_field}_result=", 'fail')
			  	# puts "updating to: fail"
			  	changes_made += 1
			  end
			when 3
              if current_field_value_via_model.blank? or current_field_value_via_model != 'pass'
			    mi.send("#{qc_field}_result=", 'pass')
			    # puts "updating to: pass"
			    changes_made += 1
			  end
			else
			  puts "WARN: unrecognised field id for #{qc_field}, no change made"
			end
		end

		unless changes_made > 0
			puts "no changes made - skipping"
			@count_mi_attempts_no_changes_made += 1

			if deactivate_plan == true
				mi.mi_plan.is_active = false
				begin
					mi.mi_plan.save
				rescue Exception=>e
					puts "process_es_cell_mi_attempts : ERROR : failed to save de-activated MI plan for Mi Attempt with ID #{mi.id}"
			    	puts "process_es_cell_mi_attempts : message : #{e.message}"
			      	@count_mi_plans_failed_save += 1
			    	next
				end
			end

			next
		end

		puts "number of changes made = #{changes_made}, saving updates"

		begin
			# save mi_attempt with data saved in colony_qc table
			mi.save
			puts "#{mi.errors.messages}"
			@count_mi_attempts_successful_data_save += 1
			# mi.reload
			display_mi_qc_values(mi)
		rescue Exception=>e
			puts "process_es_cell_mi_attempts : ERROR : failed to save MI attempt with new data with ID #{mi.id}"
      		puts "process_es_cell_mi_attempts : message : #{e.message}"
      		@count_mi_attempts_failed_data_save += 1
      		next
		end

		if deactivate_plan == true
			mi.mi_plan.is_active = false
			begin
				mi.mi_plan.save
			rescue Exception=>e
				puts "process_es_cell_mi_attempts : ERROR : failed to save de-activated MI plan for Mi Attempt with ID #{mi.id}"
		    	puts "process_es_cell_mi_attempts : message : #{e.message}"
		      	@count_mi_plans_failed_save += 1
		    	next
			end
		end

	end
	puts "process_es_cell_mi_attempts : end"
end

def display_mi_qc_values(mi)
	puts "-----------------------------------------------------"
	puts "        QC values for MI attempt id #{mi.id}"
	puts "-----------------------------------------------------"
	if mi.colony.blank?
		puts "Colony and Colony QC are nil"
	else
		puts "Colony id    = #{mi.colony.id}"
		if mi.colony.colony_qc.blank?
			puts "Colony QC is blank"
		else
			puts "Colony QC id = #{mi.colony.colony_qc.id}"
		end
	end
	puts "-----------------------------------------------------"
	QC_FIELDS.each do |qc_field|
		current_field_value_via_model = mi.send("#{qc_field}_result")
		puts "#{qc_field} = #{current_field_value_via_model}"
	end
	puts "-----------------------------------------------------"
end

def cleanup()
	puts "Counters:"
	puts "---------"
	puts "MI attempts processed                  = #{@count_mi_attempts_processed}"
	puts "MI attempts with ES cells              = #{@count_mi_attempts_with_es_cells}"
	puts "MI attempts without colonies           = #{@count_mi_attempts_with_no_colony}"
	puts "MI attempt colonies without qc         = #{@count_mi_attempts_with_no_colony_qc}"
	puts "MI attempt colonies with qc            = #{@count_mi_attempts_with_colony_qc}"
	puts ""
	puts "MI attempts with successful data save  = #{@count_mi_attempts_successful_data_save}"
	puts ""
	puts "MI attempts where QC data unchanged    = #{@count_mi_attempts_no_changes_made}"
	puts ""
	puts "MI attempts inactive                   = #{@count_mi_attempts_inactive}"
	puts "MI attempts invalid                    = #{@count_mi_attempts_invalid}"
	puts "MI attempts with FAILED initial saves  = #{@count_mi_attempts_failed_save}"
	puts "MI plans with FAILED saves             = #{@count_mi_plans_failed_save}"
	puts "MI attempts with FAILED data saves     = #{@count_mi_attempts_failed_data_save}"
end


# def method_name( parameters )


# end

# any initialisation here
initialise

# do stuff
process_es_cell_mi_attempts

# any cleanup tasks here
cleanup