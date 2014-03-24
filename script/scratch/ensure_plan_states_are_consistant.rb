#!/usr/bin/env ruby

# to run:
# $ script/runner script/ensure_plan_states_are_consistant.rb

puts 'Selecting all MI Plans'

counter_plans          = 0
counter_invalid_plans  = 0
counter_saved_plans    = 0
counter_unsaved_plans  = 0
counter_status_changed = 0

MiPlan.transaction do
	MiPlan.all(:order => 'id ASC').each do |miplan|
		counter_plans += 1
		puts "Checking plan index #{counter_plans} with ID #{miplan.id}"

		unless miplan.valid?
			puts "Error: Failed validation for plan ID #{miplan.id} for gene #{miplan.gene.marker_symbol}"
			puts "Errors: #{miplan.errors.messages}"
			counter_invalid_plans += 1
			next
		end

		status_before = miplan.status.name
		
		begin
			miplan.save!
			counter_saved_plans += 1
		rescue
			puts "Error: Failed to save plan ID #{miplan.id} for gene #{miplan.gene.marker_symbol}"
		 	counter_unsaved_plans += 1
		end

		status_after = miplan.status.name

		if status_before != status_after
			puts "Alert: Plan status has changed: Before: [ #{status_before} ] After: [ #{status_after} ]"
			counter_status_changed += 1
		end

		# for testing:
		# if counter_plans > 50
		# 	break
		# end
	end
end

puts "---------------------------------------"
puts "Number of plans:                    #{counter_plans}"
puts "Number of successfully saved plans: #{counter_saved_plans}" 
puts "Number where plan changed status:   #{counter_status_changed}"
puts "Number of invalid plans:            #{counter_invalid_plans}"
puts "Number of unsaved plans:            #{counter_unsaved_plans}"
puts "---------------------------------------"
