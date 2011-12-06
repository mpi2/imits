# encoding: utf-8

class Reports::MonthlyProduction

  extend Reports::Helper

  def self.generate(request = nil, params = { :format => "html" })
    report = generate_mi_list_report( params )

    if report.nil?
      redirect_to cleaned_redirect_params( :mi_attempts_monthly_production, params ) if request && request.format == :csv
      return
    end

    report.add_column( 'Month Injected' ) do |row|
      "#{row.data['Injection Date'].year}-#{sprintf('%02d', row.data['Injection Date'].month)}" if row.data['Injection Date']
    end

    report_table = Table(
      [
        'Consortium',
        'Production Centre',
        'Month Injected',
        '# Clones Injected',
        '# at Birth',
        '% at Birth',
        '# at Weaning',
        '# Genotype Confirmed',
        '% Genotype Confirmed'
      ]
    )

    grouped_report = Grouping( report, :by => [ 'Consortium', 'Production Centre', 'Month Injected' ] )
    grouped_report.each do |consortium|
      group_consortium = grouped_report.subgrouping(consortium)
      group_consortium.each do |production_centre|
        group_production_centre = group_consortium.subgrouping(production_centre)

        summary = group_production_centre.summary(
          'Month Injected',
          '# Clones Injected'           => lambda { |group| count_unique_instances_of( group, 'Clone Name' ) },
          '# at Birth'                  => lambda { |group| count_unique_instances_of( group, 'Clone Name', lambda { |row| row.data['# Pups Born'].to_i > 0 ? true : false } ) },
          '# at Weaning'                => lambda { |group| count_unique_instances_of( group, 'Clone Name', lambda { |row| row.data['# Male Chimeras'].to_i > 0 ? true : false } ) },
          '# Genotype Confirmed' => lambda { |group| count_unique_instances_of( group, 'Clone Name', lambda { |row| row.data['Status'] == 'Genotype confirmed' ? true : false } ) }
        )

        summary.add_column( '% at Birth',    :after => '# at Birth' )                  { |row| calculate_percentage( row.data['# at Birth'], row.data['# Clones Injected'] ) }
        summary.add_column( '% Genotype Confirmed', :after => '# Genotype Confirmed' ) { |row| calculate_percentage( row.data['# Genotype Confirmed'], row.data['# Clones Injected'] ) }

        summary.each_entry do |row|
          hash = row.to_hash
          hash['Consortium'] = consortium
          hash['Production Centre'] = production_centre
          report_table << hash
        end

      end
    end

    report_table.sort_rows_by!( nil, :order => :descending ) do |row|
      if row.data['Month Injected']
        datestr = row.data['Month Injected'].split('-')
        Date.new( datestr[0].to_i, datestr[1].to_i, 1 )
      else
        Date.new( 1966, 6, 30 )
      end
    end

    report_table.sort_rows_by!(['Month Injected'], :order => :descending)
    report_table.sort_rows_by!(['Consortium', 'Production Centre'])

    return report_table

  end

end
