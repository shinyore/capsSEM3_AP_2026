-- SkillBridge AI AP CP3: representative SQL for database operations used by the application.
-- Parameters use PostgreSQL positional placeholders ($1, $2, ...).
-- IDs are unique within READ and WRITE groups. Run writes with application-generated IDs.

-- READ
-- R1: Find an account during registration by email.
SELECT "id", "email" FROM "User" WHERE "email" = $1;

-- READ
-- R2: Authenticate account and retrieve account state and role.
SELECT "id", "fullName", "email", "password", "role", "isActive"
FROM "User" WHERE "email" = $1;

-- READ
-- R3: Resolve authenticated account by ID.
SELECT "id", "fullName", "email", "role", "isActive"
FROM "User" WHERE "id" = $1;

-- WRITE
-- W1: Create a user account (follow with role-specific profile insert).
INSERT INTO "User" ("id", "fullName", "email", "password", "phone", "role", "isActive", "updatedAt")
VALUES ($1, $2, $3, $4, $5, $6, TRUE, CURRENT_TIMESTAMP);

-- WRITE
-- W2: Create a student profile during registration.
INSERT INTO "StudentProfile" ("id", "userId", "updatedAt") VALUES ($1, $2, CURRENT_TIMESTAMP);

-- WRITE
-- W3: Create an institution profile during registration.
INSERT INTO "Institution" ("id", "userId", "name", "officialEmail", "updatedAt")
VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP);

-- WRITE
-- W4: Create a company profile during registration.
INSERT INTO "Company" ("id", "userId", "name", "officialEmail", "updatedAt")
VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP);

-- READ
-- R4: Admin user listing with optional role/status filters.
SELECT "id", "fullName", "email", "phone", "role", "isActive", "createdAt"
FROM "User" WHERE ($1::"Role" IS NULL OR "role" = $1)
  AND ($2::BOOLEAN IS NULL OR "isActive" = $2)
ORDER BY "createdAt" DESC LIMIT $3 OFFSET $4;

-- READ
-- R5: Read user detail with related student, institution, or company profile.
SELECT u."id", u."fullName", u."email", u."phone", u."role", u."isActive",
       sp."degree", sp."department", sp."graduationYear", i."name" AS "institutionName",
       c."name" AS "companyName", c."isVerified"
FROM "User" u LEFT JOIN "StudentProfile" sp ON sp."userId" = u."id"
LEFT JOIN "Institution" i ON i."userId" = u."id"
LEFT JOIN "Company" c ON c."userId" = u."id"
WHERE u."id" = $1;

-- WRITE
-- W5: Update editable user account fields.
UPDATE "User" SET "fullName" = COALESCE($2, "fullName"), "phone" = COALESCE($3, "phone"),
 "role" = COALESCE($4, "role"), "updatedAt" = CURRENT_TIMESTAMP WHERE "id" = $1;

-- WRITE
-- W6: Enable or disable a user account.
UPDATE "User" SET "isActive" = $2, "updatedAt" = CURRENT_TIMESTAMP WHERE "id" = $1;

-- READ
-- R6: Read own student profile with account and institution details.
SELECT sp.*, u."fullName", u."email", i."name" AS "institutionName"
FROM "StudentProfile" sp JOIN "User" u ON u."id" = sp."userId"
LEFT JOIN "Institution" i ON i."id" = sp."institutionId" WHERE sp."userId" = $1;

-- WRITE
-- W7: Insert or update a student's editable profile.
INSERT INTO "StudentProfile" ("id", "userId", "institutionId", "degree", "department", "graduationYear", "semester", "bio", "profileImage", "resumeUrl", "linkedIn", "github", "portfolio", "updatedAt")
VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,CURRENT_TIMESTAMP)
ON CONFLICT ("userId") DO UPDATE SET "institutionId"=EXCLUDED."institutionId", "degree"=EXCLUDED."degree", "department"=EXCLUDED."department", "graduationYear"=EXCLUDED."graduationYear", "semester"=EXCLUDED."semester", "bio"=EXCLUDED."bio", "profileImage"=EXCLUDED."profileImage", "resumeUrl"=EXCLUDED."resumeUrl", "linkedIn"=EXCLUDED."linkedIn", "github"=EXCLUDED."github", "portfolio"=EXCLUDED."portfolio", "updatedAt"=CURRENT_TIMESTAMP;

-- READ
-- R7: Read company profile for an industry account.
SELECT c.*, u."fullName", u."email" FROM "Company" c JOIN "User" u ON u."id"=c."userId" WHERE c."userId"=$1;

-- WRITE
-- W8: Update company profile fields.
UPDATE "Company" SET "name"=COALESCE($2,"name"), "officialEmail"=COALESCE($3,"officialEmail"), "website"=COALESCE($4,"website"), "address"=COALESCE($5,"address"), "description"=COALESCE($6,"description"), "contactInfo"=COALESCE($7,"contactInfo"), "updatedAt"=CURRENT_TIMESTAMP WHERE "userId"=$1;

-- READ
-- R8: Read institution profile for its account.
SELECT i.*, u."fullName", u."email" FROM "Institution" i JOIN "User" u ON u."id"=i."userId" WHERE i."userId"=$1;

-- WRITE
-- W9: Insert or update institution profile.
INSERT INTO "Institution" ("id","userId","name","officialEmail","website","address","description","contactInfo","updatedAt") VALUES ($1,$2,$3,$4,$5,$6,$7,$8,CURRENT_TIMESTAMP)
ON CONFLICT ("userId") DO UPDATE SET "name"=EXCLUDED."name", "officialEmail"=EXCLUDED."officialEmail", "website"=EXCLUDED."website", "address"=EXCLUDED."address", "description"=EXCLUDED."description", "contactInfo"=EXCLUDED."contactInfo", "updatedAt"=CURRENT_TIMESTAMP;

-- WRITE
-- W10: Admin verifies or rejects an institution using the schema's boolean field.
UPDATE "Institution" SET "isVerified"=$2, "updatedAt"=CURRENT_TIMESTAMP WHERE "id"=$1;

-- WRITE
-- W11: Admin verifies or rejects a company using AP's isVerified field.
UPDATE "Company" SET "isVerified"=$2, "updatedAt"=CURRENT_TIMESTAMP WHERE "id"=$1;

-- READ
-- R9: List companies for administrative review.
SELECT c."id", c."name", c."officialEmail", c."isVerified", c."createdAt", u."email" AS "accountEmail"
FROM "Company" c JOIN "User" u ON u."id"=c."userId" ORDER BY c."createdAt" DESC;

-- READ
-- R10: Search the skill catalog.
SELECT "id","name","category","description" FROM "Skill"
WHERE ($1::TEXT IS NULL OR "category"=$1) AND ($2::TEXT IS NULL OR "name" ILIKE '%' || $2 || '%')
ORDER BY "category","name";

-- WRITE
-- W12: Admin creates a catalog skill.
INSERT INTO "Skill" ("id","name","category","description","updatedAt") VALUES ($1,$2,$3,$4,CURRENT_TIMESTAMP);

-- READ
-- R11: List a student's skills and proficiency.
SELECT ss."studentProfileId", s."id" AS "skillId", s."name", s."category", ss."proficiencyLevel", ss."source"
FROM "StudentSkill" ss JOIN "StudentProfile" sp ON sp."id"=ss."studentProfileId"
JOIN "Skill" s ON s."id"=ss."skillId" WHERE sp."userId"=$1 ORDER BY s."name";

-- WRITE
-- W13: Add or replace a student's skill/proficiency (manual or approved resume skill).
INSERT INTO "StudentSkill" ("id","studentProfileId","skillId","proficiencyLevel","source","updatedAt") VALUES ($1,$2,$3,$4,$5,CURRENT_TIMESTAMP)
ON CONFLICT ("studentProfileId","skillId") DO UPDATE SET "proficiencyLevel"=EXCLUDED."proficiencyLevel", "source"=EXCLUDED."source", "updatedAt"=CURRENT_TIMESTAMP;

-- WRITE
-- W14: Change proficiency for an existing student skill.
UPDATE "StudentSkill" ss SET "proficiencyLevel"=$3,"updatedAt"=CURRENT_TIMESTAMP FROM "StudentProfile" sp WHERE ss."studentProfileId"=sp."id" AND sp."userId"=$1 AND ss."skillId"=$2;

-- WRITE
-- W15: Remove a skill from a student's profile.
DELETE FROM "StudentSkill" ss USING "StudentProfile" sp WHERE ss."studentProfileId"=sp."id" AND sp."userId"=$1 AND ss."skillId"=$2;

-- READ
-- R12: Load assessment catalog with skill names.
SELECT a."id",a."title",a."description",a."totalQuestions",s."id" AS "skillId",s."name" AS "skillName"
FROM "Assessment" a JOIN "Skill" s ON s."id"=a."skillId" ORDER BY s."name",a."title";

-- READ
-- R13: Load assessment questions and normalized answer options for a student attempt.
SELECT a."id" AS "assessmentId",a."title",s."name" AS "skillName",q."id" AS "questionId",q."question",q."correctAnswer",o."optionPosition",o."optionText"
FROM "Assessment" a JOIN "Skill" s ON s."id"=a."skillId"
JOIN "AssessmentQuestion" q ON q."assessmentId"=a."id"
LEFT JOIN "AssessmentQuestionOption" o ON o."questionId"=q."id"
WHERE a."id"=$1 ORDER BY q."id",o."optionPosition";

-- WRITE
-- W16: Save assessment result after grading answers.
INSERT INTO "AssessmentResult" ("id","studentProfileId","assessmentId","score","percentage","proficiencyLevel") VALUES ($1,$2,$3,$4,$5,$6);

-- WRITE
-- W17: Assessment result updates the student's proficiency for the assessed skill.
INSERT INTO "StudentSkill" ("id","studentProfileId","skillId","proficiencyLevel","source","updatedAt") VALUES ($1,$2,$3,$4,'ASSESSMENT',CURRENT_TIMESTAMP)
ON CONFLICT ("studentProfileId","skillId") DO UPDATE SET "proficiencyLevel"=EXCLUDED."proficiencyLevel", "source"='ASSESSMENT', "updatedAt"=CURRENT_TIMESTAMP;

-- READ
-- R14: List a student's assessment history with assessment and skill details.
SELECT ar."id",ar."score",ar."percentage",ar."proficiencyLevel",ar."completedAt",a."title",s."name" AS "skillName"
FROM "AssessmentResult" ar JOIN "Assessment" a ON a."id"=ar."assessmentId"
JOIN "Skill" s ON s."id"=a."skillId" JOIN "StudentProfile" sp ON sp."id"=ar."studentProfileId"
WHERE sp."userId"=$1 ORDER BY ar."completedAt" DESC;

-- READ
-- R15: Compute student skill gap against catalog skills (skills missing or below target proficiency).
SELECT s."id",s."name",s."category",ss."proficiencyLevel"
FROM "Skill" s CROSS JOIN "StudentProfile" sp LEFT JOIN "StudentSkill" ss ON ss."skillId"=s."id" AND ss."studentProfileId"=sp."id"
WHERE sp."userId"=$1 ORDER BY s."category",s."name";

-- READ
-- R16: List a student's recommendations with associated skills.
SELECT lr."id",lr."title",lr."description",lr."difficulty",lr."resourceUrl",lr."priority",lr."isCompleted",s."name" AS "skillName"
FROM "LearningRecommendation" lr JOIN "Skill" s ON s."id"=lr."skillId"
JOIN "StudentProfile" sp ON sp."id"=lr."studentProfileId" WHERE sp."userId"=$1
ORDER BY lr."isCompleted",lr."priority",lr."createdAt" DESC;

-- WRITE
-- W18: Add a generated learning recommendation unless a matching active recommendation already exists.
INSERT INTO "LearningRecommendation" ("id","studentProfileId","skillId","title","description","difficulty","resourceUrl","priority","isCompleted")
SELECT $1,$2,$3,$4,$5,$6,$7,$8,FALSE WHERE NOT EXISTS
(SELECT 1 FROM "LearningRecommendation" WHERE "studentProfileId"=$2 AND "skillId"=$3 AND "title"=$4 AND "isCompleted"=FALSE);

-- WRITE
-- W19: Mark a recommendation complete or reopen it.
UPDATE "LearningRecommendation" lr SET "isCompleted"=$3 FROM "StudentProfile" sp
WHERE lr."studentProfileId"=sp."id" AND sp."userId"=$1 AND lr."id"=$2;

-- READ
-- R17: Browse open opportunities with company information.
SELECT o.*,c."name" AS "companyName",c."isVerified"
FROM "Opportunity" o JOIN "Company" c ON c."id"=o."companyId"
WHERE o."status"='OPEN' AND ($1::"OpportunityType" IS NULL OR o."type"=$1)
AND ($2::TEXT IS NULL OR o."location" ILIKE '%'||$2||'%')
ORDER BY o."createdAt" DESC LIMIT $3 OFFSET $4;

-- READ
-- R18: List opportunities owned by a company.
SELECT o.* FROM "Opportunity" o JOIN "Company" c ON c."id"=o."companyId"
WHERE c."userId"=$1 ORDER BY o."createdAt" DESC;

-- WRITE
-- W20: Create an opportunity for the current company.
INSERT INTO "Opportunity" ("id","companyId","title","type","description","responsibilities","qualifications","location","workMode","compensation","openings","applicationUrl","applicationDeadline","startDate","endDate","status","publishedAt","updatedAt")
SELECT $1,c."id",$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,CURRENT_TIMESTAMP FROM "Company" c WHERE c."userId"=$2;

-- WRITE
-- W21: Update opportunity details for its owning company.
UPDATE "Opportunity" o SET "title"=COALESCE($3,o."title"),"description"=COALESCE($4,o."description"),"responsibilities"=COALESCE($5,o."responsibilities"),"qualifications"=COALESCE($6,o."qualifications"),"location"=COALESCE($7,o."location"),"workMode"=COALESCE($8,o."workMode"),"compensation"=COALESCE($9,o."compensation"),"openings"=COALESCE($10,o."openings"),"applicationUrl"=COALESCE($11,o."applicationUrl"),"applicationDeadline"=COALESCE($12,o."applicationDeadline"),"startDate"=COALESCE($13,o."startDate"),"endDate"=COALESCE($14,o."endDate"),"updatedAt"=CURRENT_TIMESTAMP
FROM "Company" c WHERE o."companyId"=c."id" AND c."userId"=$1 AND o."id"=$2;

-- WRITE
-- W22: Publish, close, reopen, or archive an owned opportunity (verification required to open).
UPDATE "Opportunity" o SET "status"=$3,"publishedAt"=CASE WHEN $3='OPEN' THEN COALESCE(o."publishedAt",CURRENT_TIMESTAMP) ELSE o."publishedAt" END,"updatedAt"=CURRENT_TIMESTAMP
FROM "Company" c WHERE o."companyId"=c."id" AND c."userId"=$1 AND o."id"=$2 AND ($3<>'OPEN' OR c."isVerified"=TRUE);

-- WRITE
-- W23: Delete an owned opportunity (only when dependent rows permit it).
DELETE FROM "Opportunity" o USING "Company" c WHERE o."companyId"=c."id" AND c."userId"=$1 AND o."id"=$2;

-- READ
-- R19: Check whether the student already applied to an opportunity.
SELECT "id","status" FROM "Application" WHERE "studentProfileId"=$1 AND "opportunityId"=$2;

-- WRITE
-- W24: Submit an application, initial status history, and notification atomically (execute these statements in one transaction).
INSERT INTO "Application" ("id","studentProfileId","opportunityId","coverLetter","status","updatedAt") VALUES ($1,$2,$3,$4,'SUBMITTED',CURRENT_TIMESTAMP);

-- WRITE
-- W25: Record initial application status history.
INSERT INTO "ApplicationStatusHistory" ("id","applicationId","status","changedByUserId") VALUES ($1,$2,'SUBMITTED',$3);

-- WRITE
-- W26: Notify the company account about a new application.
INSERT INTO "Notification" ("id","userId","type","title","message","link")
SELECT $1,c."userId",'NEW_APPLICATION','New application','A candidate applied for your opportunity.','/industry/applicants'
FROM "Application" a JOIN "Opportunity" o ON o."id"=a."opportunityId" JOIN "Company" c ON c."id"=o."companyId" WHERE a."id"=$2;

-- READ
-- R20: Student application list with opportunity, company and status history.
SELECT a."id",a."status",a."coverLetter",a."recruiterRemarks",a."createdAt",o."title",o."type",o."applicationDeadline",c."name" AS "companyName",h."status" AS "historyStatus",h."createdAt" AS "statusChangedAt"
FROM "Application" a JOIN "StudentProfile" sp ON sp."id"=a."studentProfileId"
JOIN "Opportunity" o ON o."id"=a."opportunityId" JOIN "Company" c ON c."id"=o."companyId"
LEFT JOIN "ApplicationStatusHistory" h ON h."applicationId"=a."id"
WHERE sp."userId"=$1 ORDER BY a."createdAt" DESC,h."createdAt" ASC;

-- READ
-- R21: Company applicant list with student identity/profile and opportunity.
SELECT a."id",a."status",a."coverLetter",a."recruiterRemarks",a."createdAt",u."fullName",u."email",sp."resumeUrl",o."title"
FROM "Application" a JOIN "Opportunity" o ON o."id"=a."opportunityId"
JOIN "Company" c ON c."id"=o."companyId" JOIN "StudentProfile" sp ON sp."id"=a."studentProfileId"
JOIN "User" u ON u."id"=sp."userId" WHERE c."userId"=$1 ORDER BY a."createdAt" DESC;

-- WRITE
-- W27: Change application status, append history and notify student atomically.
UPDATE "Application" SET "status"=$2,"recruiterRemarks"=$3,"updatedAt"=CURRENT_TIMESTAMP WHERE "id"=$1;

-- WRITE
-- W28: Append a status-history row for the application status change.
INSERT INTO "ApplicationStatusHistory" ("id","applicationId","status","remarks","changedByUserId") VALUES ($1,$2,$3,$4,$5);

-- WRITE
-- W29: Notify the applicant of a status change.
INSERT INTO "Notification" ("id","userId","type","title","message","link")
SELECT $1,sp."userId",'APPLICATION_STATUS','Application status updated',$3,$4 FROM "Application" a JOIN "StudentProfile" sp ON sp."id"=a."studentProfileId" WHERE a."id"=$2;

-- WRITE
-- W30: Student withdraws an application.
UPDATE "Application" a SET "status"='WITHDRAWN',"updatedAt"=CURRENT_TIMESTAMP
FROM "StudentProfile" sp WHERE a."studentProfileId"=sp."id" AND sp."userId"=$1 AND a."id"=$2 AND a."status" IN ('SUBMITTED','UNDER_REVIEW','SHORTLISTED');

-- READ
-- R22: Read application status history (remarks can be restricted by caller role).
SELECT h."id",h."status",h."remarks",h."createdAt",h."changedByUserId"
FROM "ApplicationStatusHistory" h JOIN "Application" a ON a."id"=h."applicationId"
LEFT JOIN "StudentProfile" sp ON sp."id"=a."studentProfileId"
LEFT JOIN "Opportunity" o ON o."id"=a."opportunityId" LEFT JOIN "Company" c ON c."id"=o."companyId"
WHERE a."id"=$1 AND (sp."userId"=$2 OR c."userId"=$2) ORDER BY h."createdAt";

-- READ
-- R23: Application counts grouped by status for a company.
SELECT a."status",COUNT(*) AS "applicationCount" FROM "Application" a
JOIN "Opportunity" o ON o."id"=a."opportunityId" JOIN "Company" c ON c."id"=o."companyId"
WHERE c."userId"=$1 GROUP BY a."status";

-- WRITE
-- W31: Schedule interview for an application; notification is a separate insert in same transaction.
INSERT INTO "Interview" ("id","applicationId","scheduledAt","location","meetingUrl","notes","status","updatedAt")
VALUES ($1,$2,$3,$4,$5,$6,'SCHEDULED',CURRENT_TIMESTAMP);

-- READ
-- R24: List student interviews with opportunity title.
SELECT i."id",i."scheduledAt",i."location",i."meetingUrl",i."notes",i."status",o."title"
FROM "Interview" i JOIN "Application" a ON a."id"=i."applicationId"
JOIN "StudentProfile" sp ON sp."id"=a."studentProfileId" JOIN "Opportunity" o ON o."id"=a."opportunityId"
WHERE sp."userId"=$1 ORDER BY i."scheduledAt";

-- READ
-- R25: List company interviews with candidate name and opportunity.
SELECT i."id",i."scheduledAt",i."status",u."fullName",o."title",a."status" AS "applicationStatus"
FROM "Interview" i JOIN "Application" a ON a."id"=i."applicationId"
JOIN "Opportunity" o ON o."id"=a."opportunityId" JOIN "Company" c ON c."id"=o."companyId"
JOIN "StudentProfile" sp ON sp."id"=a."studentProfileId" JOIN "User" u ON u."id"=sp."userId"
WHERE c."userId"=$1 ORDER BY i."scheduledAt";

-- WRITE
-- W32: Update interview details or cancel a scheduled interview.
UPDATE "Interview" i SET "scheduledAt"=COALESCE($3,i."scheduledAt"),"location"=COALESCE($4,i."location"),"meetingUrl"=COALESCE($5,i."meetingUrl"),"notes"=COALESCE($6,i."notes"),"status"=COALESCE($7,i."status"),"updatedAt"=CURRENT_TIMESTAMP
FROM "Application" a JOIN "Opportunity" o ON o."id"=a."opportunityId" JOIN "Company" c ON c."id"=o."companyId"
WHERE i."applicationId"=a."id" AND c."userId"=$1 AND i."id"=$2;

-- WRITE
-- W33: Create internship from selected application.
INSERT INTO "Internship" ("id","applicationId","studentProfileId","companyId","institutionId","title","startDate","endDate","notes","updatedAt")
SELECT $1,a."id",a."studentProfileId",o."companyId",sp."institutionId",$3,$4,$5,$6,CURRENT_TIMESTAMP
FROM "Application" a JOIN "Opportunity" o ON o."id"=a."opportunityId" JOIN "StudentProfile" sp ON sp."id"=a."studentProfileId"
WHERE a."id"=$2 AND a."status"='SELECTED';

-- READ
-- R26: List internships with student, institution and company information.
SELECT it."id",it."title",it."startDate",it."endDate",it."status",c."name" AS "companyName",i."name" AS "institutionName",u."fullName" AS "studentName"
FROM "Internship" it JOIN "Company" c ON c."id"=it."companyId"
JOIN "StudentProfile" sp ON sp."id"=it."studentProfileId" JOIN "User" u ON u."id"=sp."userId"
LEFT JOIN "Institution" i ON i."id"=it."institutionId"
WHERE ($1::TEXT IS NULL OR sp."userId"=$1) AND ($2::TEXT IS NULL OR c."userId"=$2) AND ($3::TEXT IS NULL OR i."userId"=$3)
ORDER BY it."createdAt" DESC;

-- WRITE
-- W34: Update internship status.
UPDATE "Internship" SET "status"=$2,"updatedAt"=CURRENT_TIMESTAMP WHERE "id"=$1;

-- WRITE
-- W35: Create placement record.
INSERT INTO "Placement" ("id","studentProfileId","institutionId","companyId","role","compensation","notes","updatedAt") VALUES ($1,$2,$3,$4,$5,$6,$7,CURRENT_TIMESTAMP);

-- READ
-- R27: List placements for student/institution/admin with related organization names.
SELECT p."id",p."role",p."placedAt",p."compensation",u."fullName" AS "studentName",i."name" AS "institutionName",c."name" AS "companyName"
FROM "Placement" p JOIN "StudentProfile" sp ON sp."id"=p."studentProfileId"
JOIN "User" u ON u."id"=sp."userId" JOIN "Company" c ON c."id"=p."companyId"
LEFT JOIN "Institution" i ON i."id"=p."institutionId"
WHERE ($1::TEXT IS NULL OR sp."userId"=$1) AND ($2::TEXT IS NULL OR i."userId"=$2)
ORDER BY p."placedAt" DESC;

-- WRITE
-- W36: Update placement details.
UPDATE "Placement" SET "role"=COALESCE($2,"role"),"compensation"=COALESCE($3,"compensation"),"notes"=COALESCE($4,"notes"),"updatedAt"=CURRENT_TIMESTAMP WHERE "id"=$1;

-- READ
-- R28: List notifications for the current account.
SELECT "id","type","title","message","link","readAt","createdAt" FROM "Notification" WHERE "userId"=$1 ORDER BY "createdAt" DESC LIMIT 100;

-- READ
-- R29: Count unread notifications.
SELECT COUNT(*) AS "unreadCount" FROM "Notification" WHERE "userId"=$1 AND "readAt" IS NULL;

-- WRITE
-- W37: Mark one owned notification read.
UPDATE "Notification" SET "readAt"=COALESCE("readAt",CURRENT_TIMESTAMP) WHERE "id"=$1 AND "userId"=$2;

-- WRITE
-- W38: Mark all current user's notifications read.
UPDATE "Notification" SET "readAt"=CURRENT_TIMESTAMP WHERE "userId"=$1 AND "readAt" IS NULL;

-- WRITE
-- W39: Delete one notification owned by the current user.
DELETE FROM "Notification" WHERE "id"=$1 AND "userId"=$2;

-- READ
-- R30: Institution student roster with assessment-result totals.
SELECT sp."id",sp."degree",sp."department",sp."graduationYear",sp."semester",u."fullName",u."email",COUNT(ar."id") AS "assessmentCount"
FROM "Institution" i JOIN "StudentProfile" sp ON sp."institutionId"=i."id" JOIN "User" u ON u."id"=sp."userId"
LEFT JOIN "AssessmentResult" ar ON ar."studentProfileId"=sp."id" WHERE i."userId"=$1
GROUP BY sp."id",u."fullName",u."email" ORDER BY u."fullName";

-- READ
-- R31: Student dashboard aggregates.
SELECT (SELECT COUNT(*) FROM "Application" a JOIN "StudentProfile" sp ON sp."id"=a."studentProfileId" WHERE sp."userId"=$1) AS "applications",
 (SELECT COUNT(*) FROM "Interview" it JOIN "Application" a ON a."id"=it."applicationId" JOIN "StudentProfile" sp ON sp."id"=a."studentProfileId" WHERE sp."userId"=$1 AND it."status"='SCHEDULED' AND it."scheduledAt">CURRENT_TIMESTAMP) AS "upcomingInterviews",
 (SELECT COUNT(*) FROM "Internship" it JOIN "StudentProfile" sp ON sp."id"=it."studentProfileId" WHERE sp."userId"=$1) AS "internships",
 (SELECT COUNT(*) FROM "Placement" p JOIN "StudentProfile" sp ON sp."id"=p."studentProfileId" WHERE sp."userId"=$1) AS "placements",
 (SELECT COUNT(*) FROM "Notification" n WHERE n."userId"=$2 AND n."readAt" IS NULL) AS "unreadNotifications";

-- READ
-- R32: Industry dashboard counts by status and recent activity totals.
SELECT o."status",COUNT(*) AS "opportunityCount" FROM "Opportunity" o JOIN "Company" c ON c."id"=o."companyId" WHERE c."userId"=$1 GROUP BY o."status";

-- READ
-- R33: Industry dashboard application counts by status.
SELECT a."status",COUNT(*) AS "applicationCount" FROM "Application" a JOIN "Opportunity" o ON o."id"=a."opportunityId" JOIN "Company" c ON c."id"=o."companyId" WHERE c."userId"=$1 GROUP BY a."status";

-- READ
-- R34: Industry dashboard interview, internship and recent application counts.
SELECT (SELECT COUNT(*) FROM "Interview" it JOIN "Application" a ON a."id"=it."applicationId" JOIN "Opportunity" o ON o."id"=a."opportunityId" JOIN "Company" c ON c."id"=o."companyId" WHERE c."userId"=$1 AND it."status"='SCHEDULED') AS "scheduledInterviews",
 (SELECT COUNT(*) FROM "Internship" it JOIN "Company" c ON c."id"=it."companyId" WHERE c."userId"=$1) AS "internships",
 (SELECT COUNT(*) FROM "Application" a JOIN "Opportunity" o ON o."id"=a."opportunityId" JOIN "Company" c ON c."id"=o."companyId" WHERE c."userId"=$1 AND a."createdAt">=CURRENT_TIMESTAMP-INTERVAL '7 days') AS "newApplications";

-- READ
-- R35: Institution dashboard placement, active internship, department and hiring-company data.
SELECT sp."department",c."name" AS "companyName",COUNT(p."id") AS "placementCount"
FROM "Institution" i JOIN "Placement" p ON p."institutionId"=i."id"
JOIN "StudentProfile" sp ON sp."id"=p."studentProfileId" JOIN "Company" c ON c."id"=p."companyId"
WHERE i."userId"=$1 GROUP BY sp."department",c."name";

-- READ
-- R36: Institution dashboard student and active internship totals.
SELECT (SELECT COUNT(*) FROM "StudentProfile" sp JOIN "Institution" i ON i."id"=sp."institutionId" WHERE i."userId"=$1) AS "students",
 (SELECT COUNT(*) FROM "Internship" it JOIN "Institution" i ON i."id"=it."institutionId" WHERE i."userId"=$1 AND it."status"='ACTIVE') AS "activeInternships",
 (SELECT COUNT(*) FROM "Placement" p JOIN "Institution" i ON i."id"=p."institutionId" WHERE i."userId"=$1) AS "placements";

-- READ
-- R37: Admin dashboard platform totals using AP verification boolean.
SELECT (SELECT COUNT(*) FROM "User") AS "users",
 (SELECT COUNT(*) FROM "User" WHERE "role"='STUDENT') AS "students",
 (SELECT COUNT(*) FROM "User" WHERE "role"='INSTITUTION') AS "institutions",
 (SELECT COUNT(*) FROM "User" WHERE "role"='INDUSTRY') AS "industries",
 (SELECT COUNT(*) FROM "Company" WHERE "isVerified") AS "verifiedCompanies",
 (SELECT COUNT(*) FROM "Company" WHERE NOT "isVerified") AS "unverifiedCompanies",
 (SELECT COUNT(*) FROM "Opportunity") AS "opportunities",
 (SELECT COUNT(*) FROM "Application") AS "applications",
 (SELECT COUNT(*) FROM "Internship") AS "internships",
 (SELECT COUNT(*) FROM "Placement") AS "placements";

-- READ
-- R38: Admin recent application activity with student and opportunity.
SELECT a."id",a."createdAt",a."status",u."fullName",o."title"
FROM "Application" a JOIN "StudentProfile" sp ON sp."id"=a."studentProfileId"
JOIN "User" u ON u."id"=sp."userId" JOIN "Opportunity" o ON o."id"=a."opportunityId"
ORDER BY a."createdAt" DESC LIMIT 5;

-- READ
-- R39: Admin recent company registrations.
SELECT c."id",c."name",c."createdAt",c."isVerified",u."email"
FROM "Company" c JOIN "User" u ON u."id"=c."userId" ORDER BY c."createdAt" DESC LIMIT 5;

-- READ
-- R40: Admin recent placement activity.
SELECT p."id",p."role",p."createdAt",u."fullName",c."name" AS "companyName"
FROM "Placement" p JOIN "StudentProfile" sp ON sp."id"=p."studentProfileId"
JOIN "User" u ON u."id"=sp."userId" JOIN "Company" c ON c."id"=p."companyId"
ORDER BY p."createdAt" DESC LIMIT 5;
