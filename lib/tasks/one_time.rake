#encoding: utf-8

namespace :one_time do

  desc 'fix_back_filled_status_stamps'
  task :fix_back_filled_status_stamps => :environment do
    ActiveRecord::Base.transaction do
      MiAttempt.search(:created_at_lt => '2011-10-10T10:30:00+0100').result.each do |mi_attempt|
        mi_date = mi_attempt.mi_date.to_time_in_current_zone
        time_to_set = [mi_attempt.created_at, mi_date].min
        stamp = mi_attempt.status_stamps.first
        stamp.update_attributes!(:created_at => time_to_set)
      end
    end
  end

end
