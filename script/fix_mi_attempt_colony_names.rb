#!/usr/bin/env ruby

DEBUG = false

# check if there are entries that would clash with our clean-up code

def get_duplicates
  duplicate_count_map = {}
  new_old_map = {}
  MiAttempt.all.each do |mi|

    colony_name = nil

    if ! mi.colony_name.nil?
      colony_name = mi.colony_name.to_s.strip! || mi.colony_name.to_s
      colony_name = colony_name.gsub(/\s+/, ' ')

      colony_name.downcase!

      duplicate_count_map[colony_name] ||= 0
      duplicate_count_map[colony_name] += 1

      new_old_map[colony_name] = mi.colony_name
    end

  end

  duplicate_array = []

  duplicate_count_map.keys.each do |key|
    if duplicate_count_map[key] > 1
      duplicate_array.push new_old_map[key]
    end
  end

  return duplicate_array
end

# get an array of colony names that need trimming or have multiple spaces

def get_tidy_candidates
  candidates_array = []
  MiAttempt.all.each do |mi|
    if mi.colony_name.to_s =~ /^\s+|\s+$|\s\s/
      candidates_array.push mi.colony_name
    end
  end
  return candidates_array
end

# do the actual tidy

def tidy_colony_names(candidates_array)
  MiAttempt.transaction do
    candidates_array.each do |candidate|
      mi = MiAttempt.find_by_colony_name!(candidate)

      colony_name = mi.colony_name.to_s.strip || mi.colony_name.to_s
      colony_name = colony_name.gsub(/\s+/, ' ')

      puts "Fixing mi_attempt #{mi.id} - '#{mi.colony_name}' >> '#{colony_name}'"

      mi.colony_name = colony_name
      mi.save! if ! DEBUG
    end
  end
end

################################################################################

puts "### DEBUG!!" if DEBUG
puts "Rails Environment: #{Rails.env}"

# if we get duplicate here then abort to be on safe side

duplicates = get_duplicates

raise "Following appear more than once with different spacing etc. #{duplicates}" if duplicates.length > 0

candidates = get_tidy_candidates

tidy_colony_names(candidates) if candidates.length > 0

puts "done!"

