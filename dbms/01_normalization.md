# AP CP1: Schema Normalization — SkillBridge AI

## Scope and purpose

This report analyzes the SkillBridge AI PostgreSQL schema in the original source project at `capsSEM3/backend/prisma/schema.prisma`, together with its Prisma SQL migrations. The AP submission repository is the destination for this report. The unrelated Uber Ride-Hailing project is outside scope.

Normalization organizes relational data to reduce unnecessary duplication and avoid insert, update, and delete anomalies while preserving relationships. The analysis distinguishes the existing schema from one proposed normalization change. It is based on declared keys, unique constraints, foreign keys, and documented behavior only; it does not infer undocumented business rules.

There are **17 Prisma models/tables**. The nine Prisma enums constrain values but are not tables. Prisma relation-navigation fields are also not stored columns and are omitted from the attribute lists below. All `id` fields are `String` primary keys generated with `cuid()` by Prisma. `?` means nullable. Fields without `?` are required. Defaults and enum types are shown where relevant.

The migration history creates the tables in stages: the authentication migration creates `User`, `Institution`, `StudentProfile`, and `Company`; the opportunities migration adds `Opportunity`; the Skill AI migration adds `Skill`, `StudentSkill`, `Assessment`, `AssessmentQuestion`, `AssessmentResult`, and `LearningRecommendation`; the applications/placements migration adds `Application`, `ApplicationStatusHistory`, `Interview`, `Internship`, `Placement`, and `Notification`. A later migration changes the `Opportunity.companyId` delete action to `RESTRICT`. The final migration constraints agree with the current Prisma schema for the relationships analyzed here.

## Existing models, attributes, keys, relationships, and functional dependencies

For each relation, the listed PK and unique determinant(s) determine the other attributes in that relation. These are the functional dependencies (FDs) supported by declared keys. For compactness, `K → all non-K attributes` means the determinant determines every other stored attribute listed for that relation. A nullable unique column determines the row when it has a non-null value; PostgreSQL permits multiple nulls in a unique column. Ordinary indexes do not create FDs.

| Model and attributes | Keys, foreign keys, and supported FDs |
|---|---|
| **User** — `id`, `fullName`, `email`, `password`, `phone?`, `role` (`Role`), `isActive` (default `true`), `createdAt`, `updatedAt` | PK `id`; UQ `email`. FKs: none. FDs: `id →` all non-`id` attributes; `email →` all non-`email` attributes. |
| **Institution** — `id`, `userId`, `name`, `officialEmail`, `website?`, `address?`, `description?`, `contactInfo?`, `isVerified` (default `false`), `createdAt`, `updatedAt` | PK `id`; UQ `userId`, UQ `officialEmail`. FK `userId → User.id`. FDs: each of `id`, `userId`, and `officialEmail` determines all other attributes. |
| **StudentProfile** — `id`, `userId`, `institutionId?`, `degree?`, `department?`, `graduationYear?`, `semester?`, `bio?`, `profileImage?`, `resumeUrl?`, `linkedIn?`, `github?`, `portfolio?`, `createdAt`, `updatedAt` | PK `id`; UQ `userId`. FKs: `userId → User.id`; nullable `institutionId → Institution.id`. FDs: `id →` all non-`id` attributes; `userId →` all non-`userId` attributes. |
| **Skill** — `id`, `name`, `category`, `description?`, `createdAt`, `updatedAt` | PK `id`; UQ `name`. FKs: none. FDs: `id →` all non-`id` attributes; `name →` all non-`name` attributes. |
| **StudentSkill** — `id`, `studentProfileId`, `skillId`, `proficiencyLevel` (`ProficiencyLevel`), `source` (`SkillSource`, default `MANUAL`), `createdAt`, `updatedAt` | PK `id`; UQ (`studentProfileId`, `skillId`). FKs: `studentProfileId → StudentProfile.id`; `skillId → Skill.id`. FDs: `id →` all non-`id` attributes; (`studentProfileId`, `skillId`) → `id, proficiencyLevel, source, createdAt, updatedAt`. |
| **Assessment** — `id`, `skillId`, `title`, `description?`, `totalQuestions` (default `0`), `createdAt` | PK `id`. FK `skillId → Skill.id`. FD: `id → skillId, title, description, totalQuestions, createdAt`. |
| **AssessmentQuestion** — `id`, `assessmentId`, `question`, `options` (`String[]`), `correctAnswer` (`Int`), `explanation?` | PK `id`. FK `assessmentId → Assessment.id`. FD: `id → assessmentId, question, options, correctAnswer, explanation`. The array is a collection-valued column and is the atomicity issue discussed below. |
| **AssessmentResult** — `id`, `studentProfileId`, `assessmentId`, `score`, `percentage`, `proficiencyLevel` (`ProficiencyLevel`), `completedAt` (default current time) | PK `id`. FKs: `studentProfileId → StudentProfile.id`; `assessmentId → Assessment.id`. FD: `id → studentProfileId, assessmentId, score, percentage, proficiencyLevel, completedAt`. There is no unique constraint on the student/assessment pair; multiple attempts are permitted. |
| **LearningRecommendation** — `id`, `studentProfileId`, `skillId`, `title`, `description`, `difficulty` (`ProficiencyLevel`, default `BEGINNER`), `resourceUrl?`, `priority` (default `3`), `isCompleted` (default `false`), `createdAt` | PK `id`. FKs: `studentProfileId → StudentProfile.id`; `skillId → Skill.id`. FD: `id →` all non-`id` attributes. |
| **Company** — `id`, `userId`, `name`, `officialEmail`, `website?`, `address?`, `description?`, `contactInfo?`, `isVerified` (default `false`), `createdAt`, `updatedAt` | PK `id`; UQ `userId`, UQ `officialEmail`. FK `userId → User.id`. FDs: each of `id`, `userId`, and `officialEmail` determines all other attributes. |
| **Opportunity** — `id`, `companyId`, `title`, `type` (`OpportunityType`), `description`, `responsibilities?`, `qualifications?`, `location?`, `workMode?` (`WorkMode`), `compensation?`, `openings` (default `1`), `applicationUrl?`, `applicationDeadline?`, `startDate?`, `endDate?`, `status` (`OpportunityStatus`, default `DRAFT`), `publishedAt?`, `createdAt`, `updatedAt` | PK `id`. FK `companyId → Company.id` (final delete action `RESTRICT`). FD: `id →` all non-`id` attributes. Indexes on company/status, type/status, deadline, and creation time are not unique and imply no additional FDs. |
| **Application** — `id`, `studentProfileId`, `opportunityId`, `status` (`ApplicationStatus`, default `SUBMITTED`), `coverLetter?`, `recruiterRemarks?`, `createdAt`, `updatedAt` | PK `id`; UQ (`studentProfileId`, `opportunityId`). FKs: `studentProfileId → StudentProfile.id`; `opportunityId → Opportunity.id`. FDs: `id →` all non-`id` attributes; (`studentProfileId`, `opportunityId`) → `id, status, coverLetter, recruiterRemarks, createdAt, updatedAt`. |
| **ApplicationStatusHistory** — `id`, `applicationId`, `status` (`ApplicationStatus`), `remarks?`, `changedByUserId`, `createdAt` | PK `id`. FK `applicationId → Application.id`. **`changedByUserId` is not a declared FK** in the Prisma schema or migrations. FD: `id → applicationId, status, remarks, changedByUserId, createdAt`. |
| **Interview** — `id`, `applicationId`, `scheduledAt`, `location?`, `meetingUrl?`, `notes?`, `status` (`InterviewStatus`, default `SCHEDULED`), `createdAt`, `updatedAt` | PK `id`. FK `applicationId → Application.id`. FD: `id →` all non-`id` attributes. |
| **Internship** — `id`, `applicationId`, `studentProfileId`, `companyId`, `institutionId?`, `title`, `startDate?`, `endDate?`, `status` (`InternshipStatus`, default `OFFERED`), `notes?`, `createdAt`, `updatedAt` | PK `id`; UQ `applicationId`. FKs: `applicationId → Application.id`; `studentProfileId → StudentProfile.id`; `companyId → Company.id`; nullable `institutionId → Institution.id`. FDs: `id →` all non-`id` attributes; `applicationId →` all non-`applicationId` attributes. |
| **Placement** — `id`, `studentProfileId`, `institutionId?`, `companyId`, `role`, `placedAt` (default current time), `compensation?`, `notes?`, `createdAt`, `updatedAt` | PK `id`. FKs: `studentProfileId → StudentProfile.id`; nullable `institutionId → Institution.id`; `companyId → Company.id`. FD: `id →` all non-`id` attributes. |
| **Notification** — `id`, `userId`, `type`, `title`, `message`, `link?`, `readAt?`, `createdAt` (default current time) | PK `id`. FK `userId → User.id`. FD: `id → userId, type, title, message, link, readAt, createdAt`. |

The enum types are `Role`, `OpportunityType`, `OpportunityStatus`, `WorkMode`, `ProficiencyLevel`, `SkillSource`, `ApplicationStatus`, `InterviewStatus`, and `InternshipStatus`. They are not separate relations. The schema does not declare additional candidate keys for the models beyond those listed. In particular, no uniqueness is declared for an assessment title, an opportunity title, a result's student/assessment pair, or an option's text.

## Normalization analysis

### First Normal Form (1NF)

1NF requires each column value in each row to be atomic and prohibits repeating groups stored inside one field. In the existing schema, model fields are generally scalar values, and repeated relationships are represented as separate rows (for example, skills in `StudentSkill`, applications in `Application`, and questions in `AssessmentQuestion`).

The exception is `AssessmentQuestion.options`, a PostgreSQL `String[]`. It stores multiple option values in a single column and therefore violates strict 1NF atomicity. This is an existing-schema issue, not an already implemented table decomposition.

**Proposed 1NF decomposition** (the requested normalized design):

```text
AssessmentQuestion(
  id, assessmentId, question, correctAnswer, explanation
)

AssessmentQuestionOption(
  questionId, optionPosition, optionText
)

Primary key: (questionId, optionPosition)
Functional dependency: (questionId, optionPosition) -> optionText
```

`questionId` in `AssessmentQuestionOption` is a foreign key to `AssessmentQuestion.id`. `optionPosition` distinguishes each option belonging to one question. The composite key allows the same option text to occur more than once if the data contains it; no text uniqueness rule is declared. This decomposition is lossless for the options: joining the option rows back on `questionId` reconstructs the option collection for each question, with positions preserving order.

`correctAnswer` is retained as an integer in `AssessmentQuestion`. The schema and migrations do not document whether it is a zero-based or one-based option index, so this report makes no such assumption. Before implementing the decomposition, the application’s indexing convention should be checked so that the integer can be matched to `optionPosition` correctly.

All other existing columns are represented as scalar fields, including URLs, descriptions, and messages. Whether a free-text field contains multiple conceptual facts is not specified by the schema and is not enough by itself to assert a normalization violation.

### Second Normal Form (2NF)

2NF requires 1NF and no non-prime attribute depending on only part of a candidate key. Relations with a single-column primary key cannot have a partial dependency on that key. For relations with composite candidate keys:

- In `StudentSkill`, the candidate key (`studentProfileId`, `skillId`) identifies one student's association with one skill. `proficiencyLevel`, `source`, and timestamps describe that association; the schema declares no dependency of those attributes on only one component.
- In `Application`, (`studentProfileId`, `opportunityId`) identifies one application by a student for an opportunity. Application status and application-specific text/timestamps depend on the pair; neither FK alone identifies the application row under declared constraints.
- In proposed `AssessmentQuestionOption`, `optionText` depends on the complete key (`questionId`, `optionPosition`), not either key component alone.

The surrogate `id` keys on `StudentSkill` and `Application` do not remove the importance of their declared composite unique business keys; those pairs are candidate keys too. With the proposed option relation, the relations satisfy 2NF under the declared candidate keys.

### Third Normal Form (3NF)

3NF requires 2NF and disallows a non-key attribute depending transitively on a candidate key through another non-key attribute. Under the FDs declared by the schema's keys and unique constraints, no such transitive dependency is indicated within the existing relations. Entity details are held in their own relations and referenced by foreign keys: for example, opportunities reference companies instead of repeating company profile attributes, and applications reference students and opportunities.

The proposed option relation has only the key-based FD (`questionId`, `optionPosition`) → `optionText`; the remaining question attributes stay in `AssessmentQuestion`, determined by its `id`. Therefore, following the 1NF decomposition, the relations satisfy 3NF under the declared dependencies. This is a constraint-based analysis, not a claim that undocumented application-level rules cannot exist.

### Boyce-Codd Normal Form (BCNF)

BCNF requires every determinant in every non-trivial FD to be a superkey. Based on the supported FDs listed above, each determinant is a candidate key: a declared PK, a declared unique attribute, a declared composite unique pair, or the proposed option composite key. Thus, after decomposing `options`, all relations are in BCNF with respect to the FDs supported by the declared schema constraints.

This BCNF conclusion is intentionally limited to those FDs. A foreign key establishes a reference, not a dependency from the referencing row to the referenced row's other attributes within the same relation. No additional dependencies are inferred from naming conventions or assumed business rules.

## Final normalized relational schema (proposed)

This is the proposed normalized schema. The original database has 17 Prisma models/relations. Replacing the `options[]` attribute with the new `AssessmentQuestionOption` relation adds one relation, resulting in 18 relations. Nullable attributes and enum attributes are retained. Existing unique constraints are shown; FK references reflect the schema/migrations. `changedByUserId` remains an ordinary required attribute because no FK is declared for it.

```text
User(
  id PK, fullName, email UQ, password, phone NULL, role, isActive,
  createdAt, updatedAt
)

Institution(
  id PK, userId FK->User.id UQ, name, officialEmail UQ, website NULL,
  address NULL, description NULL, contactInfo NULL, isVerified,
  createdAt, updatedAt
)

StudentProfile(
  id PK, userId FK->User.id UQ, institutionId FK->Institution.id NULL,
  degree NULL, department NULL, graduationYear NULL, semester NULL,
  bio NULL, profileImage NULL, resumeUrl NULL, linkedIn NULL,
  github NULL, portfolio NULL, createdAt, updatedAt
)

Skill(
  id PK, name UQ, category, description NULL, createdAt, updatedAt
)

StudentSkill(
  id PK, studentProfileId FK->StudentProfile.id,
  skillId FK->Skill.id, proficiencyLevel, source, createdAt, updatedAt,
  UQ(studentProfileId, skillId)
)

Assessment(
  id PK, skillId FK->Skill.id, title, description NULL,
  totalQuestions, createdAt
)

AssessmentQuestion(
  id PK, assessmentId FK->Assessment.id, question,
  correctAnswer, explanation NULL
)

AssessmentQuestionOption(
  questionId FK->AssessmentQuestion.id, optionPosition, optionText,
  PK(questionId, optionPosition)
)

AssessmentResult(
  id PK, studentProfileId FK->StudentProfile.id,
  assessmentId FK->Assessment.id, score, percentage,
  proficiencyLevel, completedAt
)

LearningRecommendation(
  id PK, studentProfileId FK->StudentProfile.id,
  skillId FK->Skill.id, title, description, difficulty,
  resourceUrl NULL, priority, isCompleted, createdAt
)

Company(
  id PK, userId FK->User.id UQ, name, officialEmail UQ,
  website NULL, address NULL, description NULL, contactInfo NULL,
  isVerified, createdAt, updatedAt
)

Opportunity(
  id PK, companyId FK->Company.id, title, type, description,
  responsibilities NULL, qualifications NULL, location NULL,
  workMode NULL, compensation NULL, openings, applicationUrl NULL,
  applicationDeadline NULL, startDate NULL, endDate NULL, status,
  publishedAt NULL, createdAt, updatedAt
)

Application(
  id PK, studentProfileId FK->StudentProfile.id,
  opportunityId FK->Opportunity.id, status, coverLetter NULL,
  recruiterRemarks NULL, createdAt, updatedAt,
  UQ(studentProfileId, opportunityId)
)

ApplicationStatusHistory(
  id PK, applicationId FK->Application.id, status,
  remarks NULL, changedByUserId, createdAt
)

Interview(
  id PK, applicationId FK->Application.id, scheduledAt,
  location NULL, meetingUrl NULL, notes NULL, status,
  createdAt, updatedAt
)

Internship(
  id PK, applicationId FK->Application.id UQ,
  studentProfileId FK->StudentProfile.id, companyId FK->Company.id,
  institutionId FK->Institution.id NULL, title, startDate NULL,
  endDate NULL, status, notes NULL, createdAt, updatedAt
)

Placement(
  id PK, studentProfileId FK->StudentProfile.id,
  institutionId FK->Institution.id NULL, companyId FK->Company.id,
  role, placedAt, compensation NULL, notes NULL, createdAt, updatedAt
)

Notification(
  id PK, userId FK->User.id, type, title, message, link NULL,
  readAt NULL, createdAt
)
```

## Conclusion

The actual SkillBridge AI schema has 17 models/tables and is already organized into separate entity and relationship relations. Based on its declared keys and constraints, the existing relations satisfy 2NF and 3NF; the explicit issue for strict 1NF is the array-valued `AssessmentQuestion.options` field. Replacing that field with `AssessmentQuestionOption(questionId, optionPosition, optionText)` preserves option order and provides the stated composite key and FD. The resulting relations satisfy 1NF, 2NF, 3NF, and BCNF under the dependencies established by the schema. The meaning/indexing convention of `correctAnswer` remains to be confirmed from application behavior before implementing this proposed decomposition.
