get_intervals = function(){
    return $('.time_interval').map(function() {
        return $(this).attr('data_interval');
    });
}

get_graph_data_series = function(){
    var all_data =  $('.graph_data');
    var graph_data = [];
    var i=0;
    var number_of_data_points = get_intervals().length
    while (true){
        if (i+number_of_data_points <= all_data.length){
            var g_d = {grant_name: $(all_data[i]).attr('data_grant_name'), data_type: $(all_data[i]).attr('data_type')};
            g_d['data'] = all_data.slice(i, i + number_of_data_points ).map(function(){return Number($(this).attr('data_cumulative_value'));});
            graph_data.push(g_d);
            i = i+number_of_data_points;
        }
        else {
            break;
        }
    }
    return graph_data;
}

stacked_graph_data = function(){
    var graph_data = [];
    var series_options = {};
    var data = get_graph_data_series();
    var re = /otal/;
    data.forEach(function(data_row){
        if (re.test(data_row['data_type'])){
            return;
        }
        graph_data.push({name: data_row['grant_name'], stack: data_row['data_type'], data: data_row['data']})
    })

    graph_data.forEach(function(data_row){
        new_data = []
        for (i = 0; i < data_row['data'].length; i++) { 
            if (i == 0) {new_data.push(0); continue;};
            new_data.push(data_row['data'][i] - data_row['data'][i - 1]);
        }
        data_row['data'] = new_data
    })

    graph_data.forEach(function(data_row){
        if (series_options[data_row['name']]  == undefined){
            series_options[data_row['name']] = {color:'d', linkedTo: data_row['name']}
        }
    })

    return graph_data;
}

graph_data_grouped_by_data_type = function(){
    var grouped_graph_data = {};
    var data = get_graph_data_series();
    data.forEach(function(data_row){
        if (grouped_graph_data[data_row['data_type']] == undefined){
            grouped_graph_data[data_row['data_type']] = {name: data_row['data_type']};
            grouped_graph_data[data_row['data_type']]['data'] = data_row['data'];

        }
        else {
            for (i=0; i < grouped_graph_data[data_row['data_type']]['data'].length; i++) {
                grouped_graph_data[data_row['data_type']]['data'][i] = grouped_graph_data[data_row['data_type']]['data'][i] + data_row['data'][i];
            }
        }

    })
    delete grouped_graph_data['crispr_mi_goal'];
    delete grouped_graph_data['crispr_gc_goal'];
    delete grouped_graph_data['es_cell_mi_goal'];
    delete grouped_graph_data['es_cell_gc_goal'];
    
    
    return Object.keys(grouped_graph_data).map(function(q){return grouped_graph_data[q];})
}

line_graph_monthly_goals = function () {
    if ( $('#line_graph_monthly_goals').length == 0 ){return;}
    $('#line_graph_monthly_goals').highcharts({
        title: {
            text: 'Cumulative Production Goals by Month',
            x: -20 //center
        },
        xAxis: {
            categories: get_intervals()
        },
        yAxis: {
            title: {
                text: 'Number of genes'
            },
            plotLines: [{
                value: 0,
                width: 1,
                color: '#808080'
            }]
        },
        tooltip: {
            valueSuffix: ' Genes'
        },
        legend: {
            layout: 'vertical',
            align: 'right',
            verticalAlign: 'middle',
            borderWidth: 0
        },
        series: graph_data_grouped_by_data_type()
    });
};

column_graph_monthly_goal_counts = function () {
    if ( $('#column_graph_monthly_goal_counts').length == 0 ){return;}
    $('#column_graph_monthly_goal_counts').highcharts({
        chart: {
            type: 'column',
            height: 200,
        },
        title: {
            text: 'Monthly Production Goals'
        },
        xAxis: {
            categories: get_intervals(),
            crosshair: true
        },
        yAxis: {
            min: 0,
            title: {
                text: 'Number of genes'
            }
        },
        tooltip: {
            formatter: function () {
                return '<b>' +  this.series.options.stack + ' for ' + this.x.slice(0, -2) + '20' + this.x.slice(-2, this.x.length) + '</b><br/>' +
                    this.series.name + ': ' + this.y + '<br/>' +
                    'Total: ' + this.point.stackTotal;
            }
        },
        plotOptions: {
            column: {
                groupPadding: 0.05,
                pointPadding: 0.2,
                borderWidth: 0,
                stacking: 'normal'
            }

        },
        legend: {
            layout: 'vertical',
            align: 'right',
            verticalAlign: 'middle',
            borderWidth: 0
        },
        series: stacked_graph_data()
    });
};