#!/usr/bin/env ruby

#default to MIAttempt.colony_background_strain for those cases where cre excision is already complete.

#ticket #9003

DEBUG = false
CHECK = false

puts "Environment: #{Rails.env}"
puts "DEBUG!!" if DEBUG
puts "CHECK!!" if CHECK

PhenotypeAttempt.transaction do

  if CHECK
    missing = []
    PhenotypeAttempt.all.each do |pa|
      if PhenotypeAttempt::Status.post_cre_excision_complete.include?(pa.status) &&
        pa.mi_attempt.colony_background_strain_name.blank?
        missing.push pa.id
      end
    end

    raise "Found following PAs without defaultable colony_background_strain_name #{missing.inspect}" if missing.size > 0
  end

  count = 0
  PhenotypeAttempt.all.each do |pa|
    if PhenotypeAttempt::Status.post_cre_excision_complete.include?(pa.status)

      next if pa.mi_attempt.colony_background_strain_name.blank?
      next if ! pa.colony_background_strain.blank?

      puts "PA: #{pa.id}: '#{pa.colony_background_strain}': defaulting to '#{pa.mi_attempt.colony_background_strain_name}'"
      pa.colony_background_strain = pa.mi_attempt.colony_background_strain
      pa.save! if ! DEBUG
      count += 1
    end
  end

  puts "COUNT: #{count}"

  raise "rollback!" if DEBUG

  puts "done!"
end
