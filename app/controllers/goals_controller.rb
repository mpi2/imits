# encoding: utf-8

class GoalsController < ApplicationController
  respond_to :html, :only => [:gene_selection]
  respond_to :json, :except => [:show, :update, :destroy]
  before_filter :authenticate_user!

  def index
    centre = Centre.find_by_name(params[:centre_name])
    date_sql_condition = ''
    start_date = params[:start_date]
    end_date = params[:end_date]

    @grants = {}
    dates = []

    unless start_date.blank? && end_date.blank?
      date_sql_condition << " AND (grants.commence >= '#{start_date}' OR grants.end >= '#{start_date}')" unless start_date.blank?
      date_sql_condition << " AND (grants.commence <= '#{end_date}' OR grants.end <= '#{end_date}') " unless end_date.blank?
    end

    grants_info = Grant.where("production_centre_id = #{centre.id} #{date_sql_condition}").order("grants.commence, grants.end")

    if !grants_info.blank?
      grant_start_date = grants_info.map{|g| g.commence.beginning_of_month}.min
      grant_end_date = grants_info.map{|g| g.end.beginning_of_month}.max

      date_range = [grant_start_date, grant_end_date]
      if start_date.blank?
        date_range[0] = start_date.to_datetime.beginning_of_month
      end

      if end_date.blank?
        date_range[1] = end_date.to_datetime.beginning_of_month
      end

      dates = []
      i = date_range[0]
      while i <= date_range[1]
        dates << i
        i = i.next_month
      end

      @dates = (date_range[0].to_i..date_range[1].to_i).step(1.month).map{|int_date| Time.at(int_date)}

      grants_info.each do |grant|
        @grants[grant] = format_hash(grant)
      end
    end

  dates = []
  i = '2015/12/01'.to_date
  while i <= '2016/12/01'.to_date
    dates << i
    i = i.next_month
  end

  @dates = {}
  dates.map{|a| a.year}.uniq.each do |year|
    @dates[year] = []
  end

  dates.each do |d|
    @dates[d.year] << d.month
  end

  @grants = {
    Grant.new(:name => 'TCP-KOMP2',
            :funding => 'NIH',
            :consortium_name => 'DTCC',
            :production_centre_name => 'TCP',
            :commence => '01/01/2016'.to_date,
            :end => '31/12/2016'.to_date,
            :grant_goal => 400) =>

{'crispr_mi_goal' => {2016 => {1 => 0,
                               2 => 80,
                               3 => 120,
                               4 => 150,
                               5 => 180,
                               6 => 220,
                               7 => 260,
                               8 => 280,
                               9 => 300,
                               10 => 360,
                               11 => 380,
                               12 => 400
                              }
                      },
'crispr_gc_goal' => {2016 => { 1 => 0,
                               2 => 80,
                               3 => 120,
                               4 => 150,
                               5 => 180,
                               6 => 220,
                               7 => 260,
                               8 => 280,
                               9 => 300,
                               10 => 360,
                               11 => 380,
                               12 => 400
                              }
                      },
'es_cell_mi_goal' => {2016 => {1 => 0, 
                               2 => 0,
                               3 => 0,
                               4 => 0,
                               5 => 0,
                               6 => 0,
                               7 => 0,
                               8 => 0,
                               9 => 0,
                               10 => 0,
                               11 => 0,
                               12 => 0
                              }
                      },
'es_cell_gc_goal' => {2016 => {1 => 0, 
                               2 => 0,
                               3 => 0,
                               4 => 0,
                               5 => 0,
                               6 => 0,
                               7 => 0,
                               8 => 0,
                               9 => 0,
                               10 => 0,
                               11 => 0,
                               12 => 0
                              }
                      },
'total_mi_goal' => {2016 => {  1 => 0,
                               2 => 80,
                               3 => 120,
                               4 => 150,
                               5 => 180,
                               6 => 220,
                               7 => 260,
                               8 => 280,
                               9 => 300,
                               10 => 360,
                               11 => 380,
                               12 => 400
                              }
                      },
'total_gc_goal' => {2016 => {  1 => 0,
                               2 => 80,
                               3 => 120,
                               4 => 150,
                               5 => 180,
                               6 => 220,
                               7 => 260,
                               8 => 280,
                               9 => 300,
                               10 => 360,
                               11 => 380,
                               12 => 400
                              }
                      },
'excision_goal' => {2016 => {1 => 0, 
                               2 => 0,
                               3 => 0,
                               4 => 0,
                               5 => 0,
                               6 => 0,
                               7 => 0,
                               8 => 0,
                               9 => 0,
                               10 => 0,
                               11 => 0,
                               12 => 0
                              }
                      },
'phenotype_goal' => {2016 => { 1 => 0, 
                               2 => 0,
                               3=> 80,
                               4=> 120,
                               5=> 150,
                               6=> 180,
                               7=> 220,
                               8=> 260,
                               9=> 280,
                               10=> 300,
                               11=> 360,
                               12=> 400 
                              }
                      }
 },

     Grant.new(            :name => 'TCP-NORCOMM',
             :funding => 'NORCOMM',
             :consortium_name => 'NORCOMM',
             :production_centre_name => 'TCP',
             :commence => '01/05/2016'.to_date,
             :end => '31/07/2016'.to_date,
             :grant_goal => 200) => 

 {'crispr_mi_goal' => {2016 => {5 => 0,
                                6 => 0,
                                7 => 0,
                                8 => 0
                               }
                       },
 'crispr_gc_goal' => {2016 => { 5 => 0,
                                6 => 0,
                                7 => 0,
                                8 => 0
                               }
                       },
 'es_cell_mi_goal' => {2016 => {5 => 0,
                                6 => 50,
                                7 => 100,
                                8 => 200
                               }
                       },
 'es_cell_gc_goal' => {2016 => {5 => 0,
                                6 => 10,
                                7 => 75,
                                8 => 150
                               }
                       },
 'total_mi_goal' => {2016 => {  5 => 0,
                                6 => 50,
                                7 => 100,
                                8 => 200
                               }
                       },
 'total_gc_goal' => {2016 => {  5 => 0,
                                6 => 10,
                                7 => 75,
                                8 => 150
                               }
                       },
 'excision_goal' => {2016 => {5 => 0,
                                6 => 2,
                                7 => 20,
                                8 => 150
                               }
                       },
 'phenotype_goal' => {2016 => {5=> 0,
                                6=> 0,
                                7=> 75,
                                8=> 150
                               }
                       }
}
}
  end

  def update
    
  end

  def show
    
  end

  def destroy
  end

  def format_hash (grant)
    grant_hash = {
        'crispr_mi_goal'  =>  {},
        'crispr_gc_goal'  =>  {},
        'es_cell_mi_goal' =>  {},
        'es_cell_gc_goal' =>  {},
        'total_mi_goal'   =>  {},
        'total_gc_goal'   =>  {},
        'excision_goal'   =>  {},
        'phenotype_goal'  =>  {}
    }

    grant.goals.each do |goal|
      grant_hash['crispr_mi_goal'][goal.year][goal.month] = goal.crispr_mi_goal
      grant_hash['crispr_gc_goal'][goal.year][goal.month] = goal.crispr_gc_goal
      grant_hash['es_cell_mi_goal'][goal.year][goal.month] = goal.es_cell_mi_goal
      grant_hash['es_cell_gc_goal'][goal.year][goal.month] = goal.es_cell_gc_goal
      grant_hash['total_mi_goal'][goal.year][goal.month] = goal.total_mi_goal
      grant_hash['total_gc_goal'][goal.year][goal.month] = goal.total_gc_goal
      grant_hash['excision_goal'][goal.year][goal.month] = goal.excision_goal
      grant_hash['phenotype_goal'][goal.year][goal.month] = goal.phenotype_goal
    end
    
    return grant_hash
  end
  private :format_hash

end
