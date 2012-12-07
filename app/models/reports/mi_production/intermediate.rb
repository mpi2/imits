# encoding: utf-8

class Reports::MiProduction::Intermediate < Reports::Base

  # TODO: unit-test it, share it somewhere for all reports, expand it so it
  # handles deeply nested associations
  def generate_report_options(report_columns)
    report_options = {
      :only => [],
      :include => {}
    }

    report_columns.each do |column_spec, column_header|
      report_options[:only].push column_spec
      if(column_spec.include? '.')
        association, attribute = column_spec.split('.').map(&:to_sym)
        report_options[:include][association] ||= {:only => []}
        report_options[:include][association][:only].push attribute
      end
    end

    return report_options
  end

  def self.report_name; 'mi_production_intermediate'; end

  attr_reader :report

  def initialize
    report_columns = {
      'consortium.name' => 'Consortium',
      'sub_project.name' => 'Sub-Project',
      'is_bespoke_allele' => 'Is Bespoke Allele',
      'priority.name' => 'Priority',
      'production_centre.name' => 'Production Centre',
      'gene.marker_symbol' => 'Gene',
      'gene.mgi_accession_id' => 'MGI Accession ID',
      'status.name' => 'MiPlan Status',
      'id' => 'MiPlan ID'
    }

    report_options = generate_report_options(report_columns)
    report_options[:methods] = [
      'reportable_statuses_with_latest_dates',
      'latest_relevant_mi_attempt',
      'best_status_phenotype_attempt',
      'distinct_old_genotype_confirmed_es_cells_count',
      'distinct_old_non_genotype_confirmed_es_cells_count',
      'total_pipeline_efficiency_gene_count',
      'gc_pipeline_efficiency_gene_count'
    ]

    transform = proc do |record|

      record["is_bespoke_allele"] = record["is_bespoke_allele"] ? 'Yes' : 'No'

      plan_status_dates = record['reportable_statuses_with_latest_dates']
      plan_status_dates.each do |name, date|
        record["#{name} Date"] = date.to_s
      end

      record['Overall Status'] = record['status.name']

      mi_attempt = record['latest_relevant_mi_attempt']
      if mi_attempt
        record['MiAttempt Status'] = mi_attempt.status.name
        record['Overall Status'] = record['MiAttempt Status']
        record['IKMC Project ID'] = mi_attempt.es_cell.ikmc_project_id
        record['Mutation Sub-Type'] = mi_attempt.es_cell.mutation_subtype
        record['Allele Symbol'] = mi_attempt.allele_symbol
        record['Genetic Background'] = mi_attempt.colony_background_strain.try(:name)
        record['MiAttempt Colony Name'] = mi_attempt.colony_name
        mi_status_dates = mi_attempt.reportable_statuses_with_latest_dates
        mi_status_dates.each do |name, date|
          record["#{name} Date"] = date.to_s
        end
      end

      phenotype_attempt = record['best_status_phenotype_attempt']
      if phenotype_attempt
        record['PhenotypeAttempt Status'] = phenotype_attempt.status.name
        record['Overall Status'] = record['PhenotypeAttempt Status']
        record['PhenotypeAttempt Colony Name'] = phenotype_attempt.colony_name

        phenotype_mi_attempt = phenotype_attempt.mi_attempt
        record['MiAttempt Consortium'] = phenotype_mi_attempt.consortium_name
        record['MiAttempt Production Centre'] = phenotype_mi_attempt.production_centre_name
        record['MiAttempt Colony Name'] = phenotype_mi_attempt.colony_name if !record['MiAttempt Colony Name']

        pt_status_names = phenotype_attempt.reportable_statuses_with_latest_dates
        pt_status_names.each do |name, date|
          record["#{name} Date"] = date.to_s
        end
      end

      record['Distinct Genotype Confirmed ES Cells'] = record['distinct_old_genotype_confirmed_es_cells_count']
      record['Distinct Old Non Genotype Confirmed ES Cells'] = record['distinct_old_non_genotype_confirmed_es_cells_count']

      record['Total Pipeline Efficiency Gene Count'] = record['total_pipeline_efficiency_gene_count']
      record['GC Pipeline Efficiency Gene Count'] = record['gc_pipeline_efficiency_gene_count']

    end
    report_options[:transforms] = [transform]

    report = MiPlan.report_table(:all, report_options)

    report.rename_columns(report_columns)
    column_names = report_columns.values - ['MiPlan ID'] - ['MiPlan Status'] + [
      'Overall Status',
      'MiPlan Status',
      'MiAttempt Status',
      'PhenotypeAttempt Status',
      'IKMC Project ID',
      'Mutation Sub-Type',
      'Allele Symbol',
      'Genetic Background',
      'Assigned Date',
      'Assigned - ES Cell QC In Progress Date',
      'Assigned - ES Cell QC Complete Date',
      'Micro-injection in progress Date',
      'Chimeras obtained Date',
      'Genotype confirmed Date',
      'Micro-injection aborted Date',
      'Phenotype Attempt Registered Date',
      'Rederivation Started Date',
      'Rederivation Complete Date',
      'Cre Excision Started Date',
      'Cre Excision Complete Date',
      'Phenotyping Started Date',
      'Phenotyping Complete Date',
      'Phenotype Attempt Aborted Date',
      'Distinct Genotype Confirmed ES Cells',
      'Distinct Old Non Genotype Confirmed ES Cells',
      'MiPlan ID',
      'Total Pipeline Efficiency Gene Count',
      'GC Pipeline Efficiency Gene Count',
      'Aborted - ES Cell QC Failed Date',
      'MiAttempt Colony Name',
      'MiAttempt Consortium',
      'MiAttempt Production Centre',
      'PhenotypeAttempt Colony Name'
    ]
    report.reorder(column_names)

    report.data.each do |record|
      record.attributes.each do |attr|
        if record[attr] == nil
          record[attr] = ''
        end
      end
    end

    @report = report.sort_rows_by(column_names)
  end

  def cache
    super
    IntermediateReport.generate(@report)
  end
end
