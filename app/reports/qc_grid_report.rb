class QcGridReport

  class Row

    attr_accessor :data, :insertion_score, :threep_loxp_score, :targeting_score, :cassette_score

    def initialize(data)
      @data = data
      data['insertion_score'] = insertion_score
      data['threep_loxp_score'] = threep_loxp_score
      data['targeting_score'] = targeting_score
      data['cassette_score'] = cassette_score
    end

    def insertion_score
      if qc_southern_blot == 'pass'
        4
      elsif qc_neo_count_qpcr == 'pass' && qc_tv_backbone_assay == 'pass'
        3
      elsif qc_tv_backbone_assay == 'pass'
        2
      else
        1
      end
    end

    def threep_loxp_score
      return nil if mutation_type == 'Deletion'
      if qc_loxp_confirmation == 'pass'
        3
      else
        1
      end
    end

    def cassette_score
      if qc_southern_blot == 'pass'
        5
      elsif qc_neo_count_qpcr == 'pass'
        3
      elsif qc_lacz_sr_pcr == 'pass'
        2
      else
        1
      end
    end

    def targeting_score
      if qc_southern_blot == 'pass'
        6
      elsif qc_loa_qpcr == 'pass' || qc_homozygous_loa_sr_pcr == 'pass'
        5
      elsif qc_five_prime_lr_pcr == 'pass' && qc_three_prime_lr_pcr == 'pass' && qc_mutant_specific_sr_pcr == 'pass'
        4
      elsif qc_five_prime_lr_pcr == 'pass' && qc_three_prime_lr_pcr == 'pass'
        3
      elsif qc_five_prime_lr_pcr == 'pass' || qc_three_prime_lr_pcr == 'pass'
        2
      else
        1
      end
    end

    ## Override method_missing and respond_to? to access the hash as you would a object attribute.
    def method_missing(method_sym, *arguments, &block)
      if value = data[method_sym.to_s]
        value
      else
        super
      end
    end

    def respond_to?(method_sym, include_private = false)
      if data[method_sym.to_s]
        true
      else
        super
      end
    end
  end #QcReport::Row

  class Summary

    def initialize
    end

    def centre_by_consortia
      sql = <<-EOF
        SELECT
          consortia.name AS consortium,
          centres.name AS production_centre

        FROM mi_attempts
        JOIN plans ON mi_attempts.plan_id = plans.id AND plans.mutagenesis_via_crispr_cas9 = false
        JOIN centres   ON centres.id = plans.production_centre_id
        JOIN consortia ON consortia.id = plans.consortium_id
        JOIN mi_attempt_statuses ON mi_attempts.status_id = mi_attempt_statuses.id

        WHERE
          mi_attempt_statuses.code = 'gtc'

        GROUP BY
          consortium,
          production_centre

        ORDER BY
          consortia.name ASC,
          centres.name ASC

        --LIMIT 4
      EOF

      result = ActiveRecord::Base.connection.execute(sql)

      consortia = {}

      result.each do |row|

        consortium = row['consortium']
        production_centre = row['production_centre']

        if consortia[consortium]
          if !consortia[consortium].include?(production_centre)
            consortia[consortium] << production_centre
          end
        else
          consortia[consortium] = [production_centre]
        end

      end

      consortia
    end


    def generate_report
      full_report = QcGridReport.new.run.report_rows

      hash = {}

      full_report.each do |report_row|
        if hash["#{report_row.consortium}-#{report_row.production_centre}"]
          hash["#{report_row.consortium}-#{report_row.production_centre}"]['count'] += 1
          hash["#{report_row.consortium}-#{report_row.production_centre}"]['insertion_score'] += report_row.insertion_score.to_i
          hash["#{report_row.consortium}-#{report_row.production_centre}"]['threep_loxp_score'] += report_row.threep_loxp_score.to_i
          hash["#{report_row.consortium}-#{report_row.production_centre}"]['threep_loxp_score_total'] += 1 unless report_row.threep_loxp_score.blank?
          hash["#{report_row.consortium}-#{report_row.production_centre}"]['targeting_score'] += report_row.targeting_score.to_i
          hash["#{report_row.consortium}-#{report_row.production_centre}"]['cassette_score'] += report_row.cassette_score.to_i
        else
          hash["#{report_row.consortium}-#{report_row.production_centre}"] = {}
          hash["#{report_row.consortium}-#{report_row.production_centre}"]['count'] = 1
          hash["#{report_row.consortium}-#{report_row.production_centre}"]['insertion_score'] = report_row.insertion_score.to_i
          hash["#{report_row.consortium}-#{report_row.production_centre}"]['threep_loxp_score'] = report_row.threep_loxp_score.to_i
          hash["#{report_row.consortium}-#{report_row.production_centre}"]['threep_loxp_score_total'] = report_row.threep_loxp_score.blank? ? 0 : 1
          hash["#{report_row.consortium}-#{report_row.production_centre}"]['targeting_score'] = report_row.targeting_score.to_i
          hash["#{report_row.consortium}-#{report_row.production_centre}"]['cassette_score'] = report_row.cassette_score.to_i
        end
      end

      hash
    end

  end

  attr_accessor :report_rows, :conditions, :consortium, :production_centre

  def initialize(options = {})
    @report_rows = []
    @conditions = {}

    @consortia = {}
  end

  def run
    qc_grid.each do |report_row|
      report_rows << QcGridReport::Row.new(report_row)
    end

    self
  end

  def conditions_for_sql
    return nil if !conditions.is_a?(Hash) || conditions.blank?

    operator = "AND "

    conditions_for_sql = String.new.tap do |s|
      conditions.each_with_index do |hash, count|
        key, value = hash

        case key.to_s
          when 'consortium'
            @consortium = Consortium.find_by_name(value)
            value = consortium ? consortium.name : nil
          when 'production_centre'
            @production_centre = Centre.find_by_name(value)
            value = production_centre ? production_centre.name : nil
          else
            value = nil
        end

        next unless key = self.class.conditions_translations[key.to_s]

        if count > 0
          s << operator
        end

        s << "#{key} = '#{value}'\n"
      end
    end

    return nil if conditions_for_sql.blank?

    operator + conditions_for_sql
  end

  def qc_grid
    sql = <<-EOF
      SELECT

        consortia.name AS consortium,
        centres.name AS production_centre,
        genes.marker_symbol AS gene,
        colonies.name AS colony_name,
        targ_rep_es_cells.name AS es_cell,
        targ_rep_mutation_types.name AS mutation_type,
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
        targ_rep_distribution_qcs.chry,
        colony_qcs.qc_southern_blot AS qc_southern_blot,
        colony_qcs.qc_five_prime_lr_pcr AS qc_five_prime_lr_pcr,
        colony_qcs.qc_five_prime_cassette_integrity AS qc_five_prime_cassette_integrity,
        colony_qcs.qc_tv_backbone_assay AS qc_tv_backbone_assay,
        colony_qcs.qc_neo_count_qpcr AS qc_neo_count_qpcr,
        colony_qcs.qc_lacz_count_qpcr AS qc_lacz_count_qpcr,
        colony_qcs.qc_neo_sr_pcr AS qc_neo_sr_pcr,
        colony_qcs.qc_loa_qpcr AS qc_loa_qpcr,
        colony_qcs.qc_homozygous_loa_sr_pcr AS qc_homozygous_loa_sr_pcr,
        colony_qcs.qc_lacz_sr_pcr AS qc_lacz_sr_pcr,
        colony_qcs.qc_mutant_specific_sr_pcr AS qc_mutant_specific_sr_pcr,
        colony_qcs.qc_loxp_confirmation AS qc_loxp_confirmation,
        colony_qcs.qc_three_prime_lr_pcr AS qc_three_prime_lr_pcr,
        colony_qcs.qc_critical_region_qpcr AS qc_critical_region_qpcr,
        colony_qcs.qc_loxp_srpcr AS qc_loxp_srpcr,
        colony_qcs.qc_loxp_srpcr_and_sequencing AS qc_loxp_srpcr_and_sequencing

      FROM mi_attempts
        JOIN (colonies LEFT JOIN colony_qcs ON colony_qcs.colony_id = colonies.id) ON colonies.mi_attempt_id = mi_attempts.id
        JOIN plans  ON mi_attempts.plan_id = plans.id AND plans.mutagenesis_via_crispr_cas9 = false
        JOIN centres   ON centres.id = plans.production_centre_id
        JOIN consortia ON consortia.id = plans.consortium_id
        JOIN genes     ON genes.id = plans.gene_id
        JOIN targ_rep_es_cells   ON targ_rep_es_cells.id = mi_attempts.es_cell_id
        JOIN mi_attempt_statuses ON mi_attempts.status_id = mi_attempt_statuses.id
        JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id

        LEFT JOIN targ_rep_mutation_types ON targ_rep_alleles.mutation_type_id = targ_rep_mutation_types.id
        LEFT JOIN targ_rep_distribution_qcs ON targ_rep_distribution_qcs.es_cell_id = targ_rep_es_cells.id
        LEFT JOIN targ_rep_es_cell_distribution_centres ON targ_rep_es_cell_distribution_centres.id = targ_rep_distribution_qcs.es_cell_distribution_centre_id

      WHERE mi_attempt_statuses.code = 'gtc'

      #{conditions_for_sql}

      ORDER BY
        consortia.name ASC,
        centres.name ASC,
        targ_rep_mutation_types.name ASC,
        genes.marker_symbol ASC
    EOF

    @qc_grid ||= ActiveRecord::Base.connection.execute(sql).to_a
  end

  class << self

    def columns
      [
        'consortium',
        'production_centre',
        'gene',
        'colony_name',
        'es_cell',
        'mutation_type',
        'qc_southern_blot',
        'qc_five_prime_lr_pcr',
        'qc_five_prime_cassette_integrity',
        'qc_tv_backbone_assay',
        'qc_neo_count_qpcr',
        'qc_neo_sr_pcr',
        'qc_loa_qpcr',
        'qc_homozygous_loa_sr_pcr',
        'qc_lacz_sr_pcr',
        'qc_mutant_specific_sr_pcr',
        'qc_loxp_confirmation',
        'qc_three_prime_lr_pcr',
        'qc_critical_region_qpcr',
        'qc_loxp_srpcr',
        'qc_loxp_srpcr_and_sequencing',
        'user_qc_map_test',
        'user_qc_karyotype',
        'user_qc_tv_backbone_assay',
        'user_qc_loxp_confirmation',
        'user_qc_southern_blot',
        'user_qc_loss_of_wt_allele',
        'user_qc_neo_count_qpcr',
        'user_qc_lacz_sr_pcr',
        'user_qc_mutant_specific_sr_pcr',
        'user_qc_five_prime_cassette_integrity',
        'user_qc_neo_sr_pcr',
        'user_qc_five_prime_lr_pcr',
        'user_qc_three_prime_lr_pcr',
        'distribution_centre',
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
        'chry',
        'targeting_score',
        'cassette_score',
        'threep_loxp_score',
        'insertion_score'
      ]
    end

    def conditions_translations
      {
        'consortium' => 'consortia.name',
        'production_centre' => 'centres.name'
      }
    end

    def html_columns
      html_columns = columns.dup

      html_columns.delete_if {|v| v =~ /consortium|production_centre|gene|distribution_centre|colony_name|es_cell/}

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
  end
end