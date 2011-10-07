#encoding: utf-8

namespace :one_time do

  desc 'Back-fill User Names'
  task :back_fill_user_names => :environment do
    {
      'a.mallon@har.mrc.ac.uk' => 'Ann-Marie Mallon',
      'abradley@sanger.ac.uk' => 'Alan Bradley',
      'aq2@sanger.ac.uk' => 'Asfand Qazi',
      'ayadi@igbmc.fr' => 'Abdel Ayadi',
      'bliu@bcm.edu' => 'Bin Liu',
      'brendan.doe@ibc.cnr.it' => 'Brendan Doe',
      'd.lynch@har.mrc.ac.uk' => 'Dee Lycnh',
      'dgm@sanger.ac.uk' => 'David Melvin',
      'do2@sanger.ac.uk' => 'Darren Oakley',
      'francesco.chiani@emma.cnr.it' => 'Francesco Chiani',
      'h.gates@har.mrc.ac.uk' => 'Hilary Gates',
      'htgt@sanger.ac.uk' => 'HTGT Data Loading Robot',
      'i.johnson@har.mrc.ac.uk' => '',
      'j.stevenson@har.mrc.ac.uk' => '',
      'j.vowles@har.mrc.ac.uk' => 'Jane Vowles',
      'jb27@sanger.ac.uk' => 'Joanna Bottomley',
      'jc3@sanger.ac.uk' => 'Jody Clements',
      'jdrapp@ucdavis.edu' => 'Jared Rapp',
      'jkw@sanger.ac.uk' => 'Jacqui White',
      'joel.schick@helmholtz-muenchen.de' => 'Joel Schick',
      'kps@sanger.ac.uk' => 'Karen Steel',
      'l.teboul@har.mrc.ac.uk' => 'Lydia Teboul',
      'lauryl.nutter@phenogenomics.ca' => 'Lauryl Nutter',
      'm.fray@har.mrc.ac.uk' => 'Martin Fray',
      'michael.hagn@gsf.de' => 'Michael Hagn',
      'mjustice@bcm.edu' => 'Monica Justice',
      'mng@sanger.ac.uk' => 'Mark Griffiths',
      'n.adams@har.mrc.ac.uk' => 'Niels Adams',
      'roland.friedel@helmholtz-muenchen.de' => 'Roland Friedel',
      'rrs@sanger.ac.uk' => 'Ramiro Ramirez-Solis',
      's.marschall@gsf.de' => 'Susan Marschall',
      's.wells@har.mrc.ac.uk' => 'Sara Wells',
      'selloum@igbmc.fr' => 'Mohammed Selloum',
      'skarnes@sanger.ac.uk' => 'Bill Skarnes',
      'vvi@sanger.ac.uk' => 'Vivek Iyer',
      'swakana@brc.riken.jp' => 'Shigeharu Wakana',
      'yobata@rtc.riken.go.jp' => 'Obata Yuichi',
      'hmasuya@brc.riken.jp' => 'Hiroshi Masuya',
      'dwest@chori.org' => 'David West',
      'steve.murray@jax.org' => 'Steve Murray',
      'adrienne.mckenzie@anu.edu.au' => 'Adrienne McKenzie'
    }.each do |email,name|
      user = User.find_by_email!(email)
      unless name.blank?
        user.name = name
        user.save!
      end
    end
  end

  desc 'Use imits audit trail to fill in missing MiAttempt and MiPlan status stamps'
  task :back_fill_status_stamps => :environment do
    ActiveRecord::Base.transaction do
      MiAttempt.all.each do |mi_attempt|
        first_revision = mi_attempt.audits[0].revision

        MiAttempt::StatusStamp.create!(:mi_attempt_status_id => first_revision.mi_attempt_status_id,
          :mi_attempt => mi_attempt, :created_at => first_revision.created_at)

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
          if mi.mi_date
            times.push mi.mi_date.to_time_in_current_zone
          end

          times.push mi.created_at
        end

        mi_plan.status_stamps.create!(:created_at => times.sort.first,
          :mi_plan_status => MiPlanStatus[:Assigned])
      end
    end
  end

end
