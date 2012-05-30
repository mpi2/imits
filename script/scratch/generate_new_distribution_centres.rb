@saved_mi_attempts = Array.new
mi_attempts = MiAttempt.all
mi_attempts.each do |this_mi_attempt|
  if this_mi_attempt.status == 'Genotype confirmed'
    MiAttempt.audited_transaction do
      Audit.as_user(User.find_by_email!("gj2@sanger.ac.uk")) do
        new_distribution_centre = MiAttempt::DistributionCentre.new

          this_centre = Centre.find(this_mi_attempt.distribution_centre_id)
          if this_centre
            this_deposited_material = DepositedMaterial.find(this_mi_attempt.deposited_material_id)
            if this_deposited_material
              new_distribution_centre.centre = this_centre
              new_distribution_centre.deposited_material = this_deposited_material
              new_distribution_centre.is_distributed_by_emma = this_mi_attempt.is_suitable_for_emma
              this_mi_attempt.distribution_centres.push(new_distribution_centre)
              if this_mi_attempt.valid?
                if this_mi_attempt.save!
                  Rails.logger.info ">>>> #{this_mi_attempt.id} Successfully saved."
                  @saved_mi_attempts.push(this_mi_attempt)
                else
                  Rails.logger.info "#{this_mi_attempt.id} Unable to save update mi_attempt #{this_mi_attempt.inspect}"
                end
              else
                Rails.logger.info "#{this_mi_attempt.id} Mi attempt not valid"
              end
            else
              Rails.logger.info "#{this_mi_attempt.id} Unable to find Deposited Material with id #{this_mi_attempt.deposited_material_id}"
            end
          else
            Rails.logger.info "#{this_mi_attempt.id} Unable to find Centre with id #{this_mi_attempt.distribution_centre_id}"
          end
      end
    end
  end
end

puts "Number of saved mi_attempts #{@saved_mi_attempts.length}"
