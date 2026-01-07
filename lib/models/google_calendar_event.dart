import 'package:json_annotation/json_annotation.dart';

part 'google_calendar_event.g.dart';

@JsonSerializable()
class GoogleCalendarEvent {
  final String? id;
  final String? summary;
  final String? description;
  final String? location;
  final GoogleCalendarDateTime? start;
  final GoogleCalendarDateTime? end;
  final List<GoogleCalendarAttendee>? attendees;
  final GoogleCalendarReminders? reminders;
  final String? status;
  final String? htmlLink;
  final DateTime? created;
  final DateTime? updated;
  final GoogleCalendarPerson? creator;
  final GoogleCalendarPerson? organizer;
  final bool? guestsCanModify;
  final bool? guestsCanInviteOthers;
  final bool? guestsCanSeeOtherGuests;

  GoogleCalendarEvent({
    this.id,
    this.summary,
    this.description,
    this.location,
    this.start,
    this.end,
    this.attendees,
    this.reminders,
    this.status,
    this.htmlLink,
    this.created,
    this.updated,
    this.creator,
    this.organizer,
    this.guestsCanModify,
    this.guestsCanInviteOthers,
    this.guestsCanSeeOtherGuests,
  });

  factory GoogleCalendarEvent.fromJson(Map<String, dynamic> json) => _$GoogleCalendarEventFromJson(json);
  Map<String, dynamic> toJson() => _$GoogleCalendarEventToJson(this);

  GoogleCalendarEvent copyWith({
    String? id,
    String? summary,
    String? description,
    String? location,
    GoogleCalendarDateTime? start,
    GoogleCalendarDateTime? end,
    List<GoogleCalendarAttendee>? attendees,
    GoogleCalendarReminders? reminders,
    String? status,
    String? htmlLink,
    DateTime? created,
    DateTime? updated,
    GoogleCalendarPerson? creator,
    GoogleCalendarPerson? organizer,
    bool? guestsCanModify,
    bool? guestsCanInviteOthers,
    bool? guestsCanSeeOtherGuests,
  }) {
    return GoogleCalendarEvent(
      id: id ?? this.id,
      summary: summary ?? this.summary,
      description: description ?? this.description,
      location: location ?? this.location,
      start: start ?? this.start,
      end: end ?? this.end,
      attendees: attendees ?? this.attendees,
      reminders: reminders ?? this.reminders,
      status: status ?? this.status,
      htmlLink: htmlLink ?? this.htmlLink,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      creator: creator ?? this.creator,
      organizer: organizer ?? this.organizer,
      guestsCanModify: guestsCanModify ?? this.guestsCanModify,
      guestsCanInviteOthers: guestsCanInviteOthers ?? this.guestsCanInviteOthers,
      guestsCanSeeOtherGuests: guestsCanSeeOtherGuests ?? this.guestsCanSeeOtherGuests,
    );
  }
}

@JsonSerializable()
class GoogleCalendarDateTime {
  final DateTime? dateTime;
  final String? date;
  final String? timeZone;

  GoogleCalendarDateTime({
    this.dateTime,
    this.date,
    this.timeZone,
  });

  factory GoogleCalendarDateTime.fromJson(Map<String, dynamic> json) => _$GoogleCalendarDateTimeFromJson(json);
  Map<String, dynamic> toJson() => _$GoogleCalendarDateTimeToJson(this);

  GoogleCalendarDateTime copyWith({
    DateTime? dateTime,
    String? date,
    String? timeZone,
  }) {
    return GoogleCalendarDateTime(
      dateTime: dateTime ?? this.dateTime,
      date: date ?? this.date,
      timeZone: timeZone ?? this.timeZone,
    );
  }
}

@JsonSerializable()
class GoogleCalendarAttendee {
  final String? email;
  final String? displayName;
  final bool? organizer;
  final bool? self;
  final String? responseStatus; // needsAction, declined, tentative, accepted

  GoogleCalendarAttendee({
    this.email,
    this.displayName,
    this.organizer,
    this.self,
    this.responseStatus,
  });

  factory GoogleCalendarAttendee.fromJson(Map<String, dynamic> json) => _$GoogleCalendarAttendeeFromJson(json);
  Map<String, dynamic> toJson() => _$GoogleCalendarAttendeeToJson(this);

  GoogleCalendarAttendee copyWith({
    String? email,
    String? displayName,
    bool? organizer,
    bool? self,
    String? responseStatus,
  }) {
    return GoogleCalendarAttendee(
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      organizer: organizer ?? this.organizer,
      self: self ?? this.self,
      responseStatus: responseStatus ?? this.responseStatus,
    );
  }
}

@JsonSerializable()
class GoogleCalendarReminders {
  final bool? useDefault;
  final List<GoogleCalendarReminderOverride>? overrides;

  GoogleCalendarReminders({
    this.useDefault,
    this.overrides,
  });

  factory GoogleCalendarReminders.fromJson(Map<String, dynamic> json) => _$GoogleCalendarRemindersFromJson(json);
  Map<String, dynamic> toJson() => _$GoogleCalendarRemindersToJson(this);

  GoogleCalendarReminders copyWith({
    bool? useDefault,
    List<GoogleCalendarReminderOverride>? overrides,
  }) {
    return GoogleCalendarReminders(
      useDefault: useDefault ?? this.useDefault,
      overrides: overrides ?? this.overrides,
    );
  }
}

@JsonSerializable()
class GoogleCalendarReminderOverride {
  final String? method; // email, popup
  final int? minutes;

  GoogleCalendarReminderOverride({
    this.method,
    this.minutes,
  });

  factory GoogleCalendarReminderOverride.fromJson(Map<String, dynamic> json) => _$GoogleCalendarReminderOverrideFromJson(json);
  Map<String, dynamic> toJson() => _$GoogleCalendarReminderOverrideToJson(this);

  GoogleCalendarReminderOverride copyWith({
    String? method,
    int? minutes,
  }) {
    return GoogleCalendarReminderOverride(
      method: method ?? this.method,
      minutes: minutes ?? this.minutes,
    );
  }
}

@JsonSerializable()
class GoogleCalendar {
  final String? id;
  final String? summary;
  final String? description;
  final String? location;
  final String? timeZone;
  final String? accessRole;
  final bool? primary;
  final bool? selected;
  final String? backgroundColor;
  final String? foregroundColor;
  final bool? hidden;
  final bool? deleted;

  GoogleCalendar({
    this.id,
    this.summary,
    this.description,
    this.location,
    this.timeZone,
    this.accessRole,
    this.primary,
    this.selected,
    this.backgroundColor,
    this.foregroundColor,
    this.hidden,
    this.deleted,
  });

  factory GoogleCalendar.fromJson(Map<String, dynamic> json) => _$GoogleCalendarFromJson(json);
  Map<String, dynamic> toJson() => _$GoogleCalendarToJson(this);

  GoogleCalendar copyWith({
    String? id,
    String? summary,
    String? description,
    String? location,
    String? timeZone,
    String? accessRole,
    bool? primary,
    bool? selected,
    String? backgroundColor,
    String? foregroundColor,
    bool? hidden,
    bool? deleted,
  }) {
    return GoogleCalendar(
      id: id ?? this.id,
      summary: summary ?? this.summary,
      description: description ?? this.description,
      location: location ?? this.location,
      timeZone: timeZone ?? this.timeZone,
      accessRole: accessRole ?? this.accessRole,
      primary: primary ?? this.primary,
      selected: selected ?? this.selected,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      hidden: hidden ?? this.hidden,
      deleted: deleted ?? this.deleted,
    );
  }
}

@JsonSerializable()
class GoogleCalendarPerson {
  final String? email;
  final String? displayName;
  final bool? self;

  GoogleCalendarPerson({
    this.email,
    this.displayName,
    this.self,
  });

  factory GoogleCalendarPerson.fromJson(Map<String, dynamic> json) => _$GoogleCalendarPersonFromJson(json);
  Map<String, dynamic> toJson() => _$GoogleCalendarPersonToJson(this);

  GoogleCalendarPerson copyWith({
    String? email,
    String? displayName,
    bool? self,
  }) {
    return GoogleCalendarPerson(
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      self: self ?? this.self,
    );
  }
}
