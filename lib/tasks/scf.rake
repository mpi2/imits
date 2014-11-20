
namespace :scf do

  desc 'run the scf process'
  task 'run', [:force] => :environment do |t, args|
    args.with_defaults(:force => false)
    options = {}
    options = { :force => true } if ! args[:force].blank?

    Colony.all.each do |colony|
      colony.crispr_damage_analysis options
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
      colony.crispr_damage_analysis options
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
      colony.trace_file.copy_to_local_file('original', filename)
    end
  end

end