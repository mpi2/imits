Ext.onReady(function() {
    function patches_for_4_0_7() {
    }

    var extvers = [Ext.versions.core.major, Ext.versions.core.minor, Ext.versions.core.patch];

    if(extvers[0] != 4 || extvers[1] != 0) {
        return;
    }

    if(extvers[2] <= 7) {
        patches_for_4_0_7();
    }
});
