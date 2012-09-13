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

exit

################################################################################
#
##raise "Following need trimming etc. #{candidates}" if candidates.length > 0
#
#MiAttempt.all.each do |mi|
#  if mi.colony_name.to_s =~ /^\s+|\s+$|\s\s/
#    puts "Needs trim: '#{mi.colony_name}'"
#  end
#end
#
##array = ['mirKO_ES_PuDtk_10E1', 'mirKO_ES_PuDtk_10H10', 'mirKO_ES_PuDtk_5H10']
##
##MiAttempt.all.each do |mi|
##  array.each do |htgt|
##    if mi.colony_name.to_s.downcase == htgt.downcase
##      puts "HTGT: '#{htgt}' - iMits: '#{mi.colony_name} - same: #{mi.colony_name == htgt}'"
##    end
##  end
##end
##
##array.each do |htgt|
##  mi_attempt = MiAttempt.find_by_colony_name(htgt)
##  puts "#### cannot find '#{htgt}'" if ! mi_attempt
##end
#
#exit
#
#################################################################################
#
#map = {}
#found = false
#
#MiAttempt.transaction do
#
#  MiAttempt.all.each do |mi|
#
#    colony_name = nil
#
#    if ! mi.colony_name.nil?
#      colony_name = mi.colony_name.to_s.strip! || mi.colony_name.to_s
##      next if ! colony_name
#      colony_name = colony_name.gsub(/\s+/, ' ')
#
#      #colony_name.downcase!
#
#      map[colony_name] ||= 0
#      map[colony_name] += 1
#    end
#
#  end
#
#  map.keys.each do |key|
#    if map[key] > 1
#      puts "#{key}: #{map[key]}"
#      found = true
#    end
#  end
#
#
##### cannot find
##### cannot find
##### cannot find
#
#  array = ['mirKO_ES_PuDtk_10E1', 'mirKO_ES_PuDtk_10H10', 'mirKO_ES_PuDtk_5H10']
#
#  map.keys.each do |key|
#    array.each do |htgt|
#      if key.downcase == htgt.downcase
#        puts "HTGT: '#{htgt}' - iMits: '#{key}' - same: #{key == htgt}"
#      end
#    end
#  end
#
#
#
#
#  raise "rollback!" if found
#
#end
#
#puts "done!"