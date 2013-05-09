class QcGridReport

  def centre_by_consortia_by_gene
    ActiveRecord::Base.connection.execute(self.class.centre_by_consortia_by_gene_sql)
  end

  def get_mi_attempts
    ActiveRecord::Base.connection.execute(self.class.qc_grid_sql).to_a#.map{|r| QcGridReport::Row.new(r)}
  end

  def mi_attempts
    return @mi_attempts if @mi_attempts

    hash = {
      :consortia => {}
    }

    centre_by_consortia_by_gene.each do |cbcg|
      hash[:consortia][cbcg['consortium']]  ||= {}
      hash[:consortia][cbcg['consortium']][cbcg['production_centre']] ||= []
      hash[:consortia][cbcg['consortium']][cbcg['production_centre']] << cbcg['gene']
    end

    get_mi_attempts.each do |report_row|
      self.class.columns.each do |header|
        hash["#{report_row['consortium']}-#{report_row['production_centre']}-#{report_row['gene']}-#{header}"] = report_row[header]
      end
    end

    @mi_attempts = hash
  end

  def number_of_consortia
    mi_attempts[:consortia].keys.size
  end

  class << self

    def columns
      [
        "consortium",
        "production_centre",
        "gene",
        "colony_name",
        "qc_southern_blot_id",
        "qc_five_prime_lr_pcr_id",
        "qc_five_prime_cassette_integrity_id",
        "qc_tv_backbone_assay_id",
        "qc_neo_count_qpcr_id",
        "qc_neo_sr_pcr_id",
        "qc_loa_qpcr_id",
        "qc_homozygous_loa_sr_pcr_id",
        "qc_lacz_sr_pcr_id",
        "qc_mutant_specific_sr_pcr_id",
        "qc_loxp_confirmation_id",
        "qc_three_prime_lr_pcr_id",
        "user_qc_map_test",
        "user_qc_karyotype",
        "user_qc_tv_backbone_assay",
        "user_qc_loxp_confirmation",
        "user_qc_southern_blot",
        "user_qc_loss_of_wt_allele",
        "user_qc_neo_count_qpcr",
        "user_qc_lacz_sr_pcr",
        "user_qc_mutant_specific_sr_pcr",
        "user_qc_five_prime_cassette_integrity",
        "user_qc_neo_sr_pcr",
        "user_qc_five_prime_lr_pcr",
        "user_qc_three_prime_lr_pcr",
        "distribution_centre",
        "five_prime_sr_pcr",
        "three_prime_sr_pcr",
        "five_prime_lr_pcr",
        "three_prime_lr_pcr",
        "thawing",
        "loa",
        "loxp",
        "lacz",
        "chr1",
        "chr8a",
        "chr8b",
        "chr11a",
        "chr11b",
        "chry"
      ]
    end

    def csv_columns
      csv_columns = columns.dup

      csv_columns.delete_if {|v| v =~ /consortium|production_centre|gene/}

      csv_columns
    end

    def html_columns
      html_columns = columns.dup

      html_columns.delete_if {|v| v =~ /consortium|production_centre|gene|distribution_centre|colony_name/}

      html_columns
    end

    def descriptive_columns
      ["consortium", "production_centre", "gene"]
    end

    def distribution_qc_columns
      [
        'five_prime_sr_pcr',
        'three_prime_sr_pcr',
        'five_prime_lr_pcr',
        'three_prime_lr_pcr',
        'thawing',
        'loa',
        'loxp',
        'lacz',
        'chr1',
        'chr8a',
        'chr8b',
        'chr11a',
        'chr11b',
        'chry'
      ]
    end

    def qc_grid_sql
      <<-EOF
        SELECT
          consortia.name AS consortium,
          centres.name AS production_centre,
          genes.marker_symbol AS gene,
          mi_attempts.colony_name,
          mi_attempts.qc_southern_blot_id,
          mi_attempts.qc_five_prime_lr_pcr_id,
          mi_attempts.qc_five_prime_cassette_integrity_id,
          mi_attempts.qc_tv_backbone_assay_id,
          mi_attempts.qc_neo_count_qpcr_id,
          mi_attempts.qc_neo_sr_pcr_id,
          mi_attempts.qc_loa_qpcr_id,
          mi_attempts.qc_homozygous_loa_sr_pcr_id,
          mi_attempts.qc_lacz_sr_pcr_id,
          mi_attempts.qc_mutant_specific_sr_pcr_id,
          mi_attempts.qc_loxp_confirmation_id,
          mi_attempts.qc_three_prime_lr_pcr_id,
          targ_rep_es_cells.user_qc_map_test,
          targ_rep_es_cells.user_qc_karyotype,
          targ_rep_es_cells.user_qc_tv_backbone_assay,
          targ_rep_es_cells.user_qc_loxp_confirmation,
          targ_rep_es_cells.user_qc_southern_blot,
          targ_rep_es_cells.user_qc_loss_of_wt_allele,
          targ_rep_es_cells.user_qc_neo_count_qpcr,
          targ_rep_es_cells.user_qc_lacz_sr_pcr,
          targ_rep_es_cells.user_qc_mutant_specific_sr_pcr,
          targ_rep_es_cells.user_qc_five_prime_cassette_integrity,
          targ_rep_es_cells.user_qc_neo_sr_pcr,
          targ_rep_es_cells.user_qc_five_prime_lr_pcr,
          targ_rep_es_cells.user_qc_three_prime_lr_pcr,
          targ_rep_es_cell_distribution_centres.name AS distribution_centre,
          targ_rep_distribution_qcs.five_prime_sr_pcr,
          targ_rep_distribution_qcs.three_prime_sr_pcr,
          targ_rep_distribution_qcs.five_prime_lr_pcr,
          targ_rep_distribution_qcs.three_prime_lr_pcr,
          targ_rep_distribution_qcs.thawing,
          targ_rep_distribution_qcs.loa,
          targ_rep_distribution_qcs.loxp,
          targ_rep_distribution_qcs.lacz,
          targ_rep_distribution_qcs.chr1,
          targ_rep_distribution_qcs.chr8a,
          targ_rep_distribution_qcs.chr8b,
          targ_rep_distribution_qcs.chr11a,
          targ_rep_distribution_qcs.chr11b,
          targ_rep_distribution_qcs.chry

        FROM mi_attempts
        JOIN mi_plans ON mi_attempts.mi_plan_id = mi_plans.id
        JOIN centres   ON centres.id = mi_plans.production_centre_id
        JOIN consortia ON consortia.id = mi_plans.consortium_id
        JOIN genes    ON genes.id = mi_plans.gene_id
        JOIN targ_rep_es_cells ON targ_rep_es_cells.id = mi_attempts.es_cell_id
        JOIN mi_attempt_statuses ON mi_attempts.status_id = mi_attempt_statuses.id

        LEFT JOIN targ_rep_distribution_qcs ON targ_rep_distribution_qcs.es_cell_id = targ_rep_es_cells.id
        LEFT JOIN targ_rep_es_cell_distribution_centres ON targ_rep_es_cell_distribution_centres.id = targ_rep_distribution_qcs.es_cell_distribution_centre_id

        WHERE
          mi_attempt_statuses.code = 'gtc'

        ORDER BY
          consortia.name ASC,
          centres.name ASC

        --LIMIT 4
      EOF

    end

    def centre_by_consortia_by_gene_sql
      <<-EOF
        SELECT
          consortia.name AS consortium,
          centres.name AS production_centre,
          genes.marker_symbol AS gene

        FROM mi_attempts
        JOIN mi_plans ON mi_attempts.mi_plan_id = mi_plans.id
        JOIN centres   ON centres.id = mi_plans.production_centre_id
        JOIN consortia ON consortia.id = mi_plans.consortium_id
        JOIN genes    ON genes.id = mi_plans.gene_id
        JOIN targ_rep_es_cells ON targ_rep_es_cells.id = mi_attempts.es_cell_id
        JOIN mi_attempt_statuses ON mi_attempts.status_id = mi_attempt_statuses.id

        LEFT JOIN targ_rep_distribution_qcs ON targ_rep_distribution_qcs.es_cell_id = targ_rep_es_cells.id
        LEFT JOIN targ_rep_es_cell_distribution_centres ON targ_rep_es_cell_distribution_centres.id = targ_rep_distribution_qcs.es_cell_distribution_centre_id

        WHERE
          mi_attempt_statuses.code = 'gtc'

        GROUP BY
          consortium,
          production_centre,
          gene

        ORDER BY
          consortia.name ASC,
          centres.name ASC
      EOF
    end
  end
end