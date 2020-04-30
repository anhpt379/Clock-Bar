var Calendar = Application('com.apple.iCal');

function findEvent(id) {
    for (var i = 0; i < Calendar.calendars.length; ++i) {
        var calendar = Calendar.calendars.at(i);
        var event = calendar.events.byId(id);
        if (event) {
            return event;
        }
    }
}

function showDate(date) {
    Calendar.viewCalendar({at: date});
}

function showEventOrDate(event, date) {
    var event = findEvent(event);
    if (event && !event.recurrence())
        event.show();
    else
        showDate(date);
}

//showEvent('local_C27ECEB2-E8D2-47B8-B1B1-EB40472F3CAE')
