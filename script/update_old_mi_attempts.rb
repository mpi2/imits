#!/usr/bin/env ruby

# to run standalone, be in imits directory and run command:
# $ script/runner script/update_old_mi_attempts.rb

require 'pp'

class UpdateOldMiAttempts

  ##
  # This class checks all MI Attempts with status 'Chimeras obtained' and sets any that are older than a year to
  # is_active = false which will change them to status aborted.
  ##

  ##
  ## Any initialization before running checks
  ##
  def initialize

    @sql_select_old_mi_attempts = "select mi_attempts.id from mi_attempts "\
      "join mi_attempt_statuses on mi_attempt_statuses.id = mi_attempts.status_id "\
      "join mi_attempt_status_stamps on mi_attempt_status_stamps.mi_attempt_id = mi_attempts.id "\
      "AND mi_attempt_status_stamps.status_id = mi_attempts.status_id "\
      "where mi_attempt_statuses.name = 'Chimeras obtained' "\
      "and mi_attempt_status_stamps.updated_at < now() - interval '1 year' "\
      "order by mi_attempt_status_stamps.updated_at;"

    @count_mi_rows_checked     = 0
    @count_mi_rows_missing_id  = 0
    @count_successful_mi_saves = 0
    @count_failed_mi_saves     = 0

  end

  ##
  ## Find any old Mi Attempts in status Chimeras obtained that haven't been updated in a year
  ##
  def check_mi_attempts

    # select all old Mi Attempts
    results = ActiveRecord::Base.connection.execute(@sql_select_old_mi_attempts)

    # process each mi attempt
    results.each do |row|
      @count_mi_rows_checked += 1

      if ( row['id'].nil? )
        @count_mi_rows_missing_id += 1
        next
      end

      mi_id = row['id']

      # fetch the mi with this id
      mi = MiAttempt.find_by_id(mi_id)

      # try to set the mi to is_active = false which will update Mi status to 'Micro-injection aborted'
      begin
        # puts "Setting Mi Attempt id = #{mi_id} to inactive"
        mi.is_active = false
        mi.save!
        @count_successful_mi_saves += 1
      rescue => e
        puts "ERROR : failed to save Mi Attempt with id #{mi_id} to inactive"
        puts "ERROR : exception : #{e.message}"
        @count_failed_mi_saves += 1
      end
    end
  end

  ##
  ## Display results of processing
  ##
  def display_results

    puts "----------------------------------------"
    puts "Updating old Mi Attempts to inactive"
    puts "----------------------------------------"
    puts "Mi Attempts with old states = #{@count_mi_rows_checked}"

    if @count_mi_rows_checked > 0
      puts "Successful Mi saves         = #{@count_successful_mi_saves}"
      puts "Failed Mi saves             = #{@count_failed_mi_saves}"
      puts "Rows missing Mi id          = #{@count_mi_rows_missing_id}"
    else
      puts "No updates required"
    end

    puts "----------------------------------------"

  end

  def run
    check_mi_attempts

    display_results
  end

end

if __FILE__ == $0
  # this will only run if the script was the main, not load'd or require'd
  UpdateOldMiAttempts.new.run
end