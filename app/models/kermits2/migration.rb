class Kermits2::Migration
  def self.run(params = {})
    params.symbolize_keys!

    migrate_pipelines

    migrate_centres

    migrate_clones(params)

    migrate_mi_attempts(params)
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

  def self.migrate_clones(params)
    query = Old::Clone.all_that_have_mi_attempts
    if params[:mi_attempt_ids]
      query = query.where(:emi_attempt => {:id => params[:mi_attempt_ids]})
    end
    old_clones = query.all
    clone_names = old_clones.collect(&:clone_name)

    if clone_names.empty?
      return []
    else
      clones = Clone.create_all_from_marts_by_clone_names(clone_names)
      new_clone_names = clones.map(&:clone_name)

      non_mart_clone_names = (Set.new(new_clone_names) ^ Set.new(clone_names)).to_a
      non_mart_clone_names.each do |non_mart_clone_name|
        old_clone = Old::Clone.find_by_clone_name(non_mart_clone_name)
        allele_md = /<sup>(.+)<\/sup>/.match(old_clone.allele_name)
        Clone.create!(
          :clone_name => non_mart_clone_name,
          :marker_symbol => old_clone.gene_symbol,
          :allele_name_superscript => (allele_md[1] if(allele_md)),
          :pipeline => Pipeline.find_or_create_by_name(old_clone.pipeline.name)
        )
      end
    end
  end

  def self.migrate_mi_attempts(params)
    mi_attempt_ids = params[:mi_attempt_ids]
    if mi_attempt_ids.nil?
      mi_attempt_ids = Old::MiAttempt.find_by_sql('select id from emi_attempt').map {|o| o.id.to_i }
    end

    mi_attempt_ids.each do |mi_attempt_id|
      migrate_single_mi_attempt_by_id(mi_attempt_id)
    end
  end

  def self.migrate_single_mi_attempt_by_id(mi_attempt_id)
    old_mi_attempt = Old::MiAttempt.find(mi_attempt_id)

    clone = Clone.find_by_clone_name!(old_mi_attempt.clone_name)

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

      # Chimera mating details
      :number_of_chimera_matings_attempted => old_mi_attempt.number_chimera_mated,
      :number_of_chimera_matings_successful => old_mi_attempt.number_chimera_mating_success,
      :number_of_chimeras_with_glt_from_cct => old_mi_attempt.chimeras_with_glt_from_cct,
      :number_of_chimeras_with_glt_from_genotyping => old_mi_attempt.chimeras_with_glt_from_genotyp,
      :number_of_chimeras_with_0_to_9_percent_glt => old_mi_attempt.number_lt_10_percent_glt,
      :number_of_chimeras_with_10_to_49_percent_glt => old_mi_attempt.number_btw_10_50_percent_glt,
      :number_of_chimeras_with_50_to_99_percent_glt => old_mi_attempt.number_gt_50_percent_glt,
      :number_of_chimeras_with_100_percent_glt => old_mi_attempt.number_100_percent_glt,
      :total_f1_mice_from_matings => old_mi_attempt.total_f1_mice,
      :number_of_cct_offspring => old_mi_attempt.number_with_cct,
      :number_of_het_offspring => old_mi_attempt.number_het_offspring,
      :number_of_live_glt_offspring => old_mi_attempt.number_live_glt_offspring
    )

    mi_attempt.save!
  end

end
