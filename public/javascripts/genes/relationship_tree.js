Ext.onReady(function () {
    var tree = Ext.create('Imits.widget.GeneRelationshipTree', {
        renderTo: 'relationship-tree'
    });

    var bucketStoreData = [];

    Ext.Array.each(window.CONSORTIA, function (consortium) {
        bucketStoreData.push({type: 'Consortia', name: consortium});
    });

    Ext.Array.each(window.CENTRES, function (centre) {
        bucketStoreData.push({type: 'Centres', name: centre});
    });

    var bucketStore = Ext.create('Ext.data.Store', {
        fields:['type', 'name'],
        groupField: 'type',
        data: bucketStoreData
    });


    var groupingFeature = Ext.create('Ext.grid.feature.Grouping', {
        hideGroupedHeader: false,
        startCollapsed: true,
        id: 'bucket-grouping'
    });

    var bucket = Ext.create('Imits.widget.Grid', {
        renderTo: 'consortium-centre-bucket',
        store: bucketStore,
        features: [groupingFeature],
        title: '&nbsp;',
        columns: [
            {header: 'Name', dataIndex: 'name', flex: 1}
        ]
    });

    Ext.EventManager.onWindowResize(tree.manageResize, tree);
    Ext.EventManager.onWindowResize(bucket.manageResize, bucket);
    bucket.manageResize();
});
