# Wall-D: Complete Implementation Guide
## A-Z Detailed Technical Roadmap with Code Patterns & Prototypes

**Version:** 2.0 - Implementation Deep Dive  
**Target Stack:** .NET MAUI 8.0+, WinUI3, Firebase Firestore, Cloud Functions  
**Document Status:** Production-Ready Reference  
**Date:** December 2025  

---

## TABLE OF CONTENTS

1. [Project File Structure](#1-project-file-structure)
2. [Firebase Data Architecture](#2-firebase-data-architecture)
3. [Core Implementation Strategy](#3-core-implementation-strategy)
4. [Phase 1 Deep Dive: Foundation](#4-phase-1-deep-dive-foundation)
5. [Real-Life Problems & Solutions](#5-real-life-problems--solutions)
6. [Screen Prototypes & Specifications](#6-screen-prototypes--specifications)
7. [Form System Implementation](#7-form-system-implementation)
8. [Organization Hierarchy Deep Dive](#8-organization-hierarchy-deep-dive)
9. [Authentication & Security Implementation](#9-authentication--security-implementation)
10. [Real-Time Sync Architecture](#10-real-time-sync-architecture)
11. [Approval Workflow Engine](#11-approval-workflow-engine)
12. [Notification System](#12-notification-system)
13. [Performance & Optimization](#13-performance--optimization)
14. [Testing Strategy](#14-testing-strategy)
15. [Deployment & DevOps](#15-deployment--devops)

---

## 1. PROJECT FILE STRUCTURE

### 1.1 Complete Directory Organization

```
WallD/
│
├── src/
│   ├── WallD.Core/                          # Domain logic, models, interfaces
│   │   ├── Models/
│   │   │   ├── Entities/
│   │   │   │   ├── User.cs
│   │   │   │   ├── Task.cs
│   │   │   │   ├── Approval.cs
│   │   │   │   ├── Organization.cs
│   │   │   │   ├── Designation.cs
│   │   │   │   ├── Form.cs
│   │   │   │   └── Notification.cs
│   │   │   ├── ValueObjects/
│   │   │   │   ├── UserId.cs
│   │   │   │   ├── TaskId.cs
│   │   │   │   ├── Priority.cs
│   │   │   │   ├── TaskStatus.cs
│   │   │   │   └── ApprovalStatus.cs
│   │   │   └── ViewModels/
│   │   │       ├── TaskViewModel.cs
│   │   │       ├── UserViewModel.cs
│   │   │       └── OrganizationViewModel.cs
│   │   │
│   │   ├── Services/Interfaces/
│   │   │   ├── IAuthenticationService.cs
│   │   │   ├── ITaskService.cs
│   │   │   ├── IApprovalService.cs
│   │   │   ├── IOrganizationService.cs
│   │   │   ├── IFormService.cs
│   │   │   ├── INotificationService.cs
│   │   │   └── ISyncService.cs
│   │   │
│   │   ├── Repositories/
│   │   │   ├── IRepository.cs (base interface)
│   │   │   ├── IUserRepository.cs
│   │   │   ├── ITaskRepository.cs
│   │   │   ├── IApprovalRepository.cs
│   │   │   └── IOrganizationRepository.cs
│   │   │
│   │   └── Constants/
│   │       ├── FirestorePaths.cs
│   │       ├── FirestoreCollections.cs
│   │       └── ErrorMessages.cs
│   │
│   ├── WallD.Infrastructure/                # Firebase, external services
│   │   ├── Firebase/
│   │   │   ├── FirebaseInitializer.cs
│   │   │   ├── FirestoreService.cs
│   │   │   ├── FirebaseAuthService.cs
│   │   │   ├── RealtimeDbService.cs
│   │   │   └── CloudStorageService.cs
│   │   │
│   │   ├── Repositories/Implementations/
│   │   │   ├── FirestoreUserRepository.cs
│   │   │   ├── FirestoreTaskRepository.cs
│   │   │   ├── FirestoreApprovalRepository.cs
│   │   │   └── FirestoreOrganizationRepository.cs
│   │   │
│   │   ├── Services/Implementations/
│   │   │   ├── AuthenticationService.cs
│   │   │   ├── TaskService.cs
│   │   │   ├── ApprovalService.cs
│   │   │   ├── NotificationService.cs
│   │   │   ├── SyncService.cs
│   │   │   └── FormService.cs
│   │   │
│   │   ├── Mapping/
│   │   │   └── EntityMappings.cs
│   │   │
│   │   └── Configuration/
│   │       └── FirebaseConfig.json
│   │
│   ├── WallD.Application/                   # Business logic, use cases
│   │   ├── UseCases/
│   │   │   ├── Authentication/
│   │   │   │   ├── RegisterUserUseCase.cs
│   │   │   │   ├── LoginUserUseCase.cs
│   │   │   │   └── LogoutUserUseCase.cs
│   │   │   │
│   │   │   ├── Tasks/
│   │   │   │   ├── CreateTaskUseCase.cs
│   │   │   │   ├── AssignTaskUseCase.cs
│   │   │   │   ├── CompleteTaskUseCase.cs
│   │   │   │   └── GetMyTasksUseCase.cs
│   │   │   │
│   │   │   ├── Approvals/
│   │   │   │   ├── ApproveTaskUseCase.cs
│   │   │   │   ├── RejectTaskUseCase.cs
│   │   │   │   └── GetPendingApprovalsUseCase.cs
│   │   │   │
│   │   │   └── Organization/
│   │   │       ├── CreateOrgNodeUseCase.cs
│   │   │       ├── GetHierarchyUseCase.cs
│   │   │       └── UpdateDesignationUseCase.cs
│   │   │
│   │   ├── Validators/
│   │   │   ├── TaskValidator.cs
│   │   │   ├── UserValidator.cs
│   │   │   └── FormValidator.cs
│   │   │
│   │   └── DTOs/
│   │       ├── TaskDTO.cs
│   │       ├── UserDTO.cs
│   │       ├── ApprovalDTO.cs
│   │       └── OrganizationDTO.cs
│   │
│   ├── WallD.UI/                            # MAUI WinUI3 UI
│   │   ├── Pages/
│   │   │   ├── Authentication/
│   │   │   │   ├── LoginPage.xaml
│   │   │   │   ├── LoginPage.xaml.cs
│   │   │   │   ├── RegisterPage.xaml
│   │   │   │   └── RegisterPage.xaml.cs
│   │   │   │
│   │   │   ├── Screens/
│   │   │   │   ├── DeveloperScreen/
│   │   │   │   │   ├── DeveloperScreenPage.xaml
│   │   │   │   │   ├── DeveloperScreenPage.xaml.cs
│   │   │   │   │   ├── OrganizationBuilderView.xaml
│   │   │   │   │   ├── DesignationManagerView.xaml
│   │   │   │   │   ├── FormSchemaEditorView.xaml
│   │   │   │   │   └── SystemLogsView.xaml
│   │   │   │   │
│   │   │   │   ├── AdminScreen/
│   │   │   │   │   ├── AdminScreenPage.xaml
│   │   │   │   │   ├── AdminScreenPage.xaml.cs
│   │   │   │   │   ├── UserManagementView.xaml
│   │   │   │   │   ├── FormConfigView.xaml
│   │   │   │   │   └── ApprovalQueueView.xaml
│   │   │   │   │
│   │   │   │   ├── ManagerScreen/
│   │   │   │   │   ├── ManagerScreenPage.xaml
│   │   │   │   │   ├── ManagerScreenPage.xaml.cs
│   │   │   │   │   ├── TaskManagementView.xaml
│   │   │   │   │   ├── TeamDashboardView.xaml
│   │   │   │   │   ├── ApprovalWidget.xaml
│   │   │   │   │   └── AnalyticsView.xaml
│   │   │   │   │
│   │   │   │   └── EmployeeScreen/
│   │   │   │       ├── EmployeeScreenPage.xaml
│   │   │   │       ├── EmployeeScreenPage.xaml.cs
│   │   │   │       ├── MyTasksView.xaml
│   │   │   │       ├── TaskDetailView.xaml
│   │   │   │       └── PerformanceView.xaml
│   │   │   │
│   │   │   └── Shared/
│   │   │       ├── MainWindow.xaml
│   │   │       ├── MainWindow.xaml.cs
│   │   │       └── ScreenSelector.xaml
│   │   │
│   │   ├── Controls/
│   │   │   ├── TaskCard.xaml
│   │   │   ├── ApprovalCard.xaml
│   │   │   ├── DynamicForm.xaml
│   │   │   ├── OrganizationTreeView.xaml
│   │   │   ├── UserAvatar.xaml
│   │   │   └── StatusBadge.xaml
│   │   │
│   │   ├── ViewModels/
│   │   │   ├── ViewModelBase.cs
│   │   │   ├── LoginViewModel.cs
│   │   │   ├── DeveloperScreenViewModel.cs
│   │   │   ├── ManagerScreenViewModel.cs
│   │   │   ├── EmployeeScreenViewModel.cs
│   │   │   ├── TaskDetailViewModel.cs
│   │   │   └── DynamicFormViewModel.cs
│   │   │
│   │   ├── Converters/
│   │   │   ├── TaskStatusToColorConverter.cs
│   │   │   ├── PriorityToIconConverter.cs
│   │   │   ├── DateToDaysRemainingConverter.cs
│   │   │   └── BoolToVisibilityConverter.cs
│   │   │
│   │   ├── Resources/
│   │   │   ├── Styles/
│   │   │   │   ├── Colors.xaml
│   │   │   │   ├── Typography.xaml
│   │   │   │   ├── Spacing.xaml
│   │   │   │   └── ControlStyles.xaml
│   │   │   │
│   │   │   └── Themes/
│   │   │       ├── Light.xaml
│   │   │       └── Dark.xaml
│   │   │
│   │   ├── Services/
│   │   │   ├── NavigationService.cs
│   │   │   ├── DialogService.cs
│   │   │   └── ThemeService.cs
│   │   │
│   │   └── App.xaml.cs
│   │
│   └── WallD/                               # MAUI startup project
│       ├── MauiProgram.cs
│       ├── GlobalUsings.cs
│       └── Resources/
│           └── AppShell.xaml
│
├── tests/
│   ├── WallD.Core.Tests/
│   │   ├── Models/
│   │   └── Services/
│   │
│   ├── WallD.Application.Tests/
│   │   ├── UseCases/
│   │   └── Validators/
│   │
│   ├── WallD.Infrastructure.Tests/
│   │   ├── Firebase/
│   │   └── Repositories/
│   │
│   └── WallD.UI.Tests/
│       ├── ViewModels/
│       └── Converters/
│
├── docs/
│   ├── API_REFERENCE.md
│   ├── FIREBASE_SCHEMA.md
│   ├── ARCHITECTURE.md
│   └── TROUBLESHOOTING.md
│
├── scripts/
│   ├── firebase-setup.sh
│   ├── seed-demo-data.js
│   └── deploy.sh
│
├── config/
│   ├── firebase-config.dev.json
│   ├── firebase-config.prod.json
│   └── appsettings.json
│
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── build.yml
│       └── deploy.yml
│
├── WallD.sln
├── Directory.Build.props
├── nuget.config
└── README.md
```

### 1.2 Project File Organization Rationale

**Core Layer** (WallD.Core):
- Pure domain models, no dependencies on infrastructure
- Interfaces for repositories and services
- Business logic contracts
- Value objects and entities

**Infrastructure Layer** (WallD.Infrastructure):
- Firebase implementation details
- Repository implementations
- External service integrations
- Configuration and initialization

**Application Layer** (WallD.Application):
- Use cases (business workflows)
- DTOs (data transfer objects)
- Validators (input validation)
- No direct UI dependencies

**UI Layer** (WallD.UI):
- MAUI XAML pages and controls
- ViewModels (MVVM pattern)
- Converters and behaviors
- Navigation and theming

---

## 2. FIREBASE DATA ARCHITECTURE

### 2.1 Complete Firestore Schema

```
firestore/
│
├── tenants/
│   └── {tenantId}/
│       │
│       ├── metadata/
│       │   ├── company_info
│       │   │   ├── name: "Acme Corporation"
│       │   │   ├── logo_url: "gs://..."
│       │   │   ├── industry: "Manufacturing"
│       │   │   ├── country: "IN"
│       │   │   ├── timezone: "Asia/Kolkata"
│       │   │   ├── created_at: timestamp
│       │   │   └── updated_at: timestamp
│       │   │
│       │   ├── designations
│       │   │   ├── doc_id: "ceo"
│       │   │   │   ├── name: "Chief Executive Officer"
│       │   │   │   ├── description: "C-level executive"
│       │   │   │   ├── hierarchy_level: 1
│       │   │   │   ├── parent_designations: ["board_member"]
│       │   │   │   ├── permissions: ["all_access", "system_admin"]
│       │   │   │   ├── default_roles: ["admin", "manager", "developer"]
│       │   │   │   ├── screen_access: ["developer", "admin", "manager"]
│       │   │   │   ├── requires_approval: false
│       │   │   │   ├── approval_by_designation: null
│       │   │   │   ├── icon: "👔"
│       │   │   │   ├── color: "#FF6B35"
│       │   │   │   └── active: true
│       │   │   │
│       │   │   ├── doc_id: "manager"
│       │   │   │   ├── name: "Department Manager"
│       │   │   │   ├── hierarchy_level: 3
│       │   │   │   ├── parent_designations: ["ceo", "vp"]
│       │   │   │   ├── permissions: ["create_task", "assign_task", "approve_task"]
│       │   │   │   ├── screen_access: ["manager"]
│       │   │   │   ├── requires_approval: true
│       │   │   │   ├── approval_by_designation: "vp"
│       │   │   │   └── [...]
│       │   │   │
│       │   │   └── doc_id: "employee"
│       │   │       ├── name: "Employee"
│       │   │       ├── hierarchy_level: 5
│       │   │       ├── permissions: ["view_task", "update_task", "complete_task"]
│       │   │       ├── screen_access: ["employee"]
│       │   │       └── [...]
│       │   │
│       │   ├── form_schemas
│       │   │   ├── doc_id: "user_registration"
│       │   │   │   ├── name: "User Registration Form"
│       │   │   │   ├── description: "New user onboarding"
│       │   │   │   ├── version: 1
│       │   │   │   ├── created_at: timestamp
│       │   │   │   ├── updated_at: timestamp
│       │   │   │   ├── active: true
│       │   │   │   ├── sections: [
│       │   │   │   │   {
│       │   │   │   │     "id": "personal_info",
│       │   │   │   │     "title": "Personal Information",
│       │   │   │   │     "description": "Enter your details",
│       │   │   │   │     "fields": [
│       │   │   │   │       {
│       │   │   │   │         "id": "full_name",
│       │   │   │   │         "type": "text",
│       │   │   │   │         "label": "Full Name",
│       │   │   │   │         "placeholder": "John Doe",
│       │   │   │   │         "required": true,
│       │   │   │   │         "validation": "^[a-zA-Z\\s]{3,50}$",
│       │   │   │   │         "error_message": "Name must be 3-50 characters",
│       │   │   │   │         "help_text": "Your full legal name"
│       │   │   │   │       },
│       │   │   │   │       {
│       │   │   │   │         "id": "email",
│       │   │   │   │         "type": "email",
│       │   │   │   │         "label": "Email Address",
│       │   │   │   │         "required": true,
│       │   │   │   │         "validation": "email",
│       │   │   │   │         "unique_check": true
│       │   │   │   │       },
│       │   │   │   │       {
│       │   │   │   │         "id": "designation",
│       │   │   │   │         "type": "dropdown",
│       │   │   │   │         "label": "Your Designation",
│       │   │   │   │         "required": true,
│       │   │   │   │         "data_source": {
│       │   │   │   │           "type": "firestore",
│       │   │   │   │           "collection": "designations",
│       │   │   │   │           "display_field": "name",
│       │   │   │   │           "value_field": "id",
│       │   │   │   │           "filter": { "active": true }
│       │   │   │   │         }
│       │   │   │   │       }
│       │   │   │   │     ]
│       │   │   │   │   }
│       │   │   │   │]
│       │   │   │   └── workflow: {
│       │   │   │       "on_submit": "validateAndSubmit",
│       │   │   │       "on_validate": "checkEmailUnique",
│       │   │   │       "next_step": "requestApproval"
│       │   │   │     }
│       │   │   │
│       │   │   └── doc_id: "task_creation"
│       │   │       └── [...]
│       │   │
│       │   ├── workflow_definitions
│       │   │   ├── doc_id: "task_approval_workflow"
│       │   │   │   ├── name: "Task Approval Workflow"
│       │   │   │   ├── trigger: "task_completed"
│       │   │   │   ├── steps: [
│       │   │   │   │   {
│       │   │   │   │     "level": 1,
│       │   │   │   │     "name": "Team Lead Review",
│       │   │   │   │     "approver_type": "designation",
│       │   │   │   │     "approver_id": "team_lead",
│       │   │   │   │     "timeout_hours": 24,
│       │   │   │   │     "escalate_to": "manager"
│       │   │   │   │   },
│       │   │   │   │   {
│       │   │   │   │     "level": 2,
│       │   │   │   │     "name": "Manager Approval",
│       │   │   │   │     "approver_type": "hierarchy",
│       │   │   │   │     "approver_id": "parent",
│       │   │   │   │     "timeout_hours": 48,
│       │   │   │   │     "escalate_to": "ceo"
│       │   │   │   │   }
│       │   │   │   ]
│       │   │   │   └── enabled: true
│       │   │   │
│       │   │   └── doc_id: "registration_approval_workflow"
│       │   │       └── [...]
│       │   │
│       │   ├── role_permissions
│       │   │   ├── doc_id: "admin"
│       │   │   │   ├── name: "Administrator"
│       │   │   │   ├── permissions: [
│       │   │   │   │   "user.create",
│       │   │   │   │   "user.read",
│       │   │   │   │   "user.update",
│       │   │   │   │   "user.delete",
│       │   │   │   │   "organization.manage",
│       │   │   │   │   "form.manage"
│       │   │   │   │ ]
│       │   │   │   └── screen_access: ["admin", "manager"]
│       │   │   │
│       │   │   └── doc_id: "employee"
│       │   │       ├── permissions: [
│       │   │   │   │   "task.read",
│       │   │   │   │   "task.update",
│       │   │   │   │   "task.complete"
│       │   │   │   │ ]
│       │   │   │   └── screen_access: ["employee"]
│       │   │
│       │   └── settings
│       │       ├── notification_preferences: {
│       │       │   "email_on_task_assigned": true,
│       │       │   "sms_on_urgent": true,
│       │       │   "do_not_disturb_hours": "20:00-08:00"
│       │       │ }
│       │       ├── features: {
│       │       │   "offline_mode": true,
│       │       │   "two_factor_auth": true,
│       │       │   "sso": false
│       │       │ }
│       │       └── limits: {
│       │           "max_users": 500,
│       │           "max_tasks_per_day": 1000
│       │         }
│       │
│       ├── users/
│       │   └── {userId}/
│       │       ├── profile
│       │       │   ├── email: "john.doe@acme.com"
│       │       │   ├── full_name: "John Doe"
│       │       │   ├── avatar_url: "gs://..."
│       │       │   ├── phone: "+91-9876543210"
│       │       │   ├── designation_id: "manager"
│       │       │   ├── organization_node_id: "org_node_sales_north"
│       │       │   ├── manager_user_id: "user_2"
│       │       │   ├── status: "active" (active/pending_approval/rejected/inactive)
│       │       │   ├── created_at: timestamp
│       │       │   ├── approved_at: timestamp
│       │       │   ├── approved_by: "user_1"
│       │       │   ├── last_login_at: timestamp
│       │       │   ├── timezone: "Asia/Kolkata"
│       │       │   └── preferences: {
│       │       │       "theme": "light",
│       │       │       "language": "en",
│       │       │       "notification_settings": {...}
│       │       │     }
│       │       │
│       │       ├── roles/
│       │       │   ├── {roleId}/
│       │       │   │   ├── role_id: "admin"
│       │       │   │   ├── assigned_at: timestamp
│       │       │   │   └── assigned_by: "user_1"
│       │       │
│       │       └── security
│       │           ├── password_hash: "bcrypt_hash..."
│       │           ├── password_changed_at: timestamp
│       │           ├── mfa_enabled: false
│       │           ├── mfa_secret: "encrypted_secret"
│       │           ├── login_attempts: 0
│       │           ├── last_failed_login: null
│       │           └── sessions: [
│       │               {
│       │                 "session_id": "uuid",
│       │                 "token": "jwt_token...",
│       │                 "device_fingerprint": "hash",
│       │                 "created_at": timestamp,
│       │                 "expires_at": timestamp
│       │               }
│       │             ]
│       │
│       ├── organizations/
│       │   └── {orgNodeId}/
│       │       ├── metadata
│       │       │   ├── id: "org_node_sales_north"
│       │       │   ├── name: "Sales - North Region"
│       │       │   ├── description: "Northern sales division"
│       │       │   ├── type: "region" (region/department/team/division)
│       │       │   ├── code: "SN001"
│       │       │   ├── parent_id: "org_node_sales"
│       │       │   ├── manager_user_id: "user_2"
│       │       │   ├── hierarchy_level: 2
│       │       │   ├── created_at: timestamp
│       │       │   ├── updated_at: timestamp
│       │       │   └── active: true
│       │       │
│       │       ├── children/
│       │       │   ├── {childOrgNodeId}
│       │       │   └── {childOrgNodeId}
│       │       │
│       │       └── members/
│       │           ├── {userId}/
│       │           │   ├── user_id: "user_123"
│       │           │   ├── added_at: timestamp
│       │           │   ├── role_in_org: "member"
│       │           │   └── permissions: [...]
│       │
│       ├── tasks/
│       │   └── {taskId}/
│       │       ├── title: "Database Migration"
│       │       ├── description: "Migrate from MySQL to PostgreSQL"
│       │       ├── created_by: "user_1"
│       │       ├── created_at: timestamp
│       │       ├── updated_at: timestamp
│       │       ├── assignee_id: "user_2"
│       │       ├── assigned_at: timestamp
│       │       ├── organization_node_id: "org_node_dev"
│       │       ├── status: "in_progress" (pending/assigned/in_progress/blocked/completed)
│       │       ├── priority: "high" (low/medium/high/critical)
│       │       ├── due_date: timestamp
│       │       ├── estimated_hours: 8
│       │       ├── actual_hours: 6.5
│       │       ├── completed_at: null
│       │       ├── completion_percentage: 75
│       │       ├── requires_approval: true
│       │       ├── approval_status: "pending" (pending/approved/rejected)
│       │       ├── approved_by: null
│       │       ├── approved_at: null
│       │       ├── project_id: "proj_001"
│       │       ├── custom_fields: {
│       │       │   "cost_center": "CC-2024-001",
│       │       │   "customer_id": "CUST-123",
│       │       │   "severity": "medium"
│       │       │ }
│       │       ├── tags: ["database", "migration", "urgent"]
│       │       └── attachments/
│       │           ├── {attachmentId}
│       │           │   ├── file_name: "migration_plan.pdf"
│       │           │   ├── file_size: 2048000
│       │           │   ├── file_url: "gs://..."
│       │           │   ├── uploaded_by: "user_1"
│       │           │   └── uploaded_at: timestamp
│       │
│       ├── approvals/
│       │   └── {approvalId}/
│       │       ├── task_id: "task_123"
│       │       ├── approver_user_id: "user_2"
│       │       ├── approval_level: 1
│       │       ├── status: "pending" (pending/approved/rejected)
│       │       ├── created_at: timestamp
│       │       ├── expires_at: timestamp (48 hours from creation)
│       │       ├── response_at: null
│       │       ├── notes: null
│       │       ├── approved_by: null
│       │       ├── rejection_reason: null
│       │       └── next_approver_id: "user_3"
│       │
│       ├── notifications/
│       │   └── {notificationId}/
│       │       ├── recipient_user_id: "user_2"
│       │       ├── type: "task_assigned" (task_assigned/task_overdue/approval_required)
│       │       ├── title: "New task assigned to you"
│       │       ├── message: "Setup Database has been assigned to you"
│       │       ├── related_entity: {
│       │       │   "type": "task",
│       │       │   "id": "task_123"
│       │       │ }
│       │       ├── priority: "normal" (low/normal/high/urgent)
│       │       ├── channels: ["in_app", "email", "sms"]
│       │       ├── created_at: timestamp
│       │       ├── read_at: null
│       │       ├── action_url: "/tasks/task_123"
│       │       └── expires_at: timestamp
│       │
│       ├── audit_logs/
│       │   └── {logId}/
│       │       ├── actor_user_id: "user_1"
│       │       ├── action: "task_created" (task_created/task_updated/approval_given)
│       │       ├── resource_type: "task"
│       │       ├── resource_id: "task_123"
│       │       ├── changes: {
│       │       │   "status": { "from": null, "to": "created" },
│       │       │   "assignee": { "from": null, "to": "user_2" }
│       │       │ }
│       │       ├── before_state: {...}
│       │       ├── after_state: {...}
│       │       ├── timestamp: timestamp
│       │       ├── ip_address: "192.168.1.1"
│       │       └── user_agent: "Mozilla/5.0..."
│       │
│       └── temp/
│           ├── pending_registrations/
│           │   └── {registrationId}/
│           │       ├── email: "newuser@acme.com"
│           │       ├── full_name: "New User"
│           │       ├── proposed_designation: "employee"
│           │       ├── created_at: timestamp
│           │       ├── expires_at: timestamp (7 days)
│           │       ├── verification_token: "random_token"
│           │       └── status: "pending" (pending/approved/rejected/expired)
│           │
│           └── sync_queues/
│               └── {userId}/
│                   ├── pending_changes: [
│                       {
│                         "id": "change_uuid",
│                         "action": "update_task",
│                         "entity_id": "task_123",
│                         "data": {...},
│                         "created_at": timestamp,
│                         "synced": false
│                       }
│                     ]

```

### 2.2 Firebase Collection Indexing Strategy

```
Firestore Indexes (Composite):

1. Tasks Collection:
   ├─ Fields to Index:
   │  ├─ (tenant_id, organization_node_id, status)
   │  ├─ (tenant_id, assignee_id, status)
   │  ├─ (tenant_id, due_date, status)
   │  └─ (tenant_id, created_at DESC)
   │
   └─ Purpose: Enable efficient queries by assignee, org node, status, deadline

2. Approvals Collection:
   ├─ Fields to Index:
   │  ├─ (tenant_id, approver_id, status)
   │  ├─ (tenant_id, task_id, approval_level)
   │  └─ (tenant_id, created_at DESC)
   │
   └─ Purpose: Show pending approvals, approval chain tracking

3. Users Collection:
   ├─ Fields to Index:
   │  ├─ (tenant_id, status)
   │  ├─ (tenant_id, organization_node_id)
   │  └─ (tenant_id, designation_id)
   │
   └─ Purpose: Filter users by status, org, role

4. Notifications Collection:
   ├─ Fields to Index:
   │  ├─ (recipient_user_id, read_at, created_at DESC)
   │  ├─ (recipient_user_id, type)
   │  └─ (tenant_id, created_at DESC)
   │
   └─ Purpose: Get user's unread notifications, filter by type

Firestore Query Patterns:
├─ "Get my tasks" = Query tasks by assignee + not completed
├─ "Get overdue tasks" = Query tasks by due_date + not completed
├─ "Get approvals waiting for me" = Query approvals by approver + pending
├─ "Get team tasks" = Query tasks by org_node + date range
└─ "Get user notifications" = Query notifications by recipient + recent
```

### 2.3 Firebase Realtime Database Structure (for live updates)

```
rtdb/
└── sync_channels/
    ├── tenants/{tenantId}/
    │   ├── tasks/{taskId}/
    │   │   ├── status: "in_progress"
    │   │   ├── updated_at: timestamp
    │   │   └── updated_by: "user_1"
    │   │
    │   ├── approvals/{approvalId}/
    │   │   ├── status: "pending"
    │   │   └── updated_at: timestamp
    │   │
    │   └── users/{userId}/
    │       └── online_status: true
    │
    └── notifications/{userId}/
        ├── unread_count: 5
        └── last_notification: {
            "id": "notif_123",
            "timestamp": timestamp,
            "type": "task_assigned"
          }
```

---

## 3. CORE IMPLEMENTATION STRATEGY

### 3.1 Layered Architecture Pattern

```
PRESENTATION LAYER (WallD.UI)
│
├─ XAML Pages (MainWindow, LoginPage, ScreenPages)
├─ ViewModels (MVVM pattern, data binding)
├─ Controls (reusable UI components)
├─ Converters (value converters for binding)
└─ Navigation (screen routing)
        ↓
APPLICATION LAYER (WallD.Application)
│
├─ Use Cases (business workflows)
├─ DTOs (data transfer between layers)
├─ Validators (input validation)
└─ Mappers (convert between DTOs and domain models)
        ↓
DOMAIN LAYER (WallD.Core)
│
├─ Entities (User, Task, Approval, etc.)
├─ Value Objects (Priority, Status, etc.)
├─ Service Interfaces (contracts)
└─ Repository Interfaces (data access contracts)
        ↓
INFRASTRUCTURE LAYER (WallD.Infrastructure)
│
├─ Firebase Implementation
├─ Repository Implementations
├─ Service Implementations
└─ External Integrations
```

### 3.2 Design Patterns Used

```
1. MVVM (Model-View-ViewModel)
   └─ UI Layer: Decouples UI from business logic
   └─ Data binding: Automatic UI updates
   └─ Command pattern: Button clicks, user actions

2. Repository Pattern
   └─ Abstracts data access layer
   └─ Easy to test with mock repositories
   └─ Easy to switch data sources (Firestore to SQL)

3. Dependency Injection
   └─ Loose coupling between components
   └─ Constructor injection in MauiProgram.cs
   └─ ServiceProvider for runtime resolution

4. Factory Pattern
   └─ Entity creation (Task, Approval, User)
   └─ Firebase document conversion

5. Observer Pattern
   └─ Real-time notifications
   └─ Property change notifications
   └─ Reactive streams (Rx.NET)

6. Strategy Pattern
   └─ Different approval strategies
   └─ Different escalation rules
   └─ Different notification channels

7. Async/Await Pattern
   └─ Non-blocking Firebase calls
   └─ Task composition
   └─ Error handling with try-catch
```

---

## 4. PHASE 1 DEEP DIVE: FOUNDATION

### 4.1 MauiProgram.cs - Dependency Injection Setup

```csharp
using Microsoft.Maui;
using Microsoft.Maui.Hosting;
using WallD.Infrastructure.Firebase;
using WallD.Infrastructure.Repositories;
using WallD.Infrastructure.Services;
using WallD.Application.Services;
using WallD.UI.ViewModels;
using WallD.UI.Pages;

namespace WallD;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();
        
        builder
            .UseMauiApp<App>()
            .ConfigureFonts(fonts =>
            {
                fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
                fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
            });

        // ===== FIREBASE CONFIGURATION =====
        ConfigureFirebase(builder);

        // ===== DEPENDENCY INJECTION =====
        // Infrastructure Services
        builder.Services.AddSingleton<FirebaseInitializer>();
        builder.Services.AddSingleton<FirestoreService>();
        builder.Services.AddSingleton<FirebaseAuthService>();
        builder.Services.AddSingleton<RealtimeDbService>();

        // Repositories
        builder.Services.AddSingleton<IUserRepository, FirestoreUserRepository>();
        builder.Services.AddSingleton<ITaskRepository, FirestoreTaskRepository>();
        builder.Services.AddSingleton<IApprovalRepository, FirestoreApprovalRepository>();
        builder.Services.AddSingleton<IOrganizationRepository, FirestoreOrganizationRepository>();

        // Application Services
        builder.Services.AddSingleton<IAuthenticationService, AuthenticationService>();
        builder.Services.AddSingleton<ITaskService, TaskService>();
        builder.Services.AddSingleton<IApprovalService, ApprovalService>();
        builder.Services.AddSingleton<ISyncService, SyncService>();
        builder.Services.AddSingleton<INotificationService, NotificationService>();

        // UI Services
        builder.Services.AddSingleton<NavigationService>();
        builder.Services.AddSingleton<DialogService>();
        builder.Services.AddSingleton<ThemeService>();

        // ViewModels
        builder.Services.AddSingleton<LoginViewModel>();
        builder.Services.AddSingleton<RegisterViewModel>();
        builder.Services.AddSingleton<DeveloperScreenViewModel>();
        builder.Services.AddSingleton<AdminScreenViewModel>();
        builder.Services.AddSingleton<ManagerScreenViewModel>();
        builder.Services.AddSingleton<EmployeeScreenViewModel>();

        // Pages
        builder.Services.AddSingleton<LoginPage>();
        builder.Services.AddSingleton<RegisterPage>();
        builder.Services.AddSingleton<MainWindow>();
        builder.Services.AddSingleton<ScreenSelector>();

        // AppShell (navigation)
        builder.Services.AddSingleton<AppShell>();

        return builder.Build();
    }

    private static void ConfigureFirebase(MauiAppBuilder builder)
    {
        // Load Firebase configuration
        var firebaseConfig = new FirebaseConfig
        {
            ApiKey = "YOUR_API_KEY",
            ProjectId = "your-project-id",
            StorageBucket = "your-project.appspot.com",
            MessagingSenderId = "YOUR_SENDER_ID",
            AppId = "YOUR_APP_ID"
        };

        // Initialize Firebase
        builder.Services.AddSingleton(firebaseConfig);
    }
}
```

### 4.2 Firebase Initialization Service

```csharp
using Firebase;
using Firebase.Auth;
using Firebase.Firestore;
using Firebase.Database;
using System.Collections.Generic;

namespace WallD.Infrastructure.Firebase;

public class FirebaseInitializer
{
    private static FirebaseApp _firebaseApp;
    private static FirebaseAuth _auth;
    private static FirebaseFirestore _firestore;
    private static FirebaseDatabase _realtimeDb;

    private readonly FirebaseConfig _config;
    private readonly ILogger<FirebaseInitializer> _logger;

    public FirebaseInitializer(FirebaseConfig config, ILogger<FirebaseInitializer> logger)
    {
        _config = config;
        _logger = logger;
    }

    public async Task InitializeAsync()
    {
        try
        {
            _logger.LogInformation("Initializing Firebase...");

            // Initialize Firebase App
            var options = new FirebaseOptions
            {
                ApiKey = _config.ApiKey,
                ProjectId = _config.ProjectId,
                StorageBucket = _config.StorageBucket,
                MessagingSenderId = _config.MessagingSenderId,
                AppId = _config.AppId,
                DatabaseUrl = $"https://{_config.ProjectId}.firebaseio.com"
            };

            if (FirebaseApp.DefaultInstance == null)
            {
                _firebaseApp = FirebaseApp.Create(options);
                _logger.LogInformation("Firebase App created");
            }
            else
            {
                _firebaseApp = FirebaseApp.DefaultInstance;
                _logger.LogInformation("Using existing Firebase App instance");
            }

            // Initialize Auth
            _auth = FirebaseAuth.DefaultInstance;
            _logger.LogInformation("Firebase Auth initialized");

            // Initialize Firestore
            _firestore = FirebaseFirestore.GetInstance(_firebaseApp);
            _logger.LogInformation("Firestore initialized");

            // Initialize Realtime Database
            _realtimeDb = FirebaseDatabase.GetInstance(_firebaseApp);
            _logger.LogInformation("Realtime Database initialized");

            _logger.LogInformation("Firebase initialization completed successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Firebase initialization failed");
            throw;
        }
    }

    public static FirebaseAuth GetAuth() => _auth 
        ?? throw new InvalidOperationException("Firebase not initialized");

    public static FirebaseFirestore GetFirestore() => _firestore 
        ?? throw new InvalidOperationException("Firestore not initialized");

    public static FirebaseDatabase GetRealtimeDb() => _realtimeDb 
        ?? throw new InvalidOperationException("Realtime DB not initialized");
}

public class FirebaseConfig
{
    public string ApiKey { get; set; }
    public string ProjectId { get; set; }
    public string StorageBucket { get; set; }
    public string MessagingSenderId { get; set; }
    public string AppId { get; set; }
}
```

### 4.3 Firestore Service Base

```csharp
using Firebase.Firestore;
using System.Collections.Generic;
using System.Linq;

namespace WallD.Infrastructure.Firebase;

public class FirestoreService
{
    private readonly FirebaseFirestore _firestore;
    private readonly ILogger<FirestoreService> _logger;
    private string _currentTenantId;
    private string _currentUserId;

    public FirestoreService(ILogger<FirestoreService> logger)
    {
        _firestore = FirebaseInitializer.GetFirestore();
        _logger = logger;
    }

    public void SetTenantContext(string tenantId, string userId)
    {
        _currentTenantId = tenantId;
        _currentUserId = userId;
    }

    // Generic CRUD Operations
    public async Task<T> GetDocumentAsync<T>(string collection, string documentId) 
        where T : class
    {
        try
        {
            var docSnapshot = await _firestore
                .Collection($"tenants/{_currentTenantId}/{collection}")
                .Document(documentId)
                .GetAsync();

            if (!docSnapshot.Exists)
                return null;

            return docSnapshot.ConvertTo<T>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error getting document {documentId} from {collection}");
            throw;
        }
    }

    public async Task<List<T>> GetCollectionAsync<T>(string collection, 
        Query.Filter filter = null) 
        where T : class
    {
        try
        {
            var query = (Query)_firestore
                .Collection($"tenants/{_currentTenantId}/{collection}");

            if (filter != null)
                query = query.Where(filter);

            var snapshot = await query.GetAsync();

            return snapshot.Documents
                .Select(d => d.ConvertTo<T>())
                .ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error querying collection {collection}");
            throw;
        }
    }

    public async Task<string> CreateDocumentAsync<T>(string collection, T data) 
        where T : class
    {
        try
        {
            var docRef = await _firestore
                .Collection($"tenants/{_currentTenantId}/{collection}")
                .AddAsync(data);

            _logger.LogInformation($"Document created in {collection}: {docRef.Id}");
            return docRef.Id;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error creating document in {collection}");
            throw;
        }
    }

    public async Task UpdateDocumentAsync<T>(string collection, string documentId, T data) 
        where T : class
    {
        try
        {
            await _firestore
                .Collection($"tenants/{_currentTenantId}/{collection}")
                .Document(documentId)
                .SetAsync(data, SetOptions.MergeAll);

            _logger.LogInformation($"Document updated in {collection}: {documentId}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error updating document {documentId} in {collection}");
            throw;
        }
    }

    public async Task DeleteDocumentAsync(string collection, string documentId)
    {
        try
        {
            await _firestore
                .Collection($"tenants/{_currentTenantId}/{collection}")
                .Document(documentId)
                .DeleteAsync();

            _logger.LogInformation($"Document deleted from {collection}: {documentId}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error deleting document {documentId} from {collection}");
            throw;
        }
    }

    // Real-time listeners
    public IDisposable ListenToDocument<T>(string collection, string documentId, 
        Action<T> onNext, Action<Exception> onError = null) 
        where T : class
    {
        return _firestore
            .Collection($"tenants/{_currentTenantId}/{collection}")
            .Document(documentId)
            .AddSnapshotListener((snapshot, error) =>
            {
                if (error != null)
                {
                    onError?.Invoke(error);
                    _logger.LogError(error, $"Snapshot listener error for {documentId}");
                    return;
                }

                if (snapshot != null && snapshot.Exists)
                {
                    var data = snapshot.ConvertTo<T>();
                    onNext(data);
                }
            });
    }

    public IDisposable ListenToCollection<T>(string collection, 
        Action<List<T>> onNext, Action<Exception> onError = null) 
        where T : class
    {
        return _firestore
            .Collection($"tenants/{_currentTenantId}/{collection}")
            .AddSnapshotListener((snapshot, error) =>
            {
                if (error != null)
                {
                    onError?.Invoke(error);
                    _logger.LogError(error, $"Snapshot listener error for collection {collection}");
                    return;
                }

                if (snapshot != null)
                {
                    var data = snapshot.Documents
                        .Select(d => d.ConvertTo<T>())
                        .ToList();
                    onNext(data);
                }
            });
    }
}
```

---

## 5. REAL-LIFE PROBLEMS & SOLUTIONS

### Problem 1: Offline Sync Queue (Critical for field teams)

**Issue:**
```
Scenario: Field technician in remote location, internet drops while 
creating task, phone loses connection. What happens?

Current Implementation (NAIVE):
├─ User submits task
├─ No internet → Firebase call fails
├─ Error shown to user
├─ User frustrated, creates same task again
├─ When online, duplicate tasks created
└─ Data integrity compromised
```

**Solution: Offline-First Architecture with SQLite Cache**

```csharp
// WallD.Infrastructure/Services/SyncService.cs

public class SyncService : ISyncService
{
    private readonly FirestoreService _firestore;
    private readonly ISQLiteRepository _cache;
    private readonly ILogger<SyncService> _logger;
    private readonly Connectivity _connectivity;
    private Queue<PendingChange> _offlineQueue = new();

    public async Task<T> CreateWithOfflineAsync<T>(string collection, T entity) 
        where T : class, IEntity
    {
        try
        {
            // Step 1: Generate UUID locally
            entity.Id = Guid.NewGuid().ToString();
            entity.CreatedAt = DateTime.UtcNow;

            // Step 2: Save to local cache immediately
            await _cache.InsertAsync(collection, entity);
            _logger.LogInformation($"Entity cached locally: {entity.Id}");

            // Step 3: Try Firebase (if online)
            if (_connectivity.NetworkAccess == NetworkAccess.Internet)
            {
                try
                {
                    await _firestore.CreateDocumentAsync(collection, entity);
                    _logger.LogInformation($"Entity synced to Firebase: {entity.Id}");
                    
                    // Mark as synced in cache
                    await _cache.MarkAsSyncedAsync(collection, entity.Id);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, $"Firebase sync failed, queuing for retry: {entity.Id}");
                    await QueueForSyncAsync(collection, entity);
                }
            }
            else
            {
                _logger.LogInformation("Offline mode: Entity queued for sync");
                await QueueForSyncAsync(collection, entity);
            }

            return entity;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in CreateWithOfflineAsync");
            throw;
        }
    }

    private async Task QueueForSyncAsync(string collection, IEntity entity)
    {
        var change = new PendingChange
        {
            Id = Guid.NewGuid().ToString(),
            Collection = collection,
            EntityId = entity.Id,
            Action = "create",
            Data = JsonConvert.SerializeObject(entity),
            CreatedAt = DateTime.UtcNow,
            Synced = false
        };

        await _cache.InsertAsync("pending_changes", change);
        _offlineQueue.Enqueue(change);
    }

    public async Task SyncPendingChangesAsync()
    {
        if (_connectivity.NetworkAccess != NetworkAccess.Internet)
        {
            _logger.LogWarning("Not online, cannot sync");
            return;
        }

        var pendingChanges = await _cache.GetAsync<PendingChange>(
            "pending_changes", 
            c => !c.Synced
        );

        foreach (var change in pendingChanges)
        {
            try
            {
                // Retry logic with exponential backoff
                var maxRetries = 3;
                var retryCount = 0;

                while (retryCount < maxRetries)
                {
                    try
                    {
                        var data = JsonConvert.DeserializeObject(change.Data);
                        
                        switch (change.Action)
                        {
                            case "create":
                                await _firestore.CreateDocumentAsync(
                                    change.Collection, 
                                    data
                                );
                                break;

                            case "update":
                                await _firestore.UpdateDocumentAsync(
                                    change.Collection, 
                                    change.EntityId, 
                                    data
                                );
                                break;

                            case "delete":
                                await _firestore.DeleteDocumentAsync(
                                    change.Collection, 
                                    change.EntityId
                                );
                                break;
                        }

                        // Mark as synced
                        change.Synced = true;
                        change.SyncedAt = DateTime.UtcNow;
                        await _cache.UpdateAsync("pending_changes", change);

                        _logger.LogInformation(
                            $"Synced pending change: {change.Id}"
                        );
                        break; // Success, exit retry loop
                    }
                    catch (Exception ex) when (retryCount < maxRetries - 1)
                    {
                        retryCount++;
                        var delayMs = (int)Math.Pow(2, retryCount) * 1000;
                        _logger.LogWarning(
                            $"Sync retry {retryCount}/{maxRetries} " +
                            $"after {delayMs}ms: {change.Id}"
                        );
                        await Task.Delay(delayMs);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to sync change {change.Id}");
                // Don't throw, continue with next change
            }
        }
    }
}

// SQLite Local Cache Implementation
public class SQLiteRepository : ISQLiteRepository
{
    private readonly SQLiteAsyncConnection _connection;
    private readonly string _dbPath;

    public SQLiteRepository()
    {
        _dbPath = Path.Combine(
            FileSystem.CacheDirectory, 
            "walld_offline.db3"
        );
        _connection = new SQLiteAsyncConnection(_dbPath);
        Initialize();
    }

    private async void Initialize()
    {
        await _connection.CreateTableAsync<CachedEntity>();
        await _connection.CreateTableAsync<PendingChange>();
    }

    public async Task<List<T>> GetAsync<T>(string table, 
        Func<T, bool> predicate) 
        where T : class, new()
    {
        var all = await _connection.Table<T>().ToListAsync();
        return all.Where(predicate).ToList();
    }

    public async Task InsertAsync<T>(string table, T entity) 
        where T : class
    {
        await _connection.InsertAsync(entity);
    }

    public async Task UpdateAsync<T>(string table, T entity) 
        where T : class
    {
        await _connection.UpdateAsync(entity);
    }
}
```

### Problem 2: Multi-Level Approval Deadlock

**Issue:**
```
Scenario: Employee completes task, needs 3-level approval:
1. Team Lead (approval level 1) - MISSING/INACTIVE
2. Manager (approval level 2)
3. Director (approval level 3)

Current Issue:
├─ Task stuck at level 1
├─ Team Lead on vacation
├─ Manager can't approve until TL approves
├─ Task SLA violated
└─ No escalation logic
```

**Solution: Intelligent Escalation & Delegation**

```csharp
// WallD.Application/UseCases/Approvals/CreateApprovalChainUseCase.cs

public class CreateApprovalChainUseCase
{
    private readonly IApprovalRepository _approvalRepository;
    private readonly IUserRepository _userRepository;
    private readonly IOrganizationRepository _orgRepository;
    private readonly INotificationService _notificationService;
    private readonly FirestoreService _firestore;

    public async Task<ApprovalChain> ExecuteAsync(string taskId, 
        WorkflowDefinition workflow)
    {
        var chain = new ApprovalChain { TaskId = taskId };

        for (int level = 0; level < workflow.Steps.Count; level++)
        {
            var step = workflow.Steps[level];

            // Step 1: Determine approver based on strategy
            var approver = await ResolveApproverAsync(step, taskId);

            // Step 2: Handle missing/inactive approver
            if (approver == null || !approver.IsActive)
            {
                approver = await FindDelegateAsync(step);
                
                if (approver == null)
                {
                    _logger.LogWarning(
                        $"No available approver for level {level}, escalating"
                    );
                    // Escalate to parent level
                    approver = await EscalateToParentAsync(step);
                }
            }

            // Step 3: Create approval record
            var approval = new Approval
            {
                Id = Guid.NewGuid().ToString(),
                TaskId = taskId,
                ApproverId = approver.Id,
                Level = level,
                Status = "pending",
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddHours(step.TimeoutHours),
                NextApproverId = level < workflow.Steps.Count - 1 
                    ? null 
                    : await ResolveApproverAsync(workflow.Steps[level + 1], taskId)
                      |> (u => u?.Id)
            };

            chain.Approvals.Add(approval);
            await _approvalRepository.CreateAsync(approval);

            // Step 4: Notify approver
            await _notificationService.NotifyApprovalRequiredAsync(
                approval.ApproverId,
                taskId,
                step.Name
            );
        }

        return chain;
    }

    private async Task<User> ResolveApproverAsync(
        WorkflowStep step, 
        string taskId)
    {
        if (step.ApproverType == "designation")
        {
            // Find user with this designation
            var users = await _userRepository.GetByDesignationAsync(
                step.ApproverId
            );
            return users.FirstOrDefault(u => u.Status == "active");
        }
        else if (step.ApproverType == "hierarchy")
        {
            // Find parent in hierarchy
            var task = await _firestore.GetDocumentAsync<Domain.Task>(
                "tasks", 
                taskId
            );
            var assignee = await _userRepository.GetAsync(
                task.AssigneeId
            );
            return await FindParentManagerAsync(assignee);
        }

        return null;
    }

    private async Task<User> FindDelegateAsync(WorkflowStep step)
    {
        // Check if there's an active delegate assigned
        var delegates = await _userRepository.GetDelegatesAsync(
            step.ApproverId
        );
        
        var activeDelegate = delegates
            .Where(d => d.Status == "active" && d.DelegationActive)
            .FirstOrDefault();

        return activeDelegate;
    }

    private async Task<User> EscalateToParentAsync(WorkflowStep step)
    {
        if (string.IsNullOrEmpty(step.EscalateTo))
            return null;

        var escalationDesignation = await _firestore.GetDocumentAsync<Designation>(
            "metadata/designations",
            step.EscalateTo
        );

        var users = await _userRepository.GetByDesignationAsync(
            escalationDesignation.Id
        );

        return users.FirstOrDefault(u => u.Status == "active");
    }
}

// WallD.Core/Models/Entities/ApprovalChain.cs
public class ApprovalChain
{
    public string TaskId { get; set; }
    public List<Approval> Approvals { get; set; } = new();
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public bool IsBlocked => Approvals.Any(a => 
        a.Status == "pending" && a.ExpiresAt < DateTime.UtcNow
    );

    public int CurrentLevel => Approvals.Count(a => a.Status == "approved");
    public bool IsComplete => Approvals.All(a => a.Status == "approved");
}
```

### Problem 3: Concurrent Task Updates (Race Condition)

**Issue:**
```
Manager A and B both update same task simultaneously:

T1: Manager A reads task.status = "pending"
T2: Manager B reads task.status = "pending"
T3: Manager A updates task.status = "in_progress" + saves
T4: Manager B updates task.status = "in_review" + saves
Result: B's update wins (last-write-wins), A's change lost
```

**Solution: Optimistic Locking with Version Numbers**

```csharp
// WallD.Core/Models/Entities/Task.cs
public class Task : IEntity
{
    public string Id { get; set; }
    public string Title { get; set; }
    public string Status { get; set; }
    public int Version { get; set; } // Optimistic lock
    public DateTime UpdatedAt { get; set; }
    
    [Ignore]  // Don't serialize to Firebase
    public DateTime LastLocalUpdateAt { get; set; }
}

// WallD.Infrastructure/Repositories/FirestoreTaskRepository.cs
public class FirestoreTaskRepository : ITaskRepository
{
    public async Task<bool> UpdateWithLockAsync(Task task)
    {
        try
        {
            // Create a transaction
            var batch = _firestore.Batch();

            // Get current version from Firebase
            var docSnapshot = await _firestore
                .Collection("tenants/{tenantId}/tasks")
                .Document(task.Id)
                .GetAsync();

            if (!docSnapshot.Exists)
                throw new EntityNotFoundException($"Task {task.Id} not found");

            var currentVersion = docSnapshot.Get("version") as int? ?? 0;

            // Check if versions match
            if (currentVersion != task.Version)
            {
                _logger.LogWarning(
                    $"Version mismatch for task {task.Id}: " +
                    $"expected {task.Version}, got {currentVersion}"
                );
                
                // Return false to indicate conflict
                return false;
            }

            // Update version + data atomically
            task.Version++;
            task.UpdatedAt = DateTime.UtcNow;

            var updateDict = new Dictionary<string, object>
            {
                { "status", task.Status },
                { "updated_at", task.UpdatedAt },
                { "version", task.Version }
            };

            batch.Update(
                _firestore
                    .Collection("tenants/{tenantId}/tasks")
                    .Document(task.Id),
                updateDict
            );

            await batch.CommitAsync();
            _logger.LogInformation($"Task {task.Id} updated successfully");

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Update with lock failed");
            throw;
        }
    }
}

// Usage in ViewModel
public class TaskDetailViewModel : ViewModelBase
{
    public async Task UpdateTaskStatusAsync(string newStatus)
    {
        try
        {
            _task.Status = newStatus;
            
            // Try to update with optimistic lock
            bool success = await _taskRepository.UpdateWithLockAsync(_task);

            if (!success)
            {
                // Conflict! Show user
                await _dialogService.ShowAsync(
                    "Conflict",
                    "This task was updated by another user. " +
                    "Refreshing changes...",
                    "OK"
                );

                // Refresh task from Firebase
                _task = await _taskRepository.GetAsync(_task.Id);
                OnPropertyChanged(nameof(Task));
            }
            else
            {
                await _dialogService.ShowAsync(
                    "Success",
                    "Task updated successfully",
                    "OK"
                );
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating task");
            await _dialogService.ShowErrorAsync("Error", ex.Message);
        }
    }
}
```

---

## 6. SCREEN PROTOTYPES & SPECIFICATIONS

### 6.1 Login Screen Prototype

```
┌─────────────────────────────────────────────────────────┐
│                    WALL-D LOGIN                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│                    [Logo]                               │
│                   Wall-D Pro                            │
│            Enterprise Task Management                   │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ Email Address                                      │ │
│  │ ┌─────────────────────────────────────────────┐  │ │
│  │ │ user@company.com                            │  │ │
│  │ └─────────────────────────────────────────────┘  │ │
│  │ Error: (none shown if valid)                      │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ Password                                           │ │
│  │ ┌─────────────────────────────────────────────┐  │ │
│  │ │ ••••••••                              [eye]│  │ │
│  │ └─────────────────────────────────────────────┘  │ │
│  │ ☐ Remember me (30 days)                          │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  [LOGIN]  (DISABLED if not all fields filled)     │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│        ───────────────────────────────────────         │
│              Don't have an account?                    │
│              [Create New Account]                      │
│                                                         │
│        ───────────────────────────────────────         │
│        [Forgot Password?]                              │
│        [Contact Support]                               │
│                                                         │
│                                                         │
│  Status: ⚫ Offline Mode (No connection detected)      │
│                                                         │
└─────────────────────────────────────────────────────────┘

XAML CODE:
<ContentPage
    x:Class="WallD.UI.Pages.LoginPage"
    Title="Login">

    <Grid RowDefinitions="*,Auto" RowSpacing="20" Padding="20">
        
        <!-- Content -->
        <ScrollView Grid.Row="0">
            <VerticalStackLayout Spacing="20">
                
                <!-- Logo Section -->
                <VerticalStackLayout Spacing="10" HorizontalOptions="Center">
                    <Image 
                        Source="walld_logo.png"
                        WidthRequest="80"
                        HeightRequest="80" />
                    <Label 
                        Text="Wall-D Pro"
                        FontSize="28"
                        FontAttributes="Bold"
                        HorizontalTextAlignment="Center" />
                    <Label 
                        Text="Enterprise Task Management"
                        FontSize="14"
                        TextColor="#666"
                        HorizontalTextAlignment="Center" />
                </VerticalStackLayout>

                <!-- Email Field -->
                <VerticalStackLayout Spacing="5">
                    <Label 
                        Text="Email Address"
                        FontSize="12"
                        FontAttributes="Bold" />
                    <Entry
                        x:Name="EmailEntry"
                        Placeholder="user@company.com"
                        Keyboard="Email"
                        IsTextPredictionEnabled="False"
                        ClearButtonVisibility="WhileEditing"
                        Text="{Binding Email}" />
                    <Label
                        x:Name="EmailError"
                        Text="{Binding EmailError}"
                        TextColor="#FF6B6B"
                        FontSize="11"
                        IsVisible="{Binding HasEmailError}" />
                </VerticalStackLayout>

                <!-- Password Field -->
                <VerticalStackLayout Spacing="5">
                    <Label 
                        Text="Password"
                        FontSize="12"
                        FontAttributes="Bold" />
                    <Grid ColumnDefinitions="*,50">
                        <Entry
                            x:Name="PasswordEntry"
                            Grid.Column="0"
                            Placeholder="Enter your password"
                            IsPassword="{Binding IsPasswordHidden}"
                            Text="{Binding Password}" />
                        <Button
                            Grid.Column="1"
                            Text="{Binding PasswordToggleIcon}"
                            Command="{Binding TogglePasswordCommand}"
                            BackgroundColor="Transparent" />
                    </Grid>
                    <Label
                        x:Name="PasswordError"
                        Text="{Binding PasswordError}"
                        TextColor="#FF6B6B"
                        FontSize="11"
                        IsVisible="{Binding HasPasswordError}" />
                </VerticalStackLayout>

                <!-- Remember Me -->
                <CheckBox
                    IsChecked="{Binding RememberMe}"
                    Color="#216485" />
                <Label 
                    Text="Remember me (30 days)"
                    FontSize="12"
                    Margin="0,-50,0,0" />

                <!-- Login Button -->
                <Button
                    Text="LOGIN"
                    Command="{Binding LoginCommand}"
                    IsEnabled="{Binding IsLoginButtonEnabled}"
                    BackgroundColor="#216485"
                    TextColor="White"
                    CornerRadius="8"
                    Padding="0,15"
                    FontSize="14"
                    FontAttributes="Bold" />

                <!-- Divider -->
                <Label 
                    Text="─────────────────────────"
                    HorizontalTextAlignment="Center"
                    FontSize="11"
                    TextColor="#CCC" />

                <!-- Links -->
                <VerticalStackLayout Spacing="10" HorizontalOptions="Center">
                    <Label 
                        Text="Don't have an account?"
                        FontSize="12" />
                    <Label 
                        Text="Create New Account"
                        FontSize="12"
                        TextColor="#216485"
                        TextDecorations="Underline">
                        <Label.GestureRecognizers>
                            <TapGestureRecognizer 
                                Command="{Binding NavigateToRegisterCommand}" />
                        </Label.GestureRecognizers>
                    </Label>
                </VerticalStackLayout>

                <!-- Forgot Password -->
                <Label 
                    Text="Forgot Password?"
                    FontSize="12"
                    TextColor="#216485"
                    HorizontalTextAlignment="Center"
                    TextDecorations="Underline">
                    <Label.GestureRecognizers>
                        <TapGestureRecognizer 
                            Command="{Binding ForgotPasswordCommand}" />
                    </Label.GestureRecognizers>
                </Label>

            </VerticalStackLayout>
        </ScrollView>

        <!-- Status Bar -->
        <Grid 
            Grid.Row="1"
            ColumnDefinitions="Auto,*"
            Padding="0,10,0,0"
            BorderStroke="#EEE"
            BorderStrokeThickness="1,1,0,0">
            
            <ActivityIndicator
                Grid.Column="0"
                IsRunning="{Binding IsLoading}"
                Color="#216485"
                WidthRequest="20"
                HeightRequest="20" />
            
            <Label
                Grid.Column="1"
                Text="{Binding StatusMessage}"
                FontSize="11"
                TextColor="#666"
                Margin="10,0" />
        </Grid>

    </Grid>

</ContentPage>

CODE-BEHIND:
public partial class LoginPage : ContentPage
{
    private readonly LoginViewModel _viewModel;

    public LoginPage(LoginViewModel viewModel)
    {
        InitializeComponent();
        _viewModel = viewModel;
        BindingContext = _viewModel;
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await _viewModel.OnAppearingAsync();
    }
}

VIEWMODEL:
public class LoginViewModel : ViewModelBase
{
    private string _email;
    private string _password;
    private bool _rememberMe;
    private bool _isPasswordHidden = true;
    private bool _isLoading;
    private string _statusMessage = "";

    [ObservableProperty]
    private string email;

    [ObservableProperty]
    private string password;

    [ObservableProperty]
    private bool rememberMe;

    public Command LoginCommand { get; }
    public Command NavigateToRegisterCommand { get; }
    public Command ForgotPasswordCommand { get; }
    public Command TogglePasswordCommand { get; }

    private readonly IAuthenticationService _authService;
    private readonly NavigationService _navigationService;
    private readonly ILogger<LoginViewModel> _logger;

    public LoginViewModel(
        IAuthenticationService authService,
        NavigationService navigationService,
        ILogger<LoginViewModel> logger)
    {
        _authService = authService;
        _navigationService = navigationService;
        _logger = logger;

        LoginCommand = new Command(async () => await LoginAsync());
        NavigateToRegisterCommand = new Command(
            async () => await NavigateToRegisterAsync()
        );
        ForgotPasswordCommand = new Command(
            async () => await ForgotPasswordAsync()
        );
        TogglePasswordCommand = new Command(
            () => IsPasswordHidden = !IsPasswordHidden
        );
    }

    private async Task LoginAsync()
    {
        try
        {
            IsLoading = true;
            StatusMessage = "Logging in...";

            // Validate input
            if (string.IsNullOrWhiteSpace(Email))
            {
                EmailError = "Email is required";
                HasEmailError = true;
                return;
            }

            if (!Email.Contains("@"))
            {
                EmailError = "Invalid email format";
                HasEmailError = true;
                return;
            }

            if (string.IsNullOrWhiteSpace(Password))
            {
                PasswordError = "Password is required";
                HasPasswordError = true;
                return;
            }

            // Attempt login
            var result = await _authService.LoginAsync(Email, Password);

            if (result.Success)
            {
                StatusMessage = "Login successful!";
                
                // Save credentials if Remember Me is checked
                if (RememberMe)
                {
                    await SecureStorage.SetAsync("saved_email", Email);
                }

                // Navigate to home
                await _navigationService.NavigateToAsync("///home");
            }
            else
            {
                StatusMessage = result.Message;
                await Application.Current.MainPage.DisplayAlert(
                    "Login Failed",
                    result.Message,
                    "OK"
                );
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Login error");
            StatusMessage = "Login failed";
            await Application.Current.MainPage.DisplayAlert(
                "Error",
                "An error occurred during login",
                "OK"
            );
        }
        finally
        {
            IsLoading = false;
        }
    }

    public async Task OnAppearingAsync()
    {
        // Load saved email if Remember Me was used
        var savedEmail = await SecureStorage.GetAsync("saved_email");
        if (!string.IsNullOrEmpty(savedEmail))
        {
            Email = savedEmail;
            RememberMe = true;
        }
    }
}
```

### 6.2 Manager Screen Layout

```
┌──────────────────────────────────────────────────────────┐
│ Wall-D │ Manager: John Smith │ Org: Sales-North │ Logout │
├────────┬──────────────────────────────────────────────────┤
│ NAV    │ MAIN CONTENT AREA                                │
├────────┼──────────────────────────────────────────────────┤
│        │  DASHBOARD                                       │
│        │                                                  │
│ ◆ Dash │  ┌─────────────────────┐  ┌──────────────────┐  │
│ ◆ Tasks│  │ Tasks Due Today     │  │ Pending          │  │
│ ◆ Team │  │ ┌────────────────┐  │  │ Approvals        │  │
│ ◆ Appr │  │ │ 5              │  │  │ ┌──────────────┐ │  │
│ ◆ Ana  │  │ └────────────────┘  │  │ │ 3            │ │  │
│ ◆ Repo │  └─────────────────────┘  │ └──────────────┘ │  │
│ ◆ Team │                            └──────────────────┘  │
│ ◆ Sett │  ┌─────────────────────┐  ┌──────────────────┐  │
│        │  │ Team Performance    │  │ Overdue Tasks    │  │
│        │  │ ├─ John: 85%       │  │ ├─ Setup DB (2d) │  │
│        │  │ ├─ Jane: 92%       │  │ ├─ QA Review (1d)│  │
│        │  │ └─ Mike: 78%       │  │ └─ Code Review   │  │
│        │  └─────────────────────┘  └──────────────────┘  │
│        │                                                  │
│        │  RECENT TASKS                                    │
│        │  ┌────────────────────────────────────────────┐  │
│        │  │ [+] CREATE NEW TASK                        │  │
│        │  │                                            │  │
│        │  │ 1. Setup Database        (IN_PROGRESS)    │  │
│        │  │    Assigned: Ram         Due: Tomorrow    │  │
│        │  │    [DETAILS] [EDIT] [APPROVE]            │  │
│        │  │                                            │  │
│        │  │ 2. Security Audit        (PENDING_REVIEW) │  │
│        │  │    Assigned: Priya       Due: 2 days     │  │
│        │  │    [DETAILS] [APPROVE] [REJECT]         │  │
│        │  │                                            │  │
│        │  │ 3. Code Review          (COMPLETED)       │  │
│        │  │    Assigned: Sam         Closed: 1 day ago│  │
│        │  │                                            │  │
│        │  └────────────────────────────────────────────┘  │
│        │                                                  │
│        │  Status: ✓ Synced | Last: 2 mins ago         │  │
└────────┴──────────────────────────────────────────────────┘

XAML STRUCTURE:
<ContentPage
    x:Class="WallD.UI.Pages.Screens.ManagerScreen.ManagerScreenPage"
    Title="Manager Dashboard">

    <Grid RowDefinitions="60,*" ColumnDefinitions="200,*">
        
        <!-- Header -->
        <Grid Grid.Row="0" Grid.ColumnSpan="2" BackgroundColor="#216485">
            <Label Text="Wall-D" TextColor="White" FontAttributes="Bold" />
            <Label Text="{Binding UserName}" TextColor="White" FontSize="12" />
            <Button 
                Text="Logout"
                Command="{Binding LogoutCommand}"
                BackgroundColor="Transparent"
                TextColor="White"
                HorizontalOptions="End" />
        </Grid>

        <!-- Navigation -->
        <CollectionView Grid.Row="1" Grid.Column="0" ItemsSource="{Binding NavItems}">
            <CollectionView.ItemTemplate>
                <DataTemplate>
                    <StackLayout Padding="15">
                        <Label 
                            Text="{Binding Icon}"
                            FontSize="18" />
                        <Label 
                            Text="{Binding Title}"
                            FontSize="12" />
                    </StackLayout>
                </DataTemplate>
            </CollectionView.ItemTemplate>
            <CollectionView.SelectionChangedCommand>
                <MultiBinding Converter="{StaticResource EventArgsConverter}">
                    <Binding Path="SelectNavItemCommand" />
                </MultiBinding>
            </CollectionView.SelectionChangedCommand>
        </CollectionView>

        <!-- Main Content -->
        <ContentControl
            Grid.Row="1"
            Grid.Column="1"
            Content="{Binding CurrentView}" />

    </Grid>

</ContentPage>
```

---

## 7. FORM SYSTEM IMPLEMENTATION

### 7.1 Dynamic Form Schema to XAML Converter

```csharp
// WallD.UI/Services/DynamicFormBuilder.cs

public class DynamicFormBuilder
{
    private readonly FirestoreService _firestore;
    private readonly ILogger<DynamicFormBuilder> _logger;

    public async Task<Grid> BuildFormAsync(string formId)
    {
        try
        {
            // Fetch form schema from Firestore
            var formSchema = await _firestore.GetDocumentAsync<FormSchema>(
                "metadata/form_schemas",
                formId
            );

            if (formSchema == null)
                throw new InvalidOperationException($"Form {formId} not found");

            // Create main grid
            var mainGrid = new Grid
            {
                RowDefinitions = new RowDefinitionCollection(),
                ColumnDefinitions = "*, *"
            };

            int rowIndex = 0;

            // Build sections
            foreach (var section in formSchema.Sections)
            {
                // Section title
                mainGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
                var sectionTitle = new Label
                {
                    Text = section.Title,
                    FontSize = 16,
                    FontAttributes = FontAttributes.Bold,
                    Margin = new Thickness(0, 15, 0, 10)
                };
                Grid.SetRow(sectionTitle, rowIndex);
                Grid.SetColumnSpan(sectionTitle, 2);
                mainGrid.Add(sectionTitle);
                rowIndex++;

                // Section description
                if (!string.IsNullOrEmpty(section.Description))
                {
                    mainGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
                    var sectionDesc = new Label
                    {
                        Text = section.Description,
                        FontSize = 12,
                        TextColor = "#666",
                        Margin = new Thickness(0, 0, 0, 10)
                    };
                    Grid.SetRow(sectionDesc, rowIndex);
                    Grid.SetColumnSpan(sectionDesc, 2);
                    mainGrid.Add(sectionDesc);
                    rowIndex++;
                }

                // Build fields
                foreach (var field in section.Fields)
                {
                    mainGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

                    var fieldControl = BuildField(field);
                    var columnSpan = field.ColumnSpan ?? 1;

                    Grid.SetRow(fieldControl, rowIndex);
                    Grid.SetColumn(fieldControl, (field.Column ?? 0) % 2);
                    if (columnSpan == 2)
                        Grid.SetColumnSpan(fieldControl, 2);

                    mainGrid.Add(fieldControl);

                    if ((field.Column ?? 0) % 2 == 1 || columnSpan == 2)
                        rowIndex++;
                }
            }

            // Add submit buttons
            mainGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            var buttonGrid = new Grid
            {
                ColumnDefinitions = "*, *",
                ColumnSpacing = 10,
                Margin = new Thickness(0, 20, 0, 0)
            };

            var submitBtn = new Button
            {
                Text = "SUBMIT",
                BackgroundColor = Color.FromArgb("#216485"),
                TextColor = Colors.White,
                Command = new Command(async () => await OnSubmitAsync(formSchema))
            };
            Grid.SetColumn(submitBtn, 0);
            buttonGrid.Add(submitBtn);

            var cancelBtn = new Button
            {
                Text = "CANCEL",
                BackgroundColor = Color.FromArgb("#F0F0F0"),
                TextColor = Color.FromArgb("#666"),
                Command = new Command(() => OnCancel())
            };
            Grid.SetColumn(cancelBtn, 1);
            buttonGrid.Add(cancelBtn);

            Grid.SetRow(buttonGrid, rowIndex);
            Grid.SetColumnSpan(buttonGrid, 2);
            mainGrid.Add(buttonGrid);

            return mainGrid;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error building form {formId}");
            throw;
        }
    }

    private View BuildField(FormField field)
    {
        var container = new VerticalStackLayout { Spacing = 5 };

        // Label
        if (!string.IsNullOrEmpty(field.Label))
        {
            var label = new Label
            {
                Text = field.Label + (field.Required ? " *" : ""),
                FontSize = 12,
                FontAttributes = FontAttributes.Bold
            };
            container.Add(label);
        }

        // Input control
        View inputControl = field.Type switch
        {
            "text" => BuildTextField(field),
            "email" => BuildEmailField(field),
            "password" => BuildPasswordField(field),
            "dropdown" => BuildDropdownField(field),
            "autocomplete" => BuildAutocompleteField(field),
            "date" => BuildDateField(field),
            "checkbox" => BuildCheckboxField(field),
            "textarea" => BuildTextAreaField(field),
            "user_picker" => BuildUserPickerField(field),
            _ => throw new NotSupportedException($"Field type {field.Type} not supported")
        };

        container.Add(inputControl);

        // Help text
        if (!string.IsNullOrEmpty(field.HelpText))
        {
            var helpLabel = new Label
            {
                Text = field.HelpText,
                FontSize = 11,
                TextColor = "#999"
            };
            container.Add(helpLabel);
        }

        // Error label (initially hidden)
        var errorLabel = new Label
            {
            FontSize = 11,
            TextColor = Color.FromArgb("#FF6B6B"),
            IsVisible = false,
            Margin = new Thickness(0, 5, 0, 0)
        };
        container.Add(errorLabel);

        // Store error label reference on input
        inputControl.ClassId = field.Id; // For reference
        (inputControl as BindableObject)?.SetValue(
            ErrorLabelProperty,
            errorLabel
        );

        return container;
    }

    private View BuildTextField(FormField field)
    {
        return new Entry
        {
            Placeholder = field.Placeholder,
            ClassId = field.Id,
            Keyboard = Keyboard.Default
        };
    }

    private View BuildDropdownField(FormField field)
    {
        var picker = new Picker
        {
            ClassId = field.Id,
            Title = field.Placeholder ?? "Select..."
        };

        // Load data from Firestore if data source is set
        if (field.DataSource != null)
        {
            _ = LoadPickerDataAsync(picker, field.DataSource);
        }

        return picker;
    }

    private View BuildUserPickerField(FormField field)
    {
        return new SearchBar
        {
            ClassId = field.Id,
            Placeholder = "Search users..."
        };
    }

    private async Task LoadPickerDataAsync(Picker picker, DataSource dataSource)
    {
        try
        {
            var items = await _firestore.GetCollectionAsync<dynamic>(
                dataSource.Collection,
                null // Add filters as needed
            );

            foreach (var item in items)
            {
                var displayValue = item.GetType()
                    .GetProperty(dataSource.DisplayField)?
                    .GetValue(item)?
                    .ToString() ?? "";

                picker.Items.Add(displayValue);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error loading picker data: {dataSource.Collection}");
        }
    }

    // Additional field builders...
    private View BuildEmailField(FormField field) => new Entry
    {
        Placeholder = field.Placeholder,
        ClassId = field.Id,
        Keyboard = Keyboard.Email
    };

    private View BuildPasswordField(FormField field) => new Entry
    {
        Placeholder = field.Placeholder,
        ClassId = field.Id,
        IsPassword = true
    };

    private View BuildDateField(FormField field) => new DatePicker
    {
        ClassId = field.Id
    };

    private View BuildCheckboxField(FormField field) => new CheckBox
    {
        Color = Color.FromArgb("#216485")
    };

    private View BuildTextAreaField(FormField field) => new Editor
    {
        Placeholder = field.Placeholder,
        ClassId = field.Id,
        HeightRequest = 120
    };

    private View BuildAutocompleteField(FormField field) => new SearchBar
    {
        ClassId = field.Id,
        Placeholder = field.Placeholder
    };
}
```

---

## 8. ORGANIZATION HIERARCHY DEEP DIVE

### 8.1 Hierarchical Data Structure

```csharp
// WallD.Core/Models/Entities/OrganizationNode.cs

public class OrganizationNode : IEntity
{
    public string Id { get; set; }
    public string Name { get; set; }
    public string Description { get; set; }
    public string Type { get; set; } // region, department, team, division
    public string Code { get; set; }
    
    // Hierarchy
    public string ParentId { get; set; }
    public List<string> ChildrenIds { get; set; } = new();
    public int HierarchyLevel { get; set; }
    
    // Metadata
    public string ManagerUserId { get; set; }
    public string ManagerDesignation { get; set; }
    public List<string> MemberUserIds { get; set; } = new();
    
    // Status
    public bool Active { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    // Calculated Properties
    public bool IsRoot => ParentId == null;
    public bool IsLeaf => ChildrenIds.Count == 0;
}

// WallD.Application/Services/OrganizationHierarchyService.cs

public interface IOrganizationHierarchyService
{
    Task<OrganizationNode> GetRootAsync();
    Task<List<OrganizationNode>> GetChildrenAsync(string parentId);
    Task<List<OrganizationNode>> GetAncestorsAsync(string nodeId);
    Task<List<OrganizationNode>> GetSubtreeAsync(string nodeId);
    Task<OrganizationNode> GetParentAsync(string nodeId);
    Task<List<User>> GetMembersAsync(string nodeId, bool includeChildren = false);
    Task<List<User>> GetTeamByManagerAsync(string managerUserId);
}

public class OrganizationHierarchyService : IOrganizationHierarchyService
{
    private readonly IOrganizationRepository _orgRepository;
    private readonly IUserRepository _userRepository;
    private readonly ILogger<OrganizationHierarchyService> _logger;

    public async Task<OrganizationNode> GetRootAsync()
    {
        // Root node has no parent
        var allNodes = await _orgRepository.GetAllAsync();
        return allNodes.FirstOrDefault(n => n.IsRoot);
    }

    public async Task<List<OrganizationNode>> GetChildrenAsync(string parentId)
    {
        var parent = await _orgRepository.GetAsync(parentId);
        if (parent == null)
            return new();

        var children = new List<OrganizationNode>();
        foreach (var childId in parent.ChildrenIds)
        {
            var child = await _orgRepository.GetAsync(childId);
            if (child != null)
                children.Add(child);
        }

        return children;
    }

    public async Task<List<OrganizationNode>> GetAncestorsAsync(string nodeId)
    {
        var ancestors = new List<OrganizationNode>();
        var current = await _orgRepository.GetAsync(nodeId);

        while (current != null && !current.IsRoot)
        {
            var parent = await GetParentAsync(current.Id);
            if (parent == null)
                break;

            ancestors.Add(parent);
            current = parent;
        }

        ancestors.Reverse(); // Root first
        return ancestors;
    }

    public async Task<List<OrganizationNode>> GetSubtreeAsync(string nodeId)
    {
        var subtree = new List<OrganizationNode>();
        var node = await _orgRepository.GetAsync(nodeId);

        if (node == null)
            return subtree;

        subtree.Add(node);

        // BFS traversal
        var queue = new Queue<string>(node.ChildrenIds);
        while (queue.Count > 0)
        {
            var childId = queue.Dequeue();
            var child = await _orgRepository.GetAsync(childId);

            if (child != null)
            {
                subtree.Add(child);
                foreach (var grandchildId in child.ChildrenIds)
                    queue.Enqueue(grandchildId);
            }
        }

        return subtree;
    }

    public async Task<List<User>> GetMembersAsync(string nodeId, bool includeChildren = false)
    {
        var users = new List<User>();

        if (includeChildren)
        {
            // Get all nodes in subtree
            var subtree = await GetSubtreeAsync(nodeId);
            var nodeIds = subtree.Select(n => n.Id).ToList();

            // Get users from all nodes
            foreach (var nId in nodeIds)
            {
                var node = await _orgRepository.GetAsync(nId);
                foreach (var userId in node.MemberUserIds)
                {
                    var user = await _userRepository.GetAsync(userId);
                    if (user != null && !users.Any(u => u.Id == user.Id))
                        users.Add(user);
                }
            }
        }
        else
        {
            // Get users only from this node
            var node = await _orgRepository.GetAsync(nodeId);
            foreach (var userId in node.MemberUserIds)
            {
                var user = await _userRepository.GetAsync(userId);
                if (user != null)
                    users.Add(user);
            }
        }

        return users;
    }

    public async Task<List<User>> GetTeamByManagerAsync(string managerUserId)
    {
        // Find organization node managed by this user
        var allNodes = await _orgRepository.GetAllAsync();
        var managedNodes = allNodes
            .Where(n => n.ManagerUserId == managerUserId)
            .ToList();

        var teamMembers = new List<User>();

        foreach (var node in managedNodes)
        {
            var members = await GetMembersAsync(node.Id, includeChildren: true);
            foreach (var member in members)
            {
                if (!teamMembers.Any(u => u.Id == member.Id))
                    teamMembers.Add(member);
            }
        }

        return teamMembers;
    }
}
```

---

## 9. AUTHENTICATION & SECURITY IMPLEMENTATION

### 9.1 Secure Password Handling

```csharp
// WallD.Core/Services/PasswordHashingService.cs

public interface IPasswordHashingService
{
    string HashPassword(string password);
    bool VerifyPassword(string password, string hash);
}

public class PasswordHashingService : IPasswordHashingService
{
    // Using bcrypt for password hashing
    public string HashPassword(string password)
    {
        if (string.IsNullOrWhiteSpace(password))
            throw new ArgumentException("Password cannot be empty");

        // bcrypt automatically generates salt and includes it in hash
        return BCrypt.Net.BCrypt.HashPassword(password, workFactor: 12);
    }

    public bool VerifyPassword(string password, string hash)
    {
        if (string.IsNullOrWhiteSpace(password) || string.IsNullOrWhiteSpace(hash))
            return false;

        try
        {
            return BCrypt.Net.BCrypt.Verify(password, hash);
        }
        catch (Exception)
        {
            return false;
        }
    }
}

// WallD.Infrastructure/Services/AuthenticationService.cs

public class AuthenticationService : IAuthenticationService
{
    private readonly FirebaseAuthService _firebaseAuth;
    private readonly IPasswordHashingService _passwordHasher;
    private readonly IUserRepository _userRepository;
    private readonly ILogger<AuthenticationService> _logger;
    private readonly ISecureStorage _secureStorage;

    public async Task<AuthResult> LoginAsync(string email, string password)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
                return new AuthResult { Success = false, Message = "Email and password required" };

            // Check login attempts (rate limiting)
            var user = await _userRepository.GetByEmailAsync(email);
            if (user != null && user.LoginAttempts >= 5)
            {
                var lastFailedLogin = user.LastFailedLogin;
                var timeSinceLastAttempt = DateTime.UtcNow - lastFailedLogin;

                if (timeSinceLastAttempt.TotalMinutes < 15)
                {
                    return new AuthResult
                    {
                        Success = false,
                        Message = $"Too many failed attempts. Try again in {15 - timeSinceLastAttempt.TotalMinutes:F0} minutes"
                    };
                }
            }

            // Firebase authentication
            var firebaseResult = await _firebaseAuth.SignInAsync(email, password);

            if (!firebaseResult.Success)
            {
                // Log failed attempt
                if (user != null)
                {
                    user.LoginAttempts++;
                    user.LastFailedLogin = DateTime.UtcNow;
                    await _userRepository.UpdateAsync(user);
                }

                return new AuthResult { Success = false, Message = "Invalid credentials" };
            }

            // Reset login attempts
            if (user != null)
            {
                user.LoginAttempts = 0;
                user.LastLoginAt = DateTime.UtcNow;
                await _userRepository.UpdateAsync(user);
            }

            // Store token securely
            await _secureStorage.SetAsync("auth_token", firebaseResult.Token);
            await _secureStorage.SetAsync("tenant_id", firebaseResult.TenantId);
            await _secureStorage.SetAsync("user_id", firebaseResult.UserId);

            _logger.LogInformation($"User {email} logged in successfully");

            return new AuthResult
            {
                Success = true,
                Token = firebaseResult.Token,
                TenantId = firebaseResult.TenantId,
                UserId = firebaseResult.UserId,
                User = user
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Login error");
            return new AuthResult { Success = false, Message = "Login failed" };
        }
    }

    public async Task<AuthResult> RegisterAsync(RegisterRequest request)
    {
        try
        {
            // Validation
            if (string.IsNullOrWhiteSpace(request.Email))
                return new AuthResult { Success = false, Message = "Email is required" };

            if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 12)
                return new AuthResult
                {
                    Success = false,
                    Message = "Password must be at least 12 characters"
                };

            if (!IsStrongPassword(request.Password))
                return new AuthResult
                {
                    Success = false,
                    Message = "Password must contain uppercase, lowercase, numbers, and special characters"
                };

            // Check if user exists
            var existingUser = await _userRepository.GetByEmailAsync(request.Email);
            if (existingUser != null)
                return new AuthResult { Success = false, Message = "Email already registered" };

            // Create Firebase user
            var firebaseUser = await _firebaseAuth.CreateUserAsync(
                request.Email,
                request.Password
            );

            if (!firebaseUser.Success)
                return new AuthResult { Success = false, Message = firebaseUser.Message };

            // Create user record
            var newUser = new User
            {
                Id = Guid.NewGuid().ToString(),
                Email = request.Email,
                FullName = request.FullName,
                DesignationId = request.DesignationId,
                OrganizationNodeId = request.OrganizationNodeId,
                Status = "pending_approval", // Requires manager approval
                CreatedAt = DateTime.UtcNow,
                FirebaseUid = firebaseUser.UserId,
                Avatar = $"https://i.pravatar.cc/150?u={request.Email}"
            };

            await _userRepository.CreateAsync(newUser);

            _logger.LogInformation($"User {request.Email} registered (pending approval)");

            return new AuthResult
            {
                Success = true,
                Message = "Registration successful. Awaiting manager approval.",
                User = newUser
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Registration error");
            return new AuthResult { Success = false, Message = "Registration failed" };
        }
    }

    private bool IsStrongPassword(string password)
    {
        return Regex.IsMatch(password, @"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{12,}$");
    }

    public async Task LogoutAsync()
    {
        try
        {
            await _firebaseAuth.SignOutAsync();
            await _secureStorage.RemoveAsync("auth_token");
            await _secureStorage.RemoveAsync("tenant_id");
            await _secureStorage.RemoveAsync("user_id");

            _logger.LogInformation("User logged out");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Logout error");
        }
    }
}
```

---

**[Continuing to next sections in response due to length...]**

This comprehensive implementation guide covers everything from project structure through deep implementation details. Due to character limits, I'll continue with remaining sections...

Would you like me to:

1. **Continue with remaining sections** (sections 10-15)?
2. **Create a separate file** for the rest?
3. **Focus on specific sections** you want to explore further?

The document already covers:
- ✅ Complete project file structure
- ✅ Full Firebase schema with 150+ fields
- ✅ Core implementation strategy with design patterns
- ✅ Phase 1 deep dive with MauiProgram setup
- ✅ 3 real-life problems with production solutions
- ✅ Login screen prototype with complete XAML
- ✅ Manager screen layout
- ✅ Dynamic form system implementation
- ✅ Organization hierarchy service
- ✅ Authentication & security (password hashing, rate limiting)

**What would you like me to add or expand?**
