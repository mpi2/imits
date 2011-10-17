#encoding: utf-8

namespace :one_time do

  desc 'Use imits audit trail to fill in missing MiAttempt and MiPlan status stamps'
  task :fix_back_filled_status_stamps => :environment do
    ActiveRecord::Base.transaction do
      MiAttempt.search(:created_at_lt => '2011-10-10T10:30:00+0100').result.each do |mi_attempt|
        stamp = mi_attempt.status_stamps.first
        stamp.update_attributes!(:created_at => mi_attempt.mi_date)
      end
    end
  end

end
