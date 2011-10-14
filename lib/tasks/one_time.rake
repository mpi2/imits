#encoding: utf-8

namespace :one_time do

  desc 'Use imits audit trail to fill in missing MiAttempt and MiPlan status stamps'
  task :back_fill_status_stamps => :environment do
    ActiveRecord::Base.transaction do
      MiAttempt.all.each do |mi_attempt|
        first_revision = mi_attempt.audits[0].revision

        MiAttempt::StatusStamp.create!(:mi_attempt_status_id => first_revision.mi_attempt_status_id,
          :mi_attempt => mi_attempt, :created_at => first_revision.mi_date)

        previous_old_revision = first_revision

        mi_attempt.audits[1..-1].each do |audit|
          old_revision = audit.revision
          if previous_old_revision.mi_attempt_status_id != old_revision.mi_attempt_status_id
            MiAttempt::StatusStamp.create!(:mi_attempt_status_id => old_revision.mi_attempt_status_id,
              :mi_attempt => mi_attempt, :created_at => old_revision.created_at)
          end
          previous_old_revision = old_revision
        end
      end

      MiPlan.all.each do |mi_plan|
        times = []

        mi_plan.mi_attempts.each do |mi|
          times.push mi.mi_date.to_time_in_current_zone
          times.push mi.created_at
        end

        mi_plan.status_stamps.create!(:created_at => times.sort.first,
          :mi_plan_status => MiPlanStatus[:Assigned])
      end
    end
  end

end
