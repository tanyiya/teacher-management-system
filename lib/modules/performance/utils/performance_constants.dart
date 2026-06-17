const double kpiBaselineScore = 100.0;

const List<String> warningTypes = [
  'Verbal Warning',
  'Written Warning',
  'Final Warning',
  'Critical Alert',
];

const Map<String, List<String>> performanceCategories = {
  'Attendance and Punctuality': [
    'Arrives at school on time',
    'Comes prepared before class starts',
    'Follow attendance procedures',
    'Submit leave application properly',
    'Has good attendance record',
  ],
  'Classroom Management': [
    'Classroom is clean and organised',
    'Students are well managed',
    'Learning corners are updated',
    'Safety rules are followed',
    'Students line up properly',
  ],
  'Teaching Performance': [
    'Lesson plan prepared on time',
    'Lesson plan submitted on time',
    'Teaching follows lesson plan',
    'Uses teaching aid effectively',
    'Explains lesson clearly',
    'Students are engaged during class',
  ],
  'Student Development': [
    'Tracks student progress',
    'Help weak students',
    'Encourages student participation',
    'Maintains student discipline positively',
    'Gives motivation and encouragement',
  ],
  'Documentation and Record Keeping': [
    'Students file updated',
    'Attendance records complete',
    'Assessment record submitted on time',
    'Portfolio/student’s work organised',
  ],
  'Communication and Professionalism': [
    'Speaks politely to students, parents and colleagues',
    'Responds professionally in WhatsApp groups',
    'Works well with team members',
    'Accept feedback positively',
    'Maintains professional appearance',
  ],
  'Task & Duty Responsibility': [
    'Follow assembly duty schedules',
    'Follow cleaning duty schedule',
    'Completes arrival and dismissal duty',
    'Helps during school events',
  ],
  'Creativity and Initiative': [
    'Creates attractive teaching materials',
    'Gives new activity ideas',
    'Participates in school improvement',
    'Decorate classroom creatively',
    'Takes initiative without waiting for instruction',
  ],
  'Training and Self Development': [
    'Attend required training (minimum 3 per year)',
    'Applies knowledge from training',
    'Shares learning with team',
    'Improves teaching skills',
  ],
  'Discipline and SOP Compliance': [
    'Follow school SOP',
    'Uses appropriate language',
    'Follow dress code',
    'Maintains confidentiality',
    'Uses social media professionally',
  ],
};
