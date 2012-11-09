# encoding: utf-8

class Reports::MiPlans

  class DoubleAssignment

    LIST_COLUMNS = [ 'Target Consortium', 'Marker Symbol', 'Consortium', 'MI Status', 'Centre', 'MI Date' , 'ES Cell', 'MUTATION TYPE']

    def self.get_consortia
      all = Consortium.all.map(&:name).sort_by { |c| c.downcase }
      komp2 = Consortium.all.find_all { |item| item.funding == 'KOMP2' }.map(&:name).sort
      ikmc = ["EUCOMM-EUMODIC", "UCD-KOMP", "MGP Legacy"]
      others = all - komp2 - ikmc
      return komp2 + others + ikmc
    end

    def self.get_genes_for_matrix

      assigned_statuses = '(' + MiPlan::Status.all_assigned.map { |i| i.id }.join(',') + ')'

      sql = <<-"SQL"
        select
          genes.marker_symbol as marker_symbol,
          COALESCE(centres.name, 'NONE') as centres_name,
          consortia.name as consortia_name
        from mi_attempts
          join mi_plans on (mi_attempts.mi_plan_id = mi_plans.id and mi_attempts.is_active = true)
          join centres on mi_plans.production_centre_id = centres.id
          join consortia on mi_plans.consortium_id = consortia.id
          join genes on mi_plans.gene_id = genes.id
        where mi_plans.gene_id in (
          select gene_id
          from mi_plans join mi_attempts on (mi_plans.id = mi_attempts.mi_plan_id and mi_attempts.is_active = true)
          group by gene_id
          having (count(distinct(mi_plans.production_centre_id)) > 1 or count(distinct(mi_plans.consortium_id)) > 1)
        )
        order by marker_symbol
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

      assigned_statuses = '(' + MiPlan::Status.all_assigned.map { |i| i.id }.join(',') + ')'

      sql = <<-"SQL"
        select
          marker_symbol as marker_symbol,
          mi_plan_statuses.name as mi_plan_statuses_name,
          COALESCE(centres.name, 'NONE') as centres_name,
          consortia.name as consortia_name,
          mi_attempts.mi_date as mi_attempts_mi_date,
          mi_attempt_statuses.name as mi_attempt_statuses_name,
          targ_rep_es_cells.name es_cell_name,
          targ_rep_es_cells.mutation_subtype mutation_type
        from mi_plans
          join mi_plan_statuses on mi_plans.status_id = mi_plan_statuses.id
          join mi_attempts on (mi_plans.id = mi_attempts.mi_plan_id and mi_attempts.is_active = true)
          join mi_attempt_statuses on mi_attempts.status_id = mi_attempt_statuses.id
          join targ_rep_es_cells on targ_rep_es_cells.id = mi_attempts.es_cell_id
          join consortia on mi_plans.consortium_id = consortia.id
          join centres on mi_plans.production_centre_id = centres.id
          join genes on mi_plans.gene_id = genes.id
        where mi_plans.gene_id in (
          select gene_id
          from mi_plans join mi_attempts on (mi_plans.id = mi_attempts.mi_plan_id and mi_attempts.is_active = true)
          group by gene_id
          having (count(distinct(mi_plans.production_centre_id)) > 1 or count(distinct(mi_plans.consortium_id)) > 1)
        )
        order by marker_symbol, consortia_name
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
          row['mi_attempt_statuses_name'],
          row['centres_name'],
          row['mi_attempts_mi_date'],
          row['es_cell_name'],
          row['mutation_type']
        ]
        )
      end

      return genes

    end

    def self.get_matrix_columns
      columns = []

      consortia = get_consortia
      consortia.each do |cons|
        columns.push(cons)
      end

      columns
    end

    def self.get_matrix_data

      genes = get_genes_for_matrix

      cons_matrix = {}
      genes.each_pair do |marker_symbol, consortium|
        genes[marker_symbol].each_pair do |consortium, v2|
          genes[marker_symbol].each_pair do |consortiumb, v3|
            cons_matrix[consortium] ||= {}
            cons_matrix[consortium][consortiumb] ||= {}
            cons_matrix[consortium][consortiumb][marker_symbol] = 0;
            cons_matrix[consortium][consortiumb][marker_symbol] = 1 if consortium != consortiumb;
          end
        end
      end

      return cons_matrix

    end

    def self.get_matrix

      cons_matrix = get_matrix_data

      columns = get_matrix_columns

      report = Table(['']+columns)

      consortia = get_consortia

      rows = 0
      consortia.each do |cons1|
        cols = 0
        new_row = []
        new_row.push columns[rows]
        consortia.each do |cons2|
          cols += 1
          if cols-1 <= rows  # skip duplicate cells
            new_row.push ''
          else
            genes_in_overlap = {}
            if cons_matrix[cons1] && cons_matrix[cons1][cons2]
              genes_in_overlap = cons_matrix[cons1][cons2]
            end

            genes_in_overlap = genes_in_overlap.count > 0 ? genes_in_overlap.count : ''

            new_row.push genes_in_overlap
          end
        end
        report << new_row
        rows += 1
      end

      return report

    end

    # The matrix data is the actual matrix of double-produced genes for each consortium
    def self.get_list()
      report = get_list_without_grouping
      report = Grouping( report, :by => 'Target Consortium', :order => ['Marker Symbol', 'Consortium', 'Centre'] )
      return report
    end

    def self.get_list_without_grouping

      genes = get_genes_for_list

      consortia = get_consortia

      report = Table( LIST_COLUMNS )

      consortia.each do |consortium|
        group_heading = "Double - Production for Consortium: #{consortium}"
        genes.each_pair do |marker, value|
          consortia_for_gene = value.keys
          has_consortia = consortia_for_gene.grep(/^#{consortium}$/)
          next if ! has_consortia || has_consortia.size < 1
          value.keys.each do |found_consortium|
            mi_array = genes[marker][found_consortium];
            mi_array.each do |mi|
              mi_status = mi[3]
              if mi_status != 'Micro-injection aborted'
                report << [group_heading] + mi
              end
            end
          end
        end
      end

      return report

    end

  end

end
