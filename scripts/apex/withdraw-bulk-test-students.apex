/*****************************************************************
Name:          withdraw-bulk-test-students.apex  (anonymous Apex)
============================================================
Purpose:       After the SCA-9 bulk proof, sets the synthetic bulk-test
               students' term enrollments to Withdrawn so the nightly
               scorer skips them (ADR-014). Deletes nothing; the
               records stay under "DEMO - Bulk Test Students (safe to
               delete)" and can be removed later or re-activated by
               re-running load-bulk-test-students.apex.
============================================================
History
-------
VERSION  AUTHOR                 DATE         DETAIL    DESCRIPTION
1.0      Revecast Orchestrate   19/11/2026   Created   SCA-9 / ADR-014
*****************************************************************/
List<AcademicTermEnrollment> enrollments = [
    SELECT Id FROM AcademicTermEnrollment
    WHERE LearnerContact.Account.Name = 'DEMO - Bulk Test Students (safe to delete)'
        AND EnrollmentStatus != 'Withdrawn'];
for (AcademicTermEnrollment enrollment : enrollments) {
    enrollment.EnrollmentStatus = 'Withdrawn';
}
update enrollments;
System.debug('SCA-9 bulk withdraw complete: ' + enrollments.size() + ' enrollments set to Withdrawn.');
