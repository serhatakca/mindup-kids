var SECRET = '';

function jsonOut(obj, cb) {
  var txt = JSON.stringify(obj);
  if (cb) {
    return ContentService.createTextOutput(cb + '(' + txt + ')').setMimeType(ContentService.MimeType.JAVASCRIPT);
  }
  return ContentService.createTextOutput(txt).setMimeType(ContentService.MimeType.JSON);
}

function handleReq(req) {
  if (SECRET && req.secret !== SECRET) {
    return { ok: false, error: 'Yetkisiz istek' };
  }
  var cal = (req.calendarId && req.calendarId !== 'primary')
    ? CalendarApp.getCalendarById(req.calendarId)
    : CalendarApp.getDefaultCalendar();
  if (!cal) return { ok: false, error: 'Takvim bulunamadi' };
  var tz = cal.getTimeZone() || Session.getScriptTimeZone();

  if (req.action === 'sync') {
    var startWin = Utilities.parseDate(req.minDate + ' 00:00', tz, 'yyyy-MM-dd HH:mm');
    var endWin = Utilities.parseDate(req.maxDate + ' 23:59', tz, 'yyyy-MM-dd HH:mm');
    var rawEvents = cal.getEvents(startWin, endWin);
    var events = [];
    for (var i = 0; i < rawEvents.length; i++) {
      var ev = rawEvents[i];
      var allDay = ev.isAllDayEvent();
      var st = ev.getStartTime();
      var en = ev.getEndTime();
      var dur = allDay ? 60 : Math.max(15, Math.round((en.getTime() - st.getTime()) / 60000));
      events.push({
        gcalId: ev.getId(),
        mindupId: ev.getTag('mindupId') || '',
        title: ev.getTitle() || '',
        description: ev.getDescription() || '',
        date: Utilities.formatDate(st, tz, 'yyyy-MM-dd'),
        time: allDay ? '09:00' : Utilities.formatDate(st, tz, 'HH:mm'),
        duration: dur,
        allDay: allDay,
        updated: ev.getLastUpdated().toISOString()
      });
    }
    return { ok: true, events: events };
  }

  if (req.action === 'upsert') {
    var s = req.session || {};
    var start = Utilities.parseDate(s.date + ' ' + (s.time || '09:00'), tz, 'yyyy-MM-dd HH:mm');
    var end = new Date(start.getTime() + (Number(s.duration) || 60) * 60000);
    var ev = null;
    if (s.gcalId) { try { ev = cal.getEventById(s.gcalId); } catch (x) {} }
    if (ev) {
      ev.setTitle(s.title || 'MindUp Seans');
      ev.setTime(start, end);
      ev.setDescription(s.description || '');
    } else {
      ev = cal.createEvent(s.title || 'MindUp Seans', start, end, { description: s.description || '' });
    }
    if (s.id) ev.setTag('mindupId', String(s.id));
    if (s.status === 'tamamlandı') ev.setColor(CalendarApp.EventColor.GREEN);
    else if (s.status === 'iptal') ev.setColor(CalendarApp.EventColor.GRAY);
    else ev.setColor(CalendarApp.EventColor.PALE_BLUE);
    return { ok: true, gcalId: ev.getId(), updated: ev.getLastUpdated().toISOString() };
  }

  if (req.action === 'delete') {
    if (req.gcalId) {
      try {
        var delEv = cal.getEventById(req.gcalId);
        if (delEv) delEv.deleteEvent();
      } catch (x) {}
    }
    return { ok: true };
  }

  return { ok: false, error: 'Bilinmeyen islem' };
}

function doGet(e) {
  var p = (e && e.parameter) || {};
  if (p.payload) {
    try {
      return jsonOut(handleReq(JSON.parse(p.payload)), p.callback);
    } catch (err) {
      return jsonOut({ ok: false, error: String(err && err.message ? err.message : err) }, p.callback);
    }
  }
  return jsonOut({ ok: true, msg: 'MindUp Google Takvim Koprusu aktif.' }, p.callback);
}

function doPost(e) {
  try {
    var raw = (e && e.postData && e.postData.contents) ? e.postData.contents : '{}';
    return jsonOut(handleReq(JSON.parse(raw)));
  } catch (err) {
    return jsonOut({ ok: false, error: String(err && err.message ? err.message : err) });
  }
}
