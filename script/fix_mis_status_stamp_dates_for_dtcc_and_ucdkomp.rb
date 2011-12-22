#!/usr/bin/env ruby

def mi_with_stamps(mi)
  ss_out = "{" + mi.status_stamps.map {|ss| "#{ss.mi_attempt_status.id}: #{ss.created_at.utc.to_date.to_s}"}.join(', ') + "}"
  return "#{mi.colony_name} : #{ss_out}"
end

MiAttempt.transaction do

  ip_status = MiAttemptStatus.micro_injection_in_progress
  mis = MiAttempt.search(:mi_plan_consortium_name_in => ['DTCC', 'UCD-KOMP'],
    :sorts => 'colony_name').result

  before, after = nil, nil

  CSV.open('tmp/fix_mis_status_stamp_dates_for_dtcc_and_ucdkomp_result.csv', 'wb') do |csv|
    csv << ['before', 'after']

    mis.each do |mi|
      before = mi_with_stamps(mi)

      ip_stamps = mi.status_stamps.select {|ss| ss.mi_attempt_status_id == ip_status.id}
      if ip_stamps.blank?
        mi.status_stamps.create!(:mi_attempt_status => ip_status, :created_at =>
                  mi.mi_date.to_time(:utc))
      else
        ip = ip_stamps.last
        ip.created_at = mi.mi_date.to_time(:utc); ip.save!
      end

      mi.reload
      after = mi_with_stamps(mi)

      csv << [before, after]
    end
  end
end
