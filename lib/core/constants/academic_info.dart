/// Academic identifiers that are proper nouns, not translatable copy.
///
/// The report asks for the same English wording in both app languages: the
/// program and department names must not change when the UI switches to
/// Indonesian. Keeping them as plain constants (instead of duplicating the
/// value into `app_en.arb` and `app_id.arb`) means there is a single place they
/// can drift from, and it mirrors how the DB stores `materials` base columns in
/// one language rather than translating a name.
library;

/// The study program ("Program Studi") shown on the student Academic
/// Information page and under the dashboard greeting.
const String kStudyProgramName = 'Information Technology Education';

/// The department ("Jurusan") shown on the student Academic Information page.
const String kDepartmentName = 'Informatics Engineering';
