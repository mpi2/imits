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

function toggleMiAttemptsSwitchViewButton(button, pressed) {
    if(!pressed) {return;}

    switch(button.id) {
        case 'view-everything':
            console.log('Viewing EVERYTHING');
            break;

        case 'view-transfer-details':
            console.log('Viewing details of transfer');
            break;
    }
}
