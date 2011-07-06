# encoding: utf-8

class Kermits2::Migration

  EXCLUDE_LIST = %w{
    8615
    11072
    11061
    11060
    11036
    11066
    8682
    11086
    8610
    11116
    11089
    11077
    11418
    11051
    7899
    11035
    11044
    5403
    11063
    11115
    11032
    5437
    11085
    11065
    11030
    11058
    11047
    11087
    7531
    11039
    11038
    6459
    8619
    7916
    7544
    7562
    8667
    8666
    6334
    7855
    5890
    7884
    7875
    7854
    7951
    5544
    8681
    5912
    5578
    5447
    5615
    5609
    7644
    5584
    7898
    11289
    11782
    11820
    11812
    11821
    11822
    11830
    11823
    11832
    11836
    11834
    11844
    11850
    11981
    11986
    11982
    12318
    12344
    12400
    7955
    8618
    11076
    11080
    8625
    7731
    5271
    7688
    6451
    6437
    8640
    8659
    8643
    8635
    11088
    11042
    11098
    10352
    11037
    11101
    11040
    11033
    11102
    11064
    5580
    7378
    5614
    11814
    11815
    11826
    11835
    11839
    11838
    11837
    11846
    11848
    11859
    12670
    12316
    5227
    11057
    11056
    7917
    5934
    12807
    12832
  }.map!(&:to_i)

  class Error < RuntimeError; end

  def self.run(params = {})
    params.symbolize_keys!

    migrate_pipelines

    migrate_centres

    migrate_users

    migrate_clones(params)

    migrate_mi_attempts(params)
  end

  private

  def self.migrate_users
    Old::User.all.each do |old_user|
      User.create!(:email => old_user.email,
        :password => Digest::SHA1.hexdigest(rand(99999999999999999999999).to_s),
        :production_centre => Centre.find_by_name(old_user.centre.name))
    end
  end

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
        begin
          old_clone = Old::Clone.find_by_clone_name(non_mart_clone_name)
          allele_md = /<sup>(.+)<\/sup>/.match(old_clone.allele_name)
          clone = Clone.new(
            :clone_name => non_mart_clone_name,
            :marker_symbol => old_clone.gene_symbol,
            :pipeline => Pipeline.find_or_create_by_name(old_clone.pipeline.name)
          )
          if allele_md
            clone.allele_name_superscript = allele_md[1]
          end
          clone.save!
        rescue Exception => e
          e2 = Kermits2::Migration::Error.new("Caught exception #{e.class.name}: Error while fallback-DB-importing #{non_mart_clone_name}: #{e.message}")
          e2.set_backtrace(e.backtrace)
          raise e2
        end
      end
    end
  end

  def self.migrate_mi_attempts(params)
    mi_attempt_ids = params[:mi_attempt_ids]
    if mi_attempt_ids.nil?
      mi_attempt_ids = Old::MiAttempt.find_by_sql('select id from emi_attempt').map {|o| o.id.to_i }
    end
    @@mi_file = File.open("/tmp/list_of_mis_#{Time.now.strftime("%F-%T")}.txt", 'w')

    mi_attempt_ids.each do |mi_attempt_id|
      next if EXCLUDE_LIST.include?(mi_attempt_id)
      migrate_single_mi_attempt_by_id(mi_attempt_id)
    end
  end

  def self.migrate_single_mi_attempt_by_id(mi_attempt_id)
    begin
      old_mi_attempt = Old::MiAttempt.find(mi_attempt_id)

      @@mi_file.puts old_mi_attempt.id
      @@mi_file.flush

      clone = Clone.find_by_clone_name!(old_mi_attempt.clone_name)

      mi_attempt = MiAttempt.new(
        :production_centre => Centre.find_by_name!(old_mi_attempt.production_centre.name),
        :distribution_centre => Centre.find_by_name!(old_mi_attempt.distribution_centre.name),

        # Important details
        :colony_name => old_mi_attempt.colony_name,
        :mi_date => old_mi_attempt.actual_mi_date,

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
        :emma_status => old_mi_attempt.emma_status,
        :date_chimeras_mated => old_mi_attempt.date_chimera_mated,
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
        :number_of_live_glt_offspring => old_mi_attempt.number_live_glt_offspring,

        # QC fields
        :is_active => old_mi_attempt.is_active,
        :report_to_public => old_mi_attempt.is_public,
        :is_released_from_genotyping => old_mi_attempt.released_from_genotyping

        # Misc
      )

      # Important details (cont)
      mi_attempt.clone = clone

      if(old_mi_attempt.emi_event.edit_date.nil? or
                  old_mi_attempt.edit_date > old_mi_attempt.emi_event.edit_date)
        latest_object = old_mi_attempt
      else
        latest_object = old_mi_attempt.emi_event
      end
      mi_attempt.updated_at = latest_object.edit_date
      if(latest_object.edited_by.to_i == 26)
        mi_attempt.updated_by = User.find_by_email('vvi@sanger.ac.uk')
      else
        mi_attempt.updated_by = User.find_by_email(Old::User.find_by_user_name(latest_object.edited_by).email)
      end

      if old_mi_attempt.mi_attempt_status.name == 'Genotype Confirmed'
        mi_attempt.mi_attempt_status = MiAttemptStatus.genotype_confirmed
      end

      mi_attempt.deposited_material_name = case old_mi_attempt.material_deposited
      when 'frozen_embryos' then 'Frozen embryos'
      when 'live_mice' then 'Live mice'
      when 'frozen_sperm' then 'Frozen sperm'
      end

      # Transfer details (cont)
      mi_attempt.blast_strain_name = old_mi_attempt.blast_strain unless old_mi_attempt.blast_strain.blank?

      # Chimera mating details (cont)
      mi_attempt.test_cross_strain_name = old_mi_attempt.test_cross_strain unless old_mi_attempt.test_cross_strain.blank?
      mi_attempt.colony_background_strain_name = old_mi_attempt.back_cross_strain unless old_mi_attempt.back_cross_strain.blank?

      if ! old_mi_attempt.mouse_allele_name.blank?
        md = /\A[A-Za-z0-9]+<sup>tm\d([a-e])?\(\w+\)\w+<\/sup>\Z/.match(old_mi_attempt.mouse_allele_name)
        if ! md
          raise "Bad mouse allele name for #{old_mi_attempt.clone_name}: #{old_mi_attempt.mouse_allele_name}"
        end
        mi_attempt.mouse_allele_type = md[1]
      end

      # QC fields (cont)
      {
        :qc_southern_blot => :qc_southern_blot,
        :qc_five_prime_lr_pcr => :qc_five_prime_lr_pcr,
        :qc_five_prime_cassette_integrity => :qc_five_prime_cass_integrity,
        :qc_tv_backbone_assay => :qc_tv_backbone_assay,
        :qc_neo_count_qpcr => :qc_neo_count_qpcr,
        :qc_neo_sr_pcr => :qc_neo_sr_pcr,
        :qc_loa_qpcr => :qc_loa_qpcr,
        :qc_homozygous_loa_sr_pcr => :qc_homozygous_loa_sr_pcr,
        :qc_lacz_sr_pcr => :qc_lacz_sr_pcr,
        :qc_mutant_specific_sr_pcr => :qc_mutant_specific_sr_pcr,
        :qc_loxp_confirmation => :qc_loxp_confirmation,
        :qc_three_prime_lr_pcr => :qc_three_prime_lr_pcr
      }.each do |new_name, old_name|
        value = QcResult.find_by_description(old_mi_attempt.send(old_name))
        if ! value
          value = QcResult.find_by_description('na')
        end
        mi_attempt.send("#{new_name}=", value)
      end

      # Misc (cont)
      if ! old_mi_attempt.comments.blank?
        mi_attempt.comments = old_mi_attempt.comments
      end

      mi_attempt.save!
    rescue Exception => e
      e2 = Kermits2::Migration::Error.new("Caught exception #{e.class.name}: Error migrating emi_attempt(#{old_mi_attempt.id}) clone_name(#{old_mi_attempt.clone_name}): #{e.message}")
      e2.set_backtrace(e.backtrace)
      raise e2
    end
  end

end
