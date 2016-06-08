load_goals = function(){
    if ( $('#goal_data').length == 0 ){return;}

    $('#goal_data').load('goals/get_goal_data', function(){
    //    line_graph_monthly_goals();
     //   column_graph_monthly_goal_counts();
    })
}

$(function () {
     
    var grid = Ext.create('Imits.widget.GrantGoalsGrid', {
        renderTo: 'grant_list'
    });
    Ext.EventManager.onWindowResize(grid.manageResize, grid);
    grid.manageResize();

    load_goals();
});