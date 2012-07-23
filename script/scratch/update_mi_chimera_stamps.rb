
class AuditStore
  attr_accessor :total_male_chimeras, :mi_attempt_id
  attr_accessor :earliest_genotype_date, :earliest_mi_date, :earliest_chimeras_date
  attr_accessor :chimeras_obtained_status
  
  def initialize
    self.chimeras_obtained_status = false
    self.earliest_genotype_date = Time.now
    self.earliest_mi_date = Time.now
    self.earliest_chimeras_date = Time.now
  end
  
  def check_dates(mi_attempt_audit, switch)
    case switch
    when "genotype"
      if self.earliest_genotype_date && (self.earliest_genotype_date.to_date > mi_attempt_audit.created_at.to_date)
        self.earliest_genotype_date = mi_attempt_audit.created_at
      end
    when "mi"
      if self.earliest_mi_date && (self.earliest_mi_date.to_date > mi_attempt_audit.created_at.to_date)
        self.earliest_mi_date = mi_attempt_audit.created_at
      end
      
    when "chimeras"
      if self.earliest_chimeras_date && (self.earliest_chimeras_date.to_date > mi_attempt_audit.created_at.to_date)
        self.earliest_chimeras_date = mi_attempt_audit.created_at
      end
      
    end
    
  end
end

def genotyping_check(het_offspring, glt_chimeras, is_active)
  if het_offspring.to_i != 0 && glt_chimeras.to_i != 0 && is_active
    return true
  else
    return false
  end
  
end

def chimera_check(male_chimeras, is_active)
  if male_chimeras.to_i != 0 && is_active
    return true
  else
    return false
  end
  
end
  
@mi_attempts = MiAttempt.all
#@mi_attempts = MiAttempt.find(:all, :conditions => ["distribution_centre_id = ?", 2])
@storage = Hash.new

@genotype_complete_status = MiAttempt::Status.find_by_description('Genotype confirmed')
@micro_injection_status = MiAttempt::Status.find_by_description('Micro-injection in progress')
@micro_injection_aborted_status = MiAttempt::Status.find_by_description('Micro-injection aborted')

@audit_log = File.open("tmp/audit_log.txt", "w")
mi_attempts_start_time = Time.now

@mi_attempts.each do |this_mia|
  
  @this_audit_store = AuditStore.new
  @default_chimeras_date = @this_audit_store.earliest_chimeras_date
  
  @this_audit_store.mi_attempt_id = this_mia.id
  genotype_stamp = this_mia.status_stamps.find_by_mi_attempt_status_id(@genotype_complete_status.id)
  micro_injection_stamp  = this_mia.status_stamps.find_by_mi_attempt_status_id(@micro_injection_status.id)
  micro_injection_aborted_stamp  = this_mia.status_stamps.find_by_mi_attempt_status_id(@micro_injection_aborted_status.id)
  
  if genotype_stamp
    @this_audit_store.earliest_genotype_date = genotype_stamp.created_at
  end
  if micro_injection_stamp
    @this_audit_store.earliest_mi_date = micro_injection_stamp.created_at
  end
  
    if this_mia.audits
      
      @audit_log.puts "#{this_mia.id} :: MI_ATTEMPT #{this_mia.id} has #{this_mia.audits.length} audit records."
      this_mia.audits.each do |this_audit|
        this_mia_revision = this_audit.revision
        if this_mia_revision.status != "Micro-injection aborted"
          if this_mia_revision.status == "Micro-injection in progress"
            @this_audit_store.check_dates(this_audit, "mi")
          end
          if genotyping_check(this_mia_revision.number_of_het_offspring, this_mia_revision.number_of_chimeras_with_glt_from_genotyping, this_mia_revision.is_active)
            @audit_log.puts "    mia_attempt #{this_mia.id} audit #{this_audit.id} #{this_audit.created_at} meets genotype confirmed criteria"
            @this_audit_store.check_dates(this_audit, "genotype")
            
            if this_mia_revision.status == "Genotype confirmed"
              @audit_log.puts "    mia_attempt #{this_mia.id} audit #{this_audit.id} #{this_audit.created_at} has genotype confirmed status"
              @this_audit_store.check_dates(this_audit, "genotype")
            end
            
          elsif chimera_check(this_mia_revision.total_male_chimeras, this_mia_revision.is_active)
            @audit_log.puts "    mia_attempt #{this_mia.id} audit #{this_audit.id} #{this_audit.created_at} meets chimeras obtained criteria and not genotype confirmed criteria"
            @this_audit_store.check_dates(this_audit, "chimeras")
            @this_audit_store.chimeras_obtained_status = true
          else
            @audit_log.puts "    mia_attempt #{this_mia.id} audit #{this_audit.id} #{this_audit.created_at} status #{this_mia_revision.status}"
          end
        end
      end
      
    end #if this_mia.audits
  
    # final catch just in case record does meet chimeras obtained criteria
    # but the audit_store chimeras date hasn't been updated
    if @this_audit_store.earliest_chimeras_date == @default_chiemras_date
      if chimeras_check(this_mia.total_male_chimeras, this_mia.is_active)
        if @this_audit_store.earliest_mi_date
          @this_audit_store.earliest_chimeras_date = @this_audit_store.earliest_mi_date
        elsif @this_audit_store.earliest_genotype_date
          @this_audit_store.earliest_chimeras_date = @this_audit_store.earliest_genotype_date
        else
          @this_audit_store.earliest_chimeras_date = Date.today
        end
      end
    end  
    
    
    @storage[this_mia.id] = @this_audit_store
end
mi_attempts_end_time = Time.now

@parsing_time_taken = mi_attempts_end_time - mi_attempts_start_time

puts "#{@storage.length} stamps in storage, from #{@mi_attempts.length} mi_attempts."
puts "Job started at #{mi_attempts_start_time}"
puts "Audits done at #{mi_attempts_end_time}"
puts "Start saving new Chimeras obtained stamps? (y/n)"
input = gets.chomp.downcase

if (input == 'y')
  puts "Creating stamps"
  @chimera_status = MiAttempt::Status.find_by_description('Chimeras obtained')
  @successful_save = 0
  
  if @chimera_status
    @storage.each_pair do |this_key, this_store|
      if this_store.chimeras_obtained_status == true
        this_stamp = MiAttempt::StatusStamp.new
        this_stamp.mi_attempt_status = @chimera_status
        this_stamp.mi_attempt_id = this_store.mi_attempt_id
        this_stamp.created_at = this_store.earliest_chimeras_date
        this_stamp.updated_at = this_store.earliest_chimeras_date
        
        if this_stamp.valid?
          if this_stamp.save!
            @audit_log.puts "#{this_stamp.inspect}"
            @successful_save += 1
          end
        end
        this_mi_attempt = MiAttempt.find(this_store.mi_attempt_id)
        if this_mi_attempt.status != "Genotype confirmed"
          this_mi_attempt.change_status
          if this_mi_attempt.valid?
            this_mi_attempt.save!
          end
        end
      end
    
    end
  else
    puts "Chimera obtained MI Attempt status not found : check that the MiAttempt::Status is available"
  end
  
  puts "Stamps finished"
  puts "#{@mi_attempts.length} MiAttempts available."
  puts "#{@storage.length} records in storage :: #{@successful_save} stamps created"
elsif (input == 'n')
  @audit_log.puts @storage.to_json
  puts "Exiting without saving stamps : storage object written to the log" 
else
  @audit_log.puts @storage.to_json
  puts "Command not recognised, exiting without saving : storage object written to the log"
end


@audit_log.close
