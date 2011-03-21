window.onload = onWindowLoad;

function onWindowLoad() {
    setInitialFocus();
}

function setInitialFocus() {
    var thing = Ext.DomQuery.jsSelect('.initial-focus')[0];
    if(thing) {
        thing.focus();
    }
}

function switchMiAttemptsGridView(button, event) {
    console.log(button.id);
}
