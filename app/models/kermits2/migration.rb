class Kermits2::Migration
  def self.run(params)
    params.symbolize_keys!

    migrate_pipelines

    migrate_centres

    migrate_mi_attempts_and_their_clones(params)
  end

  private

  def self.migrate_pipelines
    Old::Pipeline.all.each do |old_pipeline|
      Pipeline.create!(:name => old_pipeline.name,
        :description => old_pipeline.description)
    end
  end

  def self.migrate_centres
    Old::Centre.all.each do |old_centre|
      Centre.create!(:name => old_centre.name)
    end
  end

  def self.migrate_mi_attempts_and_their_clones(params)
    mi_attempt_ids = params[:mi_attempt_ids]

    mi_attempt_ids.each do |mi_attempt_id|
      old_mi_attempt = Old::MiAttempt.find(mi_attempt_id)

      clone = Clone.find_by_clone_name(old_mi_attempt.clone_name)
      if ! clone
	clone = Clone.update_or_create_from_marts_by_clone_name(
          old_mi_attempt.clone_name)
      end

      mi_attempt = MiAttempt.new(
        :clone => clone,
        :production_centre => Centre.find_by_name!(old_mi_attempt.production_centre.name),
        :distribution_centre => Centre.find_by_name!(old_mi_attempt.distribution_centre.name),

        # Transfer details
        :total_blasts_injected => old_mi_attempt.num_blasts,
        :total_transferred => old_mi_attempt.num_transferred,
        :number_surrogates_receiving => old_mi_attempt.num_recipients,

        # Litter details
        :total_pups_born => old_mi_attempt.number_born,
        :total_female_chimeras => old_mi_attempt.number_female_chimeras,
        :total_male_chimeras => old_mi_attempt.number_male_chimeras,
        :number_of_males_with_0_to_39_percent_chimerism => old_mi_attempt.number_male_lt_40_percent,
        :number_of_males_with_40_to_79_percent_chimerism => old_mi_attempt.number_male_40_to_80_percent,
        :number_of_males_with_80_to_99_percent_chimerism => old_mi_attempt.number_male_gt_80_percent,
        :number_of_males_with_100_percent_chimerism => old_mi_attempt.number_male_100_percent,
      )

      mi_attempt.save!
    end
  end

end
