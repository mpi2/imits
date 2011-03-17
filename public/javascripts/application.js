window.onload = onWindowLoad;

function onWindowLoad() {
    setInitialFocus();
}

function setInitialFocus() {
    var thing = getElementsByClassName('initial-focus')[0];
    if(thing) {
        thing.focus();
    }
}
