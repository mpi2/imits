#!/usr/bin/env ruby

ApplicationModel.audited_transaction do
  all_before = {}

  [MiPlan, MiAttempt, PhenotypeAttempt].each do |model_class|
    before = all_before[model_class] = {}
    model_class.all.each do |obj|
      before[obj.id] = obj.status_stamps.map {|ss| ss.code + '[' + ss.created_at.strftime('%F') + ']'}.join(', ')
    end
  end

  [MiPlan, MiAttempt, PhenotypeAttempt].each do |model_class|
    before = all_before[model_class]
    model_class.all.each do |obj|
      obj.save!
      after = obj.status_stamps.map {|ss| ss.code + '[' + ss.created_at.strftime('%F') + ']'}.join(', ')
      if before[obj.id] != after
        puts "#{obj.class.name}(#{obj.id}):"
        puts "  Status: #{obj.status.code}"
        puts "  New stamps: #{after}"
      end
    end
    puts
  end

  raise 'ROLLBACK'
end
