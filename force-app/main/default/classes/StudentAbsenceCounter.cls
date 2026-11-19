/*****************************************************************
Name:          StudentAbsenceCounter
============================================================
Purpose:       Invocable action for the nightly scoring flow
               (SCH – Score First Year Students, SCA-9). Returns the
               number of Absent attendance entries for each student
               on or after a window start date.
               Why Apex: Flow cannot use AttendanceEntry in this org
               ("Entity is not accessible: AttendanceEntry"), while
               SOQL from Apex can. This is the single exception to the
               Flow-first rule, recorded as ADR-012. All scoring logic
               stays in the flow; this class only counts.
               Runs without sharing and in system mode because it is
               called by a scheduled (system-context) flow and returns
               counts only, never record data.
============================================================
History
-------
VERSION  AUTHOR                  DATE         DETAIL    DESCRIPTION
1.0      Revecast Orchestrate    19/11/2026   Created   SCA-9 / ADR-012
*****************************************************************/
public without sharing class StudentAbsenceCounter {

    // The attendance status that counts as a missed class (Tardy does not count).
    @TestVisible
    private static final String ABSENT_STATUS = 'Absent';

    /*****************************************************************
    Purpose: One input per flow interview: the student and the first
             day of the missed-class window.
    *****************************************************************/
    public class Request {
        @InvocableVariable(label='Student Contact Id' description='The student Contact (AttendanceEntry.WhoId).' required=true)
        public Id studentId;

        @InvocableVariable(label='Window Start Date' description='Count absences on or after this date.' required=true)
        public Date windowStart;
    }

    /*****************************************************************
    Purpose: One output per flow interview, in the same order as the
             requests.
    *****************************************************************/
    public class Result {
        @InvocableVariable(label='Absence Count' description='Absent attendance entries in the window.')
        public Integer absenceCount;
    }

    /*****************************************************************
    Purpose:    Counts Absent entries per student. Salesforce passes the
                requests of a whole batch of flow interviews (up to 200)
                in one call, so this runs ONE query per batch and no
                query or DML inside a loop.
    Parameters: requests - one per flow interview
    Returns:    one Result per request, same order
    *****************************************************************/
    @InvocableMethod(label='Count Student Absences'
        description='Counts Absent attendance entries per student since a window start date. Used by the nightly risk scorer (SCA-9).'
        category='Student Concern Agent')
    public static List<Result> countAbsences(List<Request> requests) {
        System.debug('Entering StudentAbsenceCounter.countAbsences: ' + (requests == null ? 0 : requests.size()) + ' requests');
        List<Result> results = new List<Result>();
        if (requests == null || requests.isEmpty()) {
            return results;
        }

        // Collect the students and the earliest window so a single query covers every request.
        Set<Id> studentIds = new Set<Id>();
        Date earliestStart = null;
        for (Request request : requests) {
            if (request != null && request.studentId != null && request.windowStart != null) {
                studentIds.add(request.studentId);
                if (earliestStart == null || request.windowStart < earliestStart) {
                    earliestStart = request.windowStart;
                }
            }
        }

        // Absence dates per student. Each request applies its own window to these dates below,
        // so requests with different windows in the same batch still get exact counts.
        Map<Id, List<Date>> absenceDatesByStudent = new Map<Id, List<Date>>();
        if (!studentIds.isEmpty()) {
            for (AttendanceEntry entry : [
                SELECT WhoId, AttendanceDate
                FROM AttendanceEntry
                WHERE WhoId IN :studentIds
                    AND Status = :ABSENT_STATUS
                    AND AttendanceDate >= :earliestStart
                WITH SYSTEM_MODE
            ]) {
                if (!absenceDatesByStudent.containsKey(entry.WhoId)) {
                    absenceDatesByStudent.put(entry.WhoId, new List<Date>());
                }
                absenceDatesByStudent.get(entry.WhoId).add(entry.AttendanceDate);
            }
        }

        // Build the results in request order; a missing or incomplete request counts as 0.
        for (Request request : requests) {
            Result result = new Result();
            result.absenceCount = 0;
            if (request != null && request.studentId != null && request.windowStart != null
                    && absenceDatesByStudent.containsKey(request.studentId)) {
                for (Date absenceDate : absenceDatesByStudent.get(request.studentId)) {
                    if (absenceDate != null && absenceDate >= request.windowStart) {
                        result.absenceCount++;
                    }
                }
            }
            results.add(result);
        }

        System.debug('Exiting StudentAbsenceCounter.countAbsences: ' + results.size() + ' results');
        return results;
    }
}
