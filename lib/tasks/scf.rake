
namespace :scf do

  BWA_SLEEPTIME_SECS = 30
  MAX_NUM_TO_PROCESS = 3

  desc 'run the scf process'
  task 'run', [:force] => :environment do |t, args|
    args.with_defaults(:force => false)
    options = {}
    options = { :force => true } if ! args[:force].blank?

    # process a maximum number in one session, irrespective of force flag
    counter = 0
    Colony.joins(:trace_call).order('trace_calls.updated_at, colonies.id').each do |colony|
      next if colony.trace_call.nil?

      if counter >= MAX_NUM_TO_PROCESS
        puts "#### counter above max of #{MAX_NUM_TO_PROCESS}, exit updates"
        exit
      end

      if counter > 0
        # delay between runs to give memory time to clear (BWA) - NB. DOES NOT WORK for t87-dev
        sleep(BWA_SLEEPTIME_SECS)
      end

      # puts "checking colony id #{colony.id} with update timestamp #{colony.trace_call.updated_at}"
      if ( colony.trace_call.crispr_damage_analysis options )
        # puts "colony id #{colony.id} processed"
        counter += 1
      end
    end
  end

  desc 'run one mi_attempts scf files - pass in mi_attempt_id'
  task 'run_one', [:mi_attempt_id] => :environment do |t, args|

    if args[:mi_attempt_id].blank?
      puts "#### supply mi_attempt_id!"
      exit
    end

    options = { :force => true, :keep_generated_files => true }

    mi = MiAttempt.find args[:mi_attempt_id]

    mi.colonies.each do |colony|
      if colony.trace_call.nil?
        puts "#### colony id #{colony.id} has no trace calls"
      end

      if ( colony.trace_call.crispr_damage_analysis options )
        puts "#### colony id #{colony.id} trace call updated"
      else
        puts "#### colony id #{colony.id} trace call NOT updated"
      end
    end
  end

  desc 'get the files for a particular mi_attempt'
  task 'get_files', [:mi_attempt_id] => :environment do |t, args|

    if args[:mi_attempt_id].blank?
      puts "#### supply mi_attempt_id!"
      exit
    end

    puts "#### getting mi_attempt_id: '#{args[:mi_attempt_id]}'"

    mi = MiAttempt.find args[:mi_attempt_id]

    colonies = mi.colonies

    folder = "#{Rails.root}/tmp/recovered_scfs"

    FileUtils.mkdir_p folder

    colonies.each do |colony|
      filename = "#{folder}/#{args[:mi_attempt_id]}__#{colony.name}.scf"
      puts "#### creating '#{filename}'"
      colony.trace_call.trace_file.copy_to_local_file('original', filename) unless colony.trace_call.nil?
    end
  end

end