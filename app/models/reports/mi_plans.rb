# encoding: utf-8

class Reports::MiPlans

  class DoubleAssignment
    
    @@consortia = nil
    @@funders = nil

    LIST_COLUMNS = [ 'Target Consortium', 'Marker Symbol', 'Consortium', 'Plan Status', 'MI Status', 'Centre', 'MI Date' ]
  
    def self.get_funding
      return @@funders if @@funders != nil
      @@funders = Consortium.all.map { |i| i.funding }
      return @@funders
    end

    def self.get_consortia
      return @@consortia if @@consortia != nil
      
      all = Consortium.all.map(&:name).sort_by { |c| c.downcase }
      komp2 = Consortium.all.find_all { |item| item.funding == 'KOMP2' }.map(&:name).sort
      ikmc = ["EUCOMM-EUMODIC", "MGP-KOMP", "DTCC-KOMP"]
      others = all - komp2 - ikmc
      @@consortia = komp2 + others + ikmc
      return @@consortia
    end
    
    def self.get_genes_for_matrix

      assigned_statuses = '(' + MiPlanStatus.all_assigned.map { |i| i.id }.join(',') + ')'

      sql = <<-"SQL"
        select
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
        ) and mi_plan_status_id in #{assigned_statuses} order by marker_symbol;
      SQL
      
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

      sql = <<-"SQL"
        select
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
        ) and mi_plan_status_id in #{assigned_statuses} order by marker_symbol;
      SQL

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
    
    def self.get_matrix_columns
      columns = []
      
      funders = get_funding
      consortia = get_consortia

      for i in (0..funders.size-1)
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

      report = Table(['']+columns)

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
          else
            genes_in_overlap = cons_matrix[row1] && cons_matrix[row1][row2] ? cons_matrix[row1][row2] : {}
            new_row.push genes_in_overlap && genes_in_overlap.count != 0 ? genes_in_overlap.count : ''
          end
        end
        report << new_row
        rows += 1
      end
      
      #TODO: https://github.com/i-dcc/imits/pull/3/files#r229742

      return report

    end

    def self.get_list_columns
      return LIST_COLUMNS
    end

    def self.get_list

      report = get_list_without_grouping

      report = Grouping( report, :by => 'Target Consortium', :order => 'Marker Symbol' )

      return report

    end
    
    # return the table before grouping so test can check it

    def self.get_list_without_grouping

      genes = get_genes_for_list

      consortia = get_consortia

      report = Table( get_list_columns )

      consortia.each do |consortium|
        group_heading = "Double-Assignments for Consortium: #{consortium}"
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
