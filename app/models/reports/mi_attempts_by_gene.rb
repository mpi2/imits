# encoding: utf-8

class Reports::MiAttemptsByGene

  class GeneSummary

    include Reports::Helper

    def self.get(request, params)
      report = Common.generate_mi_list_report( params )

      if report.nil?
        redirect_to Common.cleaned_redirect_params( :mi_attempts_by_gene, params ) if request && request.format == :csv
        return
      end

      report2 = Table(
        [
          'Consortium',
          'Production Centre',
          '# Genes Injected',
          '# Genes Genotype Confirmed',
          '# Genes For EMMA'
        ]
      )

      grouped_report = Grouping( report, :by => [ 'Consortium', 'Production Centre' ], :order => [:name]  )

      grouped_report.each do |consortium|

        grouped_report.subgrouping(consortium).summary(
          'Production Centre',
          '# Genes Injected'           => lambda { |group| Common.count_unique_instances_of( group, 'Marker Symbol' ) },
          '# Genes Genotype Confirmed' => lambda { |group| Common.count_unique_instances_of( group, 'Marker Symbol', lambda { |row| row.data['Status'] == 'Genotype confirmed' ? true : false } ) },
          '# Genes For EMMA'           =>
            lambda {
            |group| Common.count_unique_instances_of(
              group,
              'Marker Symbol',
              lambda { |row| ((row.data['Status'] == 'Genotype confirmed') && (row.data['Suitable for EMMA?'])) ? true : false }
            )
          }
        ).each do |row|
          report2 << {
            'Consortium' => consortium,
            'Production Centre' => row['Production Centre'],
            '# Genes Injected' => row['# Genes Injected'],
            '# Genes Genotype Confirmed' => row['# Genes Genotype Confirmed'],
            '# Genes For EMMA' => row['# Genes For EMMA']
          }
        end

      end
      
      report2.sort_rows_by!(['Consortium', 'Production Centre'])

      return report2

    end

  end

end
