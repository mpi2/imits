#!/usr/bin/env ruby

ApplicationModel.audited_transaction do
  [MiPlan, MiAttempt, PhenotypeAttempt].each do |model_class|
    model_class.all.each do |obj|
      ss_before = obj.status_stamps.map {|ss| ss.code + '[' + ss.created_at.strftime('%F') + ']'}.join(', ')
      obj.save!
      ss_after = obj.status_stamps.map {|ss| ss.code + '[' + ss.created_at.strftime('%F') + ']'}.join(', ')

      if ss_before != ss_after
        puts "#{obj.class.name}(#{obj.id}):"
        puts "  Status: #{obj.status.code}"
        puts "  New stamps: #{ss_after}"
      end
    end
    puts
  end

  raise 'ROLLBACK'
end
