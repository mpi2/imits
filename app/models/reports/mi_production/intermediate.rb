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
      'priority.name' => 'Priority',
      'production_centre.name' => 'Production Centre',
      'gene.marker_symbol' => 'Gene',
      'gene.mgi_accession_id' => 'MGI Accession ID',
      'status.name' => 'MiPlan Status'
    }

    report_options = generate_report_options(report_columns)
    report_options[:methods] = [
      'reportable_statuses_with_latest_dates',
      'latest_relevant_mi_attempt',
      'latest_relevant_phenotype_attempt',
      'distinct_genotype_confirmed_es_cells_count',
      'distinct_old_non_genotype_confirmed_es_cells_count'
    ]

    transform = proc do |record|
      plan_status_dates = record['reportable_statuses_with_latest_dates']
      plan_status_dates.each do |name, date|
        record["#{name} Date"] = date.to_s
      end

      record['Overall Status'] = record['status.name']

      mi_attempt = record['latest_relevant_mi_attempt']
      if mi_attempt
        record['MiAttempt Status'] = mi_attempt.mi_attempt_status.description
        record['Overall Status'] = record['MiAttempt Status']
        record['IKMC Project ID'] = mi_attempt.es_cell.ikmc_project_id
        record['Mutation Sub-Type'] = mi_attempt.es_cell.mutation_subtype
        record['Allele Symbol'] = mi_attempt.allele_symbol
        record['Genetic Background'] = mi_attempt.colony_background_strain.try(:name)
        mi_status_dates = mi_attempt.reportable_statuses_with_latest_dates
        mi_status_dates.each do |description, date|
          record["#{description} Date"] = date.to_s
        end
      end

      phenotype_attempt = record['latest_relevant_phenotype_attempt']
      if phenotype_attempt
        record['PhenotypeAttempt Status'] = phenotype_attempt.status.name
        record['Overall Status'] = record['PhenotypeAttempt Status']

        pt_status_names = phenotype_attempt.reportable_statuses_with_latest_dates
        pt_status_names.each do |name, date|
          record["#{name} Date"] = date.to_s
        end
      end

      record['Distinct Genotype Confirmed ES Cells'] = record['distinct_genotype_confirmed_es_cells_count']
      record['Distinct Old Non Genotype Confirmed ES Cells'] = record['distinct_old_non_genotype_confirmed_es_cells_count']

    end
    report_options[:transforms] = [transform]

    report = MiPlan.report_table(:all, report_options)

    report.rename_columns(report_columns)
    column_names = report_columns.values - ['MiPlan Status'] + [
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
      'Distinct Old Non Genotype Confirmed ES Cells'
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
end
