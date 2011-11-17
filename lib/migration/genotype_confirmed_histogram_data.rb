# encoding: utf-8

mi_delta_data = []

MiAttempt.where(:mi_attempt_status_id => MiAttemptStatus.genotype_confirmed.id).order('id asc').each do |mi|
  next if mi.mi_date.to_time < 24.months.ago

  ip = mi.status_stamps.detect {|ss| ss.mi_attempt_status == MiAttemptStatus.micro_injection_in_progress}

  if ! ip
    STDERR.puts "Skipping #{mi.colony_name}(#{mi.id}), no Micro-injection in progress date"
    next
  end

  gc = mi.status_stamps.detect {|ss| ss.mi_attempt_status == MiAttemptStatus.genotype_confirmed}

  ip = ip.created_at
  gc = gc.created_at

  delta = ((gc - ip)/3600/24/30 + 0.5).to_i

  mi_delta_data[delta] ||= []
  mi_delta_data[delta] << mi
end

mi_delta_data.map! {|i| i || [] }

CSV.open('histogram_data.csv', 'wb') do |csv|
  csv << ['months_delta', 'number']
  mi_delta_data.each_with_index do |mis, months_delta|
    csv << [months_delta, mis.size]
  end
end

CSV.open('mi_delta_data.csv', 'wb') do |csv|
  csv << ['colony_name', 'mi_date', 'months_delta']
  mi_delta_data.each_with_index do |mis, months_delta|
    mis.each do |mi|
      csv << [mi.colony_name, mi.mi_date, months_delta]
    end
  end
end
