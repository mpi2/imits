#!/usr/bin/env ruby

def delete_stamp_duplicates(obj)
  log = []
  grouped = obj.status_stamps.group_by(&:code)
  grouped.each do |code, stamps|
    if stamps.size != 1
      stamps = stamps.sort_by(&:created_at)
      keeper = stamps.shift
      logline = "#{code.rjust(7)}: KEEP(#{keeper.created_at.strftime('%F')}) DELETE(#{stamps.map {|i| i.created_at.strftime('%F')}.join(', ')})"
      log << logline
      stamps.each(&:destroy)
    end
  end
  return log
end

ApplicationModel.audited_transaction do
  [MiPlan, MiAttempt, PhenotypeAttempt].each do |model_class|
    model_class.all.each do |obj|
      log = delete_stamp_duplicates(obj)
      obj.reload

      if ! log.blank?
        puts "#{obj.class.name}(#{obj.id}):"
        puts "  Status: #{obj.status.code}"
        puts "  Deletions:"
        puts log.map {|i| i.rjust(2)}
        puts "  New stamps: #{obj.status_stamps.map {|ss| ss.code + '[' + ss.created_at.strftime('%F') + ']'}.join(', ')}"
      end
    end
    puts
  end

  raise 'ROLLBACK'
end
