#!/usr/bin/env ruby

{ruby19: true}

ip_status = MiAttemptStatus.micro_injection_in_progress
gc_status = MiAttemptStatus.genotype_confirmed
ab_status = MiAttemptStatus.micro_injection_aborted

MiAttempt.audited_transaction do
  MiAttempt.all.each do |mi|
    ips = mi.status_stamps.all.find_all {|ss| ss.mi_attempt_status == ip_status}
    gcs = mi.status_stamps.all.find_all {|ss| ss.mi_attempt_status == gc_status}
    abs = mi.status_stamps.all.find_all {|ss| ss.mi_attempt_status == ab_status}

    if ips.size > 1
      to_delete = ips[1..-1]
      puts "WARNING: #{'%0.6i' % mi.id} has multiple IP stamps: #{ips.map(&:created_at).map(&:iso8601)}; deleting: #{to_delete.map(&:created_at).map(&:iso8601)}"
    end

    if gcs.size > 1
      to_delete = gcs[1..-1]
      puts "WARNING: #{'%0.6i' % mi.id} has multiple GC stamps: #{gcs.map(&:created_at).map(&:iso8601)}; deleting: #{to_delete.map(&:created_at).map(&:iso8601)}"
    end

    if abs.size > 1
      to_delete = abs[1..-1]
      puts "WARNING: #{'%0.6i' % mi.id} has multiple AB stamps: #{abs.map(&:created_at).map(&:iso8601)}; deleting: #{to_delete.map(&:created_at).map(&:iso8601)}"
    end
  end
end
