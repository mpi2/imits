# encoding: utf-8

class Reports::MiPlans

  class DoubleAssignment

#imits_development=# select * from consortia;
# id |      name      |        funding        |                   participants                    | contact |         created_at         |         updated_at         
#----+----------------+-----------------------+---------------------------------------------------+---------+----------------------------+----------------------------
#  4 | BaSH           | KOMP2                 | Baylor, Sanger, Harwell                           |         | 2011-10-10 09:47:04.514909 | 2011-10-10 09:49:09.785945
#  5 | DTCC           | KOMP2                 | Davis-Toronto-Charles River-CHORI                 |         | 2011-10-10 09:49:09.804322 | 2011-10-10 09:49:09.81595
#  2 | DTCC-KOMP      | KOMP                  | Davis-Toronto-Charles River-CHORI                 |         | 2011-10-10 09:47:04.507889 | 2011-10-10 09:49:09.82567
#  1 | EUCOMM-EUMODIC | EUCOMM / EUMODIC      |                                                   |         | 2011-10-10 09:47:04.496476 | 2011-10-10 09:49:09.833663
#  6 | Helmholtz GMC  | Infrafrontier/BMBF    | Helmholtz Muenchen                                |         | 2011-10-10 09:49:09.84065  | 2011-10-10 09:49:09.846541
#  7 | JAX            | KOMP2                 | The Jackson Laboratory                            |         | 2011-10-10 09:49:09.853132 | 2011-10-10 09:49:09.859321
#  8 | MARC           | China                 | Model Animarl Research Centre, Nanjing University |         | 2011-10-10 09:49:09.866204 | 2011-10-10 09:49:09.872266
#  9 | MGP            | Wellcome Trust        | Mouse Genetics Project, WTSI                      |         | 2011-10-10 09:49:09.878915 | 2011-10-10 09:49:09.884969
#  3 | MGP-KOMP       | KOMP / Wellcome Trust | Mouse Genetics Project, WTSI                      |         | 2011-10-10 09:47:04.511435 | 2011-10-10 09:49:09.891933
# 10 | Monterotondo   | European Union        | Monterotondo Institute for Cell Biology (CNR)     |         | 2011-10-10 09:49:09.898876 | 2011-10-10 09:49:09.904677
# 11 | MRC            | MRC                   | MRC - Harwell                                     |         | 2011-10-10 09:49:09.911704 | 2011-10-10 09:49:09.917592
# 12 | NorCOMM2       | Genome Canada         | NorCOMM2                                          |         | 2011-10-10 09:49:09.924289 | 2011-10-10 09:49:09.930046
# 13 | Phenomin       | Phenomin              | ICS                                               |         | 2011-10-10 09:49:09.937161 | 2011-10-10 09:49:09.943349
# 14 | RIKEN BRC      | Japanese government   | RIKEN BRC                                         |         | 2011-10-10 09:49:09.950102 | 2011-10-10 09:49:09.955935
#(14 rows)

    public
    
    def self.get_funding
      funders = Consortium.all.map { |i| i.funding }
      #funders = %w[ KOMP2 KOMP2 KOMP2 IMPC IMPC IMPC IMPC IMPC IMPC IMPC IMPC IKMC IKMC IKMC ]
      return funders
    end
    
    def self.get_consortia
      ikmc_funders = [ 'EUCOMM / EUMODIC', 'KOMP / Wellcome Trust', 'KOMP' ]
      impc_funders = [ 'Infrafrontier/BMBF', 'China', 'Wellcome Trust', 'MRC', 'European Union', 'Genome Canada', 'Phenomin', 'Japanese government' ]
      komp2 = []
      Consortium.all.map { |i| komp2.push i.name if i.funding == 'KOMP2' }
      impc = []
      Consortium.all.map { |i| impc.push i.name if impc_funders.include?(i.funding) }
      ikmc = []
      Consortium.all.map { |i| ikmc.push i.name if ikmc_funders.include?(i.funding) }
      others = []
      Consortium.all.map { |i| others.push i.name if !impc.include?(i.name) && !komp2.include?(i.name) && !ikmc.include?(i.name) }
      
#      consortia = []
#      consortia.push komp2.to_a + impc.to_a + others.to_a
      consortia = komp2 + impc + ikmc + others
      #consortia = %w[ BaSH DTCC JAX Helmholtz-GMC MARC MGP MRC Monterotondo NorCOMM2 Phenomin RIKEN-BRC EUCOMM-EUMODIC MGP-KOMP DTCC-KOMP ]
      return consortia
    end
    
    def self.get_genes_for_matrix

      assigned_statuses = '(' + MiPlanStatus.all_assigned.map { |i| i.id }.join(',') + ')'

      sql = "select
        genes.marker_symbol as marker_symbol,
        COALESCE(centres.name, 'NONE') as centres_name,
        consortia.name as consortia_name
      from mi_plans
        left outer join centres on mi_plans.production_centre_id = centres.id
        join consortia on mi_plans.consortium_id = consortia.id
        join genes on mi_plans.gene_id = genes.id
      where mi_plans.gene_id in (
        select gene_id
        from mi_plans
        where mi_plan_status_id in #{assigned_statuses} 
        group by gene_id
        having count(*) > 1
      ) and mi_plan_status_id in #{assigned_statuses} order by marker_symbol;"

      result = ActiveRecord::Base.connection.select_all( sql )

      genes = {}
      
      result.each do |row|
        genes[row['marker_symbol']] ||= {}
        genes[row['marker_symbol']][row['consortia_name']] ||= []
        genes[row['marker_symbol']][row['consortia_name']].push(
        [
          row['marker_symbol'],
          row['consortia_name'],
          row['centres_name']
        ]
        )
      end

      return genes

    end

    def self.get_genes_for_list

      assigned_statuses = '(' + MiPlanStatus.all_assigned.map { |i| i.id }.join(',') + ')'

      sql = "select
        marker_symbol as marker_symbol,
        mi_plan_statuses.name as mi_plan_statuses_name,
        COALESCE(centres.name, 'NONE') as centres_name,
        consortia.name as consortia_name,
        mi_attempts.mi_date as mi_attempts_mi_date,
        mi_attempt_statuses.description as mi_attempt_statuses_description
      from mi_plans
        join mi_plan_statuses on mi_plans.mi_plan_status_id = mi_plan_statuses.id
        left outer join mi_attempts on mi_plans.id = mi_attempts.mi_plan_id
        left outer join mi_attempt_statuses on mi_attempts.mi_attempt_status_id = mi_attempt_statuses.id
        join consortia on mi_plans.consortium_id = consortia.id
        left outer join centres on mi_plans.production_centre_id = centres.id
        join genes on mi_plans.gene_id = genes.id
      where mi_plans.gene_id in (
        select gene_id
        from mi_plans
        where mi_plan_status_id in #{assigned_statuses}
        group by gene_id
        having count(*) > 1
      ) and mi_plan_status_id in #{assigned_statuses} order by marker_symbol;"

#      ) and mi_plan_status_id in #{assigned_statuses} order by marker_symbol, consortia_name;"

      result = ActiveRecord::Base.connection.select_all( sql )

      genes = {}
      result.each do |row|
        genes[row['marker_symbol']] ||= {}
        genes[row['marker_symbol']][row['consortia_name']] ||= []
        genes[row['marker_symbol']][row['consortia_name']].push(
        [
          row['marker_symbol'],
          row['consortia_name'],
          row['mi_plan_statuses_name'],
          row['mi_attempt_statuses_description'],
          row['centres_name'],
          row['mi_attempts_mi_date']
        ]
        )
      end

      return genes

    end

    public
    
    def self.get_matrix_columns
      columns = []
      
      funders = get_funding
      consortia = get_consortia

      for i in (0..funders.size-1)
        #columns.push(funders[i] + '/' + consortia[i])
        columns.push(funders[i] + ' - ' + consortia[i])
      end
      columns
    end

    def self.get_matrix

      genes = get_genes_for_matrix

      cons_matrix = {}
      genes.each_pair do |k1, v1|
        genes[k1].each_pair do |k2, v2|
          genes[k1].each_pair do |k3, v3|
            cons_matrix[k2] ||= {}
            cons_matrix[k2][k3] ||= {}
            cons_matrix[k2][k3][k1] = 0;
            cons_matrix[k2][k3][k1] = 1 if k2 != k3;
          end
        end
      end

      columns = get_matrix_columns
      columns.unshift('')

      report = Table( columns )

      columns.shift

      consortia = get_consortia

      rows = 0
      consortia.each do |row1|
        cols = 0
        new_row = []
        new_row.push columns[rows]
        consortia.each do |row2|
          cols += 1
          if cols-1 <= rows  # skip duplicate rows
            new_row.push ''
            next
          end
          genes_in_overlap = cons_matrix[row1] && cons_matrix[row1][row2] ? cons_matrix[row1][row2] : {}
          new_row.push genes_in_overlap && genes_in_overlap.count != 0 ? genes_in_overlap.count : ''
        end
        report << new_row
        rows += 1
      end

      return report

    end

    def self.get_list_columns
      return [
        'Target Consortium',
        'Marker Symbol',
        'Consortium',
        'Plan Status',
        'MI Status',
        'Centre',
        'MI Date'
      ]
    end

    def self.get_list

      report = get_list_raw

      report = Grouping( report, :by => 'Target Consortium', :order => 'Marker Symbol' )

      return report

    end
    
    # return the table before grouping so test can check it

    def self.get_list_raw

      genes = get_genes_for_list

      consortia = get_consortia

      report = Table( get_list_columns )

      consortia.each do |consortium|
        group_heading = "DOUBLE-ASSIGNMENTS FOR consortium: #{consortium}"
        genes.each_pair do |marker, value|
          consortia_for_gene = value.keys
          has_consortia = consortia_for_gene.grep(/^#{consortium}$/)
          next if ! has_consortia || has_consortia.size < 1
          value.keys.each do |found_consortium|
            mi_array = genes[marker][found_consortium];
            mi_array.each do |mi|
              mi_status = mi[3]
              next if mi_status == 'Micro-injection aborted'
              mi2 = mi.clone
              mi2.unshift(group_heading)
              report << mi2
            end
          end
        end
      end

      return report

    end

  end

end
