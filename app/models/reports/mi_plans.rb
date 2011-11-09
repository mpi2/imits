# encoding: utf-8

class Reports::MiPlans

  class DoubleAssignment

    #  FUNDING = %w[ KOMP2 KOMP2 KOMP2 IMPC IMPC IMPC IMPC IMPC IMPC IMPC IMPC IKMC IKMC IKMC KOMP2 IMPC IKMC ]
    #  CONSORTIA = %w[ BaSH DTCC JAX Helmholtz-GMC MARC MGP MRC Monterotondo NorCOMM2 Phenomin RIKEN-BRC EUCOMM-EUMODIC MGP-KOMP DTCC-KOMP NONE NONE NONE ]
    FUNDING = %w[ KOMP2 KOMP2 KOMP2 IMPC IMPC IMPC IMPC IMPC IMPC IMPC IMPC IKMC IKMC IKMC ]
    CONSORTIA = %w[ BaSH DTCC JAX Helmholtz-GMC MARC MGP MRC Monterotondo NorCOMM2 Phenomin RIKEN-BRC EUCOMM-EUMODIC MGP-KOMP DTCC-KOMP ]

    def self.get_genes
      get_genes_old
    end

    def self.get_results
      #    result = get_genes_old_1
      result = get_genes_new_2
      report = Table( ['marker_symbol', 'mi_plan_statuses_name', 'centres_name', 'consortia_name', 'mi_attempts_mi_date', 'mi_attempt_statuses_description'] )
      result.each do |row|
        report << row
      end

      return report

    end

    def self.get_genes_old_1

      newarray = []
      MiPlanStatus.all_assigned.map { |i| newarray.push(i.id) }

      sql = "select
      marker_symbol as marker_symbol,
      mi_plan_statuses.name as mi_plan_statuses_name,
      centres.name as centres_name,
      consortia.name as consortia_name,
      mi_attempts.mi_date as mi_attempts_mi_date,
      mi_attempt_statuses.description as mi_attempt_statuses_description
      from mi_plans
      join mi_plan_statuses on mi_plans.mi_plan_status_id = mi_plan_statuses.id
      left outer join mi_attempts on mi_plans.id = mi_attempts.mi_plan_id
      left outer join mi_attempt_statuses on mi_attempts.mi_attempt_status_id = mi_attempt_statuses.id
      join consortia on mi_plans.consortium_id = consortia.id
      join centres on mi_plans.production_centre_id = centres.id
      join genes on mi_plans.gene_id = genes.id
      where mi_plans.gene_id in (
      select gene_id
      from mi_plans
      where mi_plan_status_id in (" + newarray.join(',').to_s + ") " +
      "group by gene_id
      having count(*) > 1
      ) and mi_plan_status_id in (" + newarray.join(',').to_s + ") " + "order by marker_symbol;"

      result = ActiveRecord::Base.connection.select_all( sql )
      
      return result

    end

    def self.get_genes_old

      result = get_genes_old_1

      #puts "TEST COUNT 1: " + result.size.to_s

      #TEST COUNT 1: 438

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
          #          row['centres_name'] && row['centres_name'].length > 0 ? row['centres_name'] : 'NONE',
          row['centres_name'],
          row['mi_attempts_mi_date']
        ]
        )
      end

      return genes

    end

    def self.get_consortia_matrix(genes)

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

      return cons_matrix

    end

    def self.get_matrix_columns
      columns = []

      for i in (0..FUNDING.size-1)
        columns.push(FUNDING[i] + '/' + CONSORTIA[i])
      end
      columns
    end
    #
    #def self.get_genes_new_2
    #
    #  newarray = []
    #  MiPlanStatus.all_assigned.map { |i| newarray.push(i.id) }
    #
    #  genes_ids = MiPlan.all(:select => 'gene_id',
    #  :conditions => "mi_plans.mi_plan_status_id in (" + newarray.join(',').to_s + ")",
    #  :group => "mi_plans.gene_id having count(*) > 1")
    #
    #  result = []
    #
    #  newarray = []
    #  genes_ids.map { |i| newarray.push(i['gene_id']) }
    #
    #  genes = Gene.find( newarray )
    #
    #  genes.each do |gene|
    #
    #    gene.mi_plans.each do |plan|
    #      hash = {
    #        'marker_symbol' => gene.marker_symbol,
    #        'mi_plan_statuses_name' => plan.mi_plan_status.name,
    #        'centres_name' => plan.production_centre.name,
    #        'consortia_name' => plan.consortium.name,
    #        'mi_attempts_mi_date' => plan.mi_attempts.size > 0 ? plan.mi_attempts[plan.mi_attempts.size-1].mi_date : nil,
    #        'mi_attempt_statuses_description' => plan.mi_attempts.size > 0 ? plan.mi_attempts[plan.mi_attempts.size-1].mi_attempt_status.description : nil
    #      }
    #      result.push(hash)
    #    end
    #
    #  end
    #
    #  genes = {}
    #  result.each do |row|
    #    genes[row['marker_symbol']] ||= {}
    #    genes[row['marker_symbol']][row['consortia_name']] ||= []
    #    genes[row['marker_symbol']][row['consortia_name']].push(
    #    [
    #      row['marker_symbol'],
    #      row['consortia_name'],
    #      row['mi_plan_statuses_name'],
    #      row['mi_attempt_statuses_description'],
    #      row['centres_name'],
    #      row['mi_attempts_mi_date']
    #    ]
    #    )
    #  end
    #
    #  #puts "TEST COUNT 2: " + result.size.to_s
    #  #puts "result.inspect: " + result.inspect
    #
    #  return genes
    #
    #end
    
    #
    def self.get_genes_new_2

      newarray = []
      MiPlanStatus.all_assigned.map { |i| newarray.push(i.id) }

      genes = MiPlan.all(:select => 'gene_id',
      :conditions => "mi_plans.mi_plan_status_id in (" + newarray.join(',').to_s + ")",
      :group => "mi_plans.gene_id having count(*) > 1")

      puts "PLAN COUNT 2: " + genes.size.to_s

      result = []

      genes.each do |gene_id|
        gene = Gene.find(gene_id['gene_id'])

        gene.mi_plans.each do |plan|
          
          #>> ['Cat', 'Dog', 'Bird'].include? 'Dog'
          
          next if ! newarray.include? plan.mi_plan_status.id

          if plan.mi_attempts.size == 0
            hash = {
              'marker_symbol' => gene.marker_symbol,
              'mi_plan_statuses_name' => plan.mi_plan_status.name,
              'centres_name' => plan.production_centre.name,
              'consortia_name' => plan.consortium.name,
              'mi_attempts_mi_date' => '',
              'mi_attempt_statuses_description' => ''
            }
            result.push(hash)
            next
          end
          plan.mi_attempts.each do |attempt|
            hash = {
              'marker_symbol' => gene.marker_symbol,
              'mi_plan_statuses_name' => plan.mi_plan_status.name,
              #          'centres_name' => plan.production_centre.name.length > 0 ? plan.production_centre.name : 'NONE',
              'centres_name' => plan.production_centre.name,
              'consortia_name' => plan.consortium.name,
              'mi_attempts_mi_date' => attempt.mi_date,
              'mi_attempt_statuses_description' => attempt.mi_attempt_status.description
            }
            result.push(hash)
          end          
        end
      end

      return result

    end

    def self.get_genes_new_1

      newarray = []
      MiPlanStatus.all_assigned.map { |i| newarray.push(i.id) }

      genes = MiPlan.all(:select => 'gene_id',
      :conditions => "mi_plans.mi_plan_status_id in (" + newarray.join(',').to_s + ")",
      :group => "mi_plans.gene_id having count(*) > 1")

      puts "PLAN COUNT 2: " + genes.size.to_s

      result = []

      genes.each do |gene_id|
        gene = Gene.find(gene_id['gene_id'])

        gene.mi_plans.each do |plan|
          hash = {
            'marker_symbol' => gene.marker_symbol,
            'mi_plan_statuses_name' => plan.mi_plan_status.name,
            #          'centres_name' => plan.production_centre.name.length > 0 ? plan.production_centre.name : 'NONE',
            'centres_name' => plan.production_centre.name,
            'consortia_name' => plan.consortium.name,
            'mi_attempts_mi_date' => plan.mi_attempts.size > 0 ? plan.mi_attempts[plan.mi_attempts.size-1].mi_date : nil,
            'mi_attempt_statuses_description' => plan.mi_attempts.size > 0 ? plan.mi_attempts[plan.mi_attempts.size-1].mi_attempt_status.description : nil
          }
          result.push(hash)
        end
      end

      return result

    end

    def self.get_genes_new

      result = get_genes_new_1

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

      #puts "TEST COUNT 2: " + result.size.to_s
      #puts "result.inspect: " + result.inspect

      return genes

    end

    def self.get_matrix

      genes = get_genes
      cons_matrix = get_consortia_matrix(genes)

      columns = get_matrix_columns
      columns.unshift('')

      report = Table( columns )
      matrix = []

      columns.shift

      rows = 0
      CONSORTIA.each do |row1|
        cols = 0
        matrix[rows] ||= []
        matrix[rows][0] = columns[rows]
        CONSORTIA.each do |row2|
          cols += 1
          if cols-1 <= rows  # skip duplicate rows
            matrix[rows][cols] = ''
            next
          end
          genes_in_overlap = cons_matrix[row1] && cons_matrix[row1][row2] ? cons_matrix[row1][row2] : []
          matrix[rows][cols] = genes_in_overlap && genes_in_overlap.count != 0 ? genes_in_overlap.count : ''
        end
        report << matrix[rows]
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

      genes = get_genes

      report = Table( get_list_columns )

      CONSORTIA.each do |consortium|
        group_heading = "DOUBLE-ASSIGNMENTS FOR consortium: #{consortium}"
        genes.each_pair do |marker, value|
          consortia_for_gene = value.keys
          array = consortia_for_gene.grep(/^#{consortium}$/)
          next if ! array || array.size < 1
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
        report << [group_heading, '', '', '', '', '', '', '', ''] # make blank lines between groups
      end

      report = Grouping( report, :by => 'Target Consortium', :order => 'Marker Symbol' )

      return report

    end

  end

end
