import 'package:cloud_firestore/cloud_firestore.dart';

class MentorshipSession {
  final String id;
  final String mentorId;
  final String menteeId; // UID or "manual:..." string
  final String menteeName;
  final DateTime date;
  final String? notes;
  final bool isCompleted;
  final String? meetLink;
  final String? googleEventId;

  MentorshipSession({
    required this.id,
    required this.mentorId,
    required this.menteeId,
    required this.menteeName,
    required this.date,
    this.notes,
    this.isCompleted = false,
    this.meetLink,
    this.googleEventId,
  });

  factory MentorshipSession.fromMap(Map<String, dynamic> data, String id) {
    return MentorshipSession(
      id: id,
      mentorId: data['mentorId'] ?? '',
      menteeId: data['menteeId'] ?? '',
      menteeName: data['menteeName'] ?? 'Desconegut',
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'],
      isCompleted: data['isCompleted'] ?? false,
      meetLink: data['meetLink'],
      googleEventId: data['googleEventId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mentorId': mentorId,
      'menteeId': menteeId,
      'menteeName': menteeName,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'isCompleted': isCompleted,
      'meetLink': meetLink,
      'googleEventId': googleEventId,
    };
  }

  MentorshipSession copyWith({
    String? id,
    String? mentorId,
    String? menteeId,
    String? menteeName,
    DateTime? date,
    String? notes,
    bool? isCompleted,
  }) {
    return MentorshipSession(
      id: id ?? this.id,
      mentorId: mentorId ?? this.mentorId,
      menteeId: menteeId ?? this.menteeId,
      menteeName: menteeName ?? this.menteeName,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
