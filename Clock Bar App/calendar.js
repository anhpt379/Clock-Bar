var Calendar = Application('com.apple.iCal');

function showEvent(id) {
    for (var i = 0; i < Calendar.calendars.length; ++i) {
        var calendar = Calendar.calendars.at(i);
        var event = calendar.events.byId(id);
        if (event) {
            event.show();
            return;
        }
    }
}

//showEvent('local_C27ECEB2-E8D2-47B8-B1B1-EB40472F3CAE')
