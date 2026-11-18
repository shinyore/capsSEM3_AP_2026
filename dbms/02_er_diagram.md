# AP CP2: ER Diagram — SkillBridge AI

The diagram below represents the proposed normalized design: the 17 original Prisma models plus `AssessmentQuestionOption`, which replaces the `options[]` field on `AssessmentQuestion`. `PK`, `FK`, and `UK` mark primary keys, foreign keys, and individually unique attributes. Composite unique constraints are `StudentSkill(studentProfileId, skillId)` and `Application(studentProfileId, opportunityId)`. The other unique constraints are `User.email`, `Institution.userId`, `Institution.officialEmail`, `StudentProfile.userId`, `Skill.name`, `Company.userId`, `Company.officialEmail`, and `Internship.applicationId`. Prisma relation-navigation fields are omitted. `changedByUserId` is intentionally not an FK. `correctAnswer` remains an integer; its indexing convention is unspecified.

```mermaid
erDiagram
    User {
        string id PK
        string fullName
        string email UK
        string password
        string phone "nullable"
        Role role
        boolean isActive
        datetime createdAt
        datetime updatedAt
    }
    Institution {
        string id PK
        string userId FK, UK
        string name
        string officialEmail UK
        string website "nullable"
        string address "nullable"
        string description "nullable"
        string contactInfo "nullable"
        boolean isVerified
        datetime createdAt
        datetime updatedAt
    }
    StudentProfile {
        string id PK
        string userId FK, UK
        string institutionId FK "nullable"
        string degree "nullable"
        string department "nullable"
        int graduationYear "nullable"
        int semester "nullable"
        string bio "nullable"
        string profileImage "nullable"
        string resumeUrl "nullable"
        string linkedIn "nullable"
        string github "nullable"
        string portfolio "nullable"
        datetime createdAt
        datetime updatedAt
    }
    Skill {
        string id PK
        string name UK
        string category
        string description "nullable"
        datetime createdAt
        datetime updatedAt
    }
    StudentSkill {
        string id PK
        string studentProfileId FK
        string skillId FK
        ProficiencyLevel proficiencyLevel
        SkillSource source
        datetime createdAt
        datetime updatedAt
    }
    Assessment {
        string id PK
        string skillId FK
        string title
        string description "nullable"
        int totalQuestions
        datetime createdAt
    }
    AssessmentQuestion {
        string id PK
        string assessmentId FK
        string question
        int correctAnswer
        string explanation "nullable"
    }
    AssessmentQuestionOption {
        string questionId PK, FK
        int optionPosition PK
        string optionText
    }
    AssessmentResult {
        string id PK
        string studentProfileId FK
        string assessmentId FK
        int score
        float percentage
        ProficiencyLevel proficiencyLevel
        datetime completedAt
    }
    LearningRecommendation {
        string id PK
        string studentProfileId FK
        string skillId FK
        string title
        string description
        ProficiencyLevel difficulty
        string resourceUrl "nullable"
        int priority
        boolean isCompleted
        datetime createdAt
    }
    Company {
        string id PK
        string userId FK, UK
        string name
        string officialEmail UK
        string website "nullable"
        string address "nullable"
        string description "nullable"
        string contactInfo "nullable"
        boolean isVerified
        datetime createdAt
        datetime updatedAt
    }
    Opportunity {
        string id PK
        string companyId FK
        string title
        OpportunityType type
        string description
        string responsibilities "nullable"
        string qualifications "nullable"
        string location "nullable"
        WorkMode workMode "nullable"
        string compensation "nullable"
        int openings
        string applicationUrl "nullable"
        datetime applicationDeadline "nullable"
        datetime startDate "nullable"
        datetime endDate "nullable"
        OpportunityStatus status
        datetime publishedAt "nullable"
        datetime createdAt
        datetime updatedAt
    }
    Application {
        string id PK
        string studentProfileId FK
        string opportunityId FK
        ApplicationStatus status
        string coverLetter "nullable"
        string recruiterRemarks "nullable"
        datetime createdAt
        datetime updatedAt
    }
    ApplicationStatusHistory {
        string id PK
        string applicationId FK
        ApplicationStatus status
        string remarks "nullable"
        string changedByUserId
        datetime createdAt
    }
    Interview {
        string id PK
        string applicationId FK
        datetime scheduledAt
        string location "nullable"
        string meetingUrl "nullable"
        string notes "nullable"
        InterviewStatus status
        datetime createdAt
        datetime updatedAt
    }
    Internship {
        string id PK
        string applicationId FK, UK
        string studentProfileId FK
        string companyId FK
        string institutionId FK "nullable"
        string title
        datetime startDate "nullable"
        datetime endDate "nullable"
        InternshipStatus status
        string notes "nullable"
        datetime createdAt
        datetime updatedAt
    }
    Placement {
        string id PK
        string studentProfileId FK
        string institutionId FK "nullable"
        string companyId FK
        string role
        datetime placedAt
        string compensation "nullable"
        string notes "nullable"
        datetime createdAt
        datetime updatedAt
    }
    Notification {
        string id PK
        string userId FK
        string type
        string title
        string message
        string link "nullable"
        datetime readAt "nullable"
        datetime createdAt
    }

    User ||--o| Institution : "account for"
    User ||--o| StudentProfile : "account for"
    User ||--o| Company : "account for"
    User ||--o{ Notification : receives
    Institution o|--o{ StudentProfile : affiliates
    Institution o|--o{ Internship : hosts
    Institution o|--o{ Placement : records
    StudentProfile ||--o{ StudentSkill : has
    Skill ||--o{ StudentSkill : assessed_as
    Skill ||--o{ Assessment : covers
    Assessment ||--o{ AssessmentQuestion : contains
    AssessmentQuestion ||--o{ AssessmentQuestionOption : has_options
    StudentProfile ||--o{ AssessmentResult : earns
    Assessment ||--o{ AssessmentResult : receives
    StudentProfile ||--o{ LearningRecommendation : receives
    Skill ||--o{ LearningRecommendation : recommends_for
    Company ||--o{ Opportunity : posts
    StudentProfile ||--o{ Application : submits
    Opportunity ||--o{ Application : receives
    Application ||--o{ ApplicationStatusHistory : records
    Application ||--o{ Interview : schedules
    Application ||--o| Internship : may_lead_to
    StudentProfile ||--o{ Internship : undertakes
    Company ||--o{ Internship : provides
    StudentProfile ||--o{ Placement : obtains
    Company ||--o{ Placement : employs
```
