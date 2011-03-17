window.onload = onWindowLoad;

function onWindowLoad() {
    var things = getElementsByClassName('initial-focus');
    var thing = things[0];
    if(thing) {
        thing.focus();
    }
}
