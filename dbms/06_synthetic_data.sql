-- Deterministic, constraint-valid synthetic fixture for CP4 query benchmarking.
-- Target: a fresh database after dbms/03_schema.sql.
BEGIN;

INSERT INTO "User" ("id", "fullName", "email", "password", "phone", "role", "isActive", "createdAt", "updatedAt")
SELECT 'student-user-' || lpad(g::text, 5, '0'), 'Student ' || g,
       'student' || g || '@example.test', 'benchmark-hash', '+1000' || lpad(g::text, 8, '0'),
       'STUDENT', g % 10 <> 0, CURRENT_TIMESTAMP - (g % 900) * INTERVAL '1 day', CURRENT_TIMESTAMP
FROM generate_series(1, 5000) AS g;

INSERT INTO "User" ("id", "fullName", "email", "password", "phone", "role", "isActive", "createdAt", "updatedAt")
SELECT 'industry-user-' || lpad(g::text, 3, '0'), 'Industry User ' || g,
       'industry' || g || '@example.test', 'benchmark-hash', '+2000' || lpad(g::text, 8, '0'),
       'INDUSTRY', g % 7 <> 0, CURRENT_TIMESTAMP - (g % 500) * INTERVAL '1 day', CURRENT_TIMESTAMP
FROM generate_series(1, 200) AS g;

INSERT INTO "User" ("id", "fullName", "email", "password", "phone", "role", "isActive", "createdAt", "updatedAt")
SELECT 'institution-user-' || lpad(g::text, 3, '0'), 'Institution User ' || g,
       'institution' || g || '@example.test', 'benchmark-hash', '+3000' || lpad(g::text, 8, '0'),
       'INSTITUTION', TRUE, CURRENT_TIMESTAMP - (g % 700) * INTERVAL '1 day', CURRENT_TIMESTAMP
FROM generate_series(1, 50) AS g;

INSERT INTO "User" ("id", "fullName", "email", "password", "phone", "role", "isActive", "createdAt", "updatedAt")
VALUES
 ('admin-user-001','Benchmark Admin','admin@example.test','benchmark-hash','+40000000001','ADMIN',TRUE,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP),
 ('bench-w2-user','Profileless Student','bench-w2@example.test','benchmark-hash','+40000000002','STUDENT',TRUE,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP),
 ('bench-w3-user','New Institution User','bench-w3@example.test','benchmark-hash','+40000000003','INSTITUTION',TRUE,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP),
 ('bench-w4-user','New Company User','bench-w4@example.test','benchmark-hash','+40000000004','INDUSTRY',TRUE,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP);

INSERT INTO "Institution" ("id","userId","name","officialEmail","website","address","description","contactInfo","isVerified","createdAt","updatedAt")
SELECT 'institution-' || lpad(g::text,3,'0'), 'institution-user-' || lpad(g::text,3,'0'),
       'Institute ' || g, 'office' || g || '@institution.example.test',
       'https://institution' || g || '.example.test', 'Campus ' || g, 'Synthetic institution ' || g,
       'contact-' || g, g % 2 = 0, CURRENT_TIMESTAMP - (g % 600) * INTERVAL '1 day', CURRENT_TIMESTAMP
FROM generate_series(1,50) AS g;

INSERT INTO "Company" ("id","userId","name","officialEmail","website","address","description","contactInfo","isVerified","createdAt","updatedAt")
SELECT 'company-' || lpad(g::text,3,'0'), 'industry-user-' || lpad(g::text,3,'0'),
       'Company ' || g, 'office' || g || '@company.example.test',
       'https://company' || g || '.example.test', 'Office ' || g, 'Synthetic company ' || g,
       'contact-' || g, g % 4 <> 0, CURRENT_TIMESTAMP - (g % 500) * INTERVAL '1 day', CURRENT_TIMESTAMP
FROM generate_series(1,200) AS g;

INSERT INTO "StudentProfile" ("id","userId","institutionId","degree","department","graduationYear","semester","bio","profileImage","resumeUrl","linkedIn","github","portfolio","createdAt","updatedAt")
SELECT 'student-profile-' || lpad(g::text,5,'0'),
       'student-user-' || lpad(g::text,5,'0'),
       'institution-' || lpad(((g-1)%50+1)::text,3,'0'),
       CASE WHEN g%2=0 THEN 'B.Tech' ELSE 'B.Sc' END,
       CASE WHEN g%3=0 THEN 'Computer Science' ELSE 'Engineering' END,
       2024 + g%5, 1 + g%8, 'Synthetic profile ' || g,
       NULL, 'https://example.test/resume/' || g,
       'https://example.test/in/' || g, 'https://example.test/gh/' || g,
       NULL, CURRENT_TIMESTAMP - (g%800)*INTERVAL '1 day', CURRENT_TIMESTAMP
FROM generate_series(1,5000) AS g;

INSERT INTO "Skill" ("id","name","category","description","createdAt","updatedAt")
SELECT 'skill-' || lpad(g::text,3,'0'), 'Skill ' || lpad(g::text,3,'0'),
       CASE WHEN g%4=0 THEN 'Data' WHEN g%4=1 THEN 'Engineering' WHEN g%4=2 THEN 'Design' ELSE 'Business' END,
       'Synthetic skill ' || g, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM generate_series(1,100) AS g;

INSERT INTO "Assessment" ("id","skillId","title","description","totalQuestions","createdAt")
SELECT 'assessment-' || lpad(g::text,3,'0'), 'skill-' || lpad(g::text,3,'0'),
       'Assessment ' || g, 'Synthetic assessment ' || g, 5, CURRENT_TIMESTAMP
FROM generate_series(1,100) AS g;

INSERT INTO "AssessmentQuestion" ("id","assessmentId","question","correctAnswer","explanation")
SELECT 'question-' || lpad(g::text,4,'0'),
       'assessment-' || lpad(((g-1)/5+1)::text,3,'0'),
       'Question ' || g, 1 + g%4, 'Synthetic explanation ' || g
FROM generate_series(1,500) AS g;

INSERT INTO "AssessmentQuestionOption" ("questionId","optionPosition","optionText")
SELECT 'question-' || lpad(q::text,4,'0'), p, 'Option ' || p || ' for question ' || q
FROM generate_series(1,500) AS q CROSS JOIN generate_series(1,4) AS p;

INSERT INTO "StudentSkill" ("id","studentProfileId","skillId","proficiencyLevel","source","createdAt","updatedAt")
SELECT 'student-skill-' || lpad(g::text,6,'0'),
       'student-profile-' || lpad((((g-1)/10)+1)::text,5,'0'),
       'skill-' || lpad((((((g-1)/10)+(g-1)%10)%100)+1)::text,3,'0'),
       (ARRAY['BEGINNER','INTERMEDIATE','ADVANCED','EXPERT'])[1+g%4]::"ProficiencyLevel",
       (ARRAY['MANUAL','ASSESSMENT','RESUME'])[1+g%3]::"SkillSource",
       CURRENT_TIMESTAMP - (g%300)*INTERVAL '1 day', CURRENT_TIMESTAMP
FROM generate_series(1,50000) AS g;

INSERT INTO "AssessmentResult" ("id","studentProfileId","assessmentId","score","percentage","proficiencyLevel","completedAt")
SELECT 'assessment-result-' || lpad(g::text,6,'0'),
       'student-profile-' || lpad((((g-1)%5000+1)::text),5,'0'),
       'assessment-' || lpad((((g-1)/5000+1)::text),3,'0'),
       g%6, (g%6)*20.0,
       (ARRAY['BEGINNER','INTERMEDIATE','ADVANCED','EXPERT'])[1+g%4]::"ProficiencyLevel",
       CURRENT_TIMESTAMP - (g%700)*INTERVAL '1 day'
FROM generate_series(1,15000) AS g;

INSERT INTO "LearningRecommendation" ("id","studentProfileId","skillId","title","description","difficulty","resourceUrl","priority","isCompleted","createdAt")
SELECT 'recommendation-' || lpad(g::text,6,'0'),
       'student-profile-' || lpad((((g-1)/2+1)::text),5,'0'),
       'skill-' || lpad((((g-1)%100+1)::text),3,'0'),
       'Recommendation ' || g, 'Synthetic learning recommendation ' || g,
       (ARRAY['BEGINNER','INTERMEDIATE','ADVANCED','EXPERT'])[1+g%4]::"ProficiencyLevel",
       'https://example.test/learn/' || g, 1+g%5, g%3=0,
       CURRENT_TIMESTAMP - (g%400)*INTERVAL '1 day'
FROM generate_series(1,10000) AS g;

INSERT INTO "Opportunity" ("id","companyId","title","type","description","responsibilities","qualifications","location","workMode","compensation","openings","applicationUrl","applicationDeadline","startDate","endDate","status","publishedAt","createdAt","updatedAt")
SELECT 'opportunity-' || lpad(g::text,4,'0'),
       'company-' || lpad(((g-1)%200+1)::text,3,'0'),
       'Opportunity ' || g,
       (ARRAY['INTERNSHIP','JOB','PROJECT'])[1+g%3]::"OpportunityType",
       'Synthetic opportunity ' || g, 'Responsibilities ' || g, 'Qualifications ' || g,
       CASE WHEN g%2=0 THEN 'Remote' ELSE 'Bengaluru' END,
       (ARRAY['REMOTE','HYBRID','ONSITE'])[1+g%3]::"WorkMode",
       '$' || (50000+g)::text, 1+g%10, 'https://example.test/apply/' || g,
       CURRENT_TIMESTAMP + ((g%90)+1)*INTERVAL '1 day',
       CURRENT_TIMESTAMP + INTERVAL '30 days', CURRENT_TIMESTAMP + INTERVAL '120 days',
       CASE WHEN g%5=0 THEN 'CLOSED'::"OpportunityStatus" WHEN g%11=0 THEN 'DRAFT'::"OpportunityStatus" ELSE 'OPEN'::"OpportunityStatus" END,
       CURRENT_TIMESTAMP - (g%180)*INTERVAL '1 day',
       CURRENT_TIMESTAMP - (g%500)*INTERVAL '1 day', CURRENT_TIMESTAMP
FROM generate_series(1,1100) AS g;

INSERT INTO "Application" ("id","studentProfileId","opportunityId","status","coverLetter","recruiterRemarks","createdAt","updatedAt")
SELECT 'application-' || lpad(g::text,6,'0'),
       'student-profile-' || lpad((((g-1)%5000+1)::text),5,'0'),
       'opportunity-' || lpad((( (((g-1)/5000)*17 + (g-1)%5000) % 1000 + 1))::text,4,'0'),
       CASE WHEN g=1 THEN 'SUBMITTED'::"ApplicationStatus"
            WHEN g%20=0 THEN 'SELECTED'::"ApplicationStatus"
            WHEN g%7=0 THEN 'UNDER_REVIEW'::"ApplicationStatus"
            WHEN g%5=0 THEN 'SHORTLISTED'::"ApplicationStatus"
            WHEN g%3=0 THEN 'REJECTED'::"ApplicationStatus"
            ELSE 'SUBMITTED'::"ApplicationStatus" END,
       'Synthetic cover letter ' || g, NULL,
       CURRENT_TIMESTAMP - (g%300)*INTERVAL '1 day', CURRENT_TIMESTAMP
FROM generate_series(1,20000) AS g;

INSERT INTO "ApplicationStatusHistory" ("id","applicationId","status","remarks","changedByUserId","createdAt")
SELECT 'application-history-' || lpad(g::text,6,'0'),
       'application-' || lpad(((g-1)%20000+1)::text,6,'0'),
       a."status", 'Synthetic status history ' || g,
       'industry-user-' || lpad(((g-1)%200+1)::text,3,'0'),
       CURRENT_TIMESTAMP - (g%300)*INTERVAL '1 day'
FROM generate_series(1,25000) AS g
JOIN "Application" a ON a."id"='application-' || lpad(((g-1)%20000+1)::text,6,'0');

INSERT INTO "Interview" ("id","applicationId","scheduledAt","location","meetingUrl","notes","status","createdAt","updatedAt")
SELECT 'interview-' || lpad(g::text,5,'0'),
       'application-' || lpad((g*4)::text,6,'0'),
       CURRENT_TIMESTAMP + (g%45)*INTERVAL '1 day', 'Video call',
       'https://example.test/meeting/' || g, 'Synthetic interview ' || g,
       CASE WHEN g%5=0 THEN 'COMPLETED'::"InterviewStatus" ELSE 'SCHEDULED'::"InterviewStatus" END,
       CURRENT_TIMESTAMP - (g%90)*INTERVAL '1 day', CURRENT_TIMESTAMP
FROM generate_series(1,5000) AS g;

INSERT INTO "Internship" ("id","applicationId","studentProfileId","companyId","institutionId","title","startDate","endDate","status","notes","createdAt","updatedAt")
SELECT 'internship-' || lpad(row_number() OVER (ORDER BY a."id")::text,5,'0'),
       a."id", a."studentProfileId", o."companyId", sp."institutionId",
       'Internship for ' || o."title", CURRENT_TIMESTAMP + INTERVAL '30 days',
       CURRENT_TIMESTAMP + INTERVAL '120 days',
       (ARRAY['OFFERED','ACTIVE','COMPLETED','CANCELLED'])[1+(row_number() OVER (ORDER BY a."id"))%4]::"InternshipStatus",
       'Synthetic internship', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM "Application" a
JOIN "Opportunity" o ON o."id"=a."opportunityId"
JOIN "StudentProfile" sp ON sp."id"=a."studentProfileId"
WHERE a."status"='SELECTED' AND a."id"<>'application-000020';

INSERT INTO "Placement" ("id","studentProfileId","institutionId","companyId","role","placedAt","compensation","notes","createdAt","updatedAt")
SELECT 'placement-' || lpad(g::text,4,'0'),
       'student-profile-' || lpad(g::text,5,'0'),
       'institution-' || lpad(((g-1)%50+1)::text,3,'0'),
       'company-' || lpad(((g-1)%200+1)::text,3,'0'),
       'Role ' || g, CURRENT_TIMESTAMP - (g%250)*INTERVAL '1 day',
       '$' || (60000+g)::text, 'Synthetic placement ' || g,
       CURRENT_TIMESTAMP - (g%300)*INTERVAL '1 day', CURRENT_TIMESTAMP
FROM generate_series(1,500) AS g;

INSERT INTO "Notification" ("id","userId","type","title","message","link","readAt","createdAt")
SELECT 'notification-' || lpad(g::text,6,'0'),
       'student-user-' || lpad(((g-1)%5000+1)::text,5,'0'),
       CASE WHEN g%2=0 THEN 'APPLICATION_STATUS' ELSE 'NEW_APPLICATION' END,
       'Notification ' || g, 'Synthetic notification message ' || g,
       '/benchmark/' || g,
       CASE WHEN g%3=0 THEN CURRENT_TIMESTAMP - INTERVAL '1 day' ELSE NULL END,
       CURRENT_TIMESTAMP - (g%180)*INTERVAL '1 day'
FROM generate_series(1,20000) AS g;

ANALYZE;
COMMIT;
