# Wall-D: Unified Extreme Workflow Design
## .NET MAUI + Firebase Complete System Plan

**Version:** 1.0 - Master Unified Plan  
**Target Stack:** .NET MAUI (WinUI3), Firebase Firestore & Realtime Database  
**Architecture:** Metadata-Driven, Multi-Tenant, Desktop-Native  
**Scope:** Complete Enterprise Workflow Management Platform  
**Timeline:** 18-24 Months to Production  

---

## TABLE OF CONTENTS

1. [System Overview & Vision](#1-system-overview--vision)
2. [Core Architecture Philosophy](#2-core-architecture-philosophy)
3. [Desktop Integration Strategy](#3-desktop-integration-strategy)
4. [Authentication & Authorization Flow](#4-authentication--authorization-flow)
5. [Metadata-Driven Architecture](#5-metadata-driven-architecture)
6. [Organization Hierarchy System](#6-organization-hierarchy-system)
7. [Dynamic Forms Engine](#7-dynamic-forms-engine)
8. [Task Management Workflow](#8-task-management-workflow)
9. [Multi-Screen Architecture](#9-multi-screen-architecture)
10. [Real-Time Synchronization](#10-real-time-synchronization)
11. [Approval & Escalation Engine](#11-approval--escalation-engine)
12. [Notification System](#12-notification-system)
13. [Database Schema Strategy](#13-database-schema-strategy)
14. [Security & Compliance](#14-security--compliance)
15. [Implementation Phases](#15-implementation-phases)

---

## 1. SYSTEM OVERVIEW & VISION

### 1.1 Core Concept

Wall-D is an **enterprise-grade desktop command center** that replaces the wallpaper with an intelligent, interactive workspace. The system:

- **Covers the entire screen** above the wallpaper, leaving taskbar untouched
- **Cannot be moved or minimized** (always-visible accountability design)
- **Starts automatically** on user login (daemon/background service)
- **Connects to Firebase** for real-time data synchronization
- **Organizes users by SCREENS, not user types** (Developer Screen, Admin Screen, Manager Screen, Employee Screen)
- **Drives approval workflows** through dynamic hierarchy and role-based access

### 1.2 Strategic Differentiators

| Feature | Impact | Competitive Advantage |
|---------|--------|----------------------|
| **Desktop-native** | Tasks impossible to ignore | Competitors are web-based tabs |
| **Always visible** | Accountability enforced | Can't close/minimize |
| **Multi-tenant** | Scales to any company | Support diverse org structures |
| **Metadata-driven** | Zero code changes for customization | Configuration-only deployment |
| **Offline-first** | Works without internet | Syncs when online |
| **Cross-platform** | Windows + Web + Future mobile | MAUI enables easy expansion |
| **Dynamic hierarchy** | Adapts to org changes | No re-deployment needed |

### 1.3 System Layers

```
┌─────────────────────────────────────────────────────────┐
│         WALL-D DESKTOP SHELL (MAUI WinUI3)              │
│  - Replaces system wallpaper                            │
│  - Covers entire screen (task bar below)                │
│  - Non-movable, always-visible panels                   │
│  - Real-time WebSocket connection                       │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ↓ HTTPS + WebSocket
┌──────────────────────────────────────────────────────────┐
│      FIREBASE BACKEND (Firestore + Realtime DB)         │
│  - Real-time data synchronization                       │
│  - Multi-tenant isolation (document structure)          │
│  - Cloud Functions for workflows                        │
│  - Storage for attachments                              │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────────────────────────────────────────┐
│    METADATA CONFIGURATION ENGINE                         │
│  - Org hierarchy definitions (JSON)                      │
│  - Form schemas (JSON)                                  │
│  - Workflow definitions (JSON)                          │
│  - Role/permission mappings                             │
└──────────────────────────────────────────────────────────┘
```

---

## 2. CORE ARCHITECTURE PHILOSOPHY

### 2.1 Metadata-Driven Design

Every element of the system is **defined, not coded**:

```
❌ BEFORE: Hardcoded designation list in application
   → Adding new designation = code change + redeployment

✅ AFTER: Designation list in Firestore document
   → Adding new designation = admin config update + instant effect
```

### 2.2 Multi-Tenant Isolation

**Document-level tenancy** in Firebase:

```
firestore/
├── tenants/{tenantId}/
│   ├── organizations/
│   │   ├── hierarchy/
│   │   ├── designations/
│   │   └── departments/
│   ├── users/
│   ├── forms/
│   ├── workflows/
│   ├── tasks/
│   ├── approvals/
│   └── metadata/
```

**Every query includes `tenantId` filter** → Zero data leakage

### 2.3 Role-Based Access Control (RBAC)

**Roles define capabilities, not screens**:

```
DEVELOPER ROLE:
  - Can create/edit organizations
  - Can manage all metadata
  - Can override workflows
  - Can access admin dashboard
  - Root access

ADMIN ROLE:
  - Can manage users in org
  - Can configure forms/workflows
  - Can manage approvals
  - Limited to assigned organization

MANAGER ROLE:
  - Can create/assign tasks
  - Can approve tasks (within hierarchy)
  - Can view team performance
  - Can export reports

EMPLOYEE ROLE:
  - Can view assigned tasks
  - Can complete tasks
  - Can request approval
  - Can comment/collaborate
```

### 2.4 Separation of Concerns

**Four independent modules:**

1. **Authentication Module** → Identity, login, session
2. **Organization Module** → Hierarchy, designations, departments
3. **Form Module** → Dynamic form schemas, validation rules
4. **Task Module** → Workflow, approvals, execution

---

## 3. DESKTOP INTEGRATION STRATEGY

### 3.1 Application Lifecycle

```
USER TURNS ON COMPUTER
    ↓
Windows login screen appears
    ↓
User enters Windows credentials
    ↓
Wall-D service starts (background)
    ↓
Wall-D splash screen shows
    ↓
Connects to Firebase
    ↓
Wall-D login screen appears
    ↓
User enters Wall-D credentials (or SSO)
    ↓
Firebase authentication validates
    ↓
Loads user's tenant, roles, permissions
    ↓
Main Wall-D desktop loads
    ↓
SCREEN COVERED (wallpaper hidden)
    ↓
Real-time data stream opens
    ↓
Tasks/notifications flow in live
```

### 3.2 Screen Coverage Implementation

**WinUI3 XAML considerations:**

```xml
<!-- Main application window -->
<Window
    x:Class="WallD.MainWindow"
    ExtendsContentIntoTitleBar="True"
    SystemBackdropFallback="Acrylic">

    <!-- Core properties -->
    <!-- - WindowState = Maximized (always) -->
    <!-- - IsResizable = False -->
    <!-- - CanMinimize = False -->
    <!-- - CanClose = False (unless logout) -->
    <!-- - TopMost = False (allow notifications above) -->
    <!-- - WindowStyle = None (no frame) -->

    <!-- Layout structure -->
    <Grid Background="{ThemeResource ApplicationPageBackgroundThemeBrush}">
        
        <!-- HEADER: Branding + User Info -->
        <StackPanel Grid.Row="0" Orientation="Horizontal">
            <TextBlock Text="Wall-D" FontSize="24" FontWeight="Bold" />
            <Spacer HorizontalAlignment="Stretch" />
            <UserProfileControl User="{x:Bind CurrentUser, Mode=OneWay}" />
            <LogoutButton Command="{x:Bind LogoutCommand}" />
        </StackPanel>

        <!-- MAIN CONTENT: Dynamic based on screen type -->
        <ContentControl Grid.Row="1" Content="{x:Bind CurrentScreen, Mode=OneWay}" />

        <!-- FOOTER: Status bar, sync indicator -->
        <Grid Grid.Row="2" Height="50">
            <TextBlock Text="{x:Bind SyncStatus, Mode=OneWay}" />
            <ProgressRing IsActive="{x:Bind IsSyncing, Mode=OneWay}" />
        </Grid>

    </Grid>

</Window>
```

### 3.3 Taskbar Positioning

**System integration points:**

- Wall-D window = **Top: 0, Left: 0, Right: Width, Bottom: Height - TaskbarHeight**
- Does NOT hide taskbar
- Taskbar remains fully functional
- User can switch to other apps (Wall-D visible when switched back)
- Can use Alt+Tab or taskbar to switch contexts

### 3.4 Overlay vs Shell Replacement

**Phase 1 (MVP): Overlay Mode**
- Wall-D window on top of Explorer
- Everything else works normally
- Easy to develop, safe for users
- Users can minimize Wall-D (but it auto-restores)

**Phase 2 (Enterprise): Shell Replacement**
- Replace Windows Explorer as shell
- Only admin-approved apps available
- Locked-down environment
- Requires admin privileges

---

## 4. AUTHENTICATION & AUTHORIZATION FLOW

### 4.1 Authentication Sequence

```
┌─────────────────────────────────────────────────┐
│ STEP 1: Registration                            │
├─────────────────────────────────────────────────┤

User enters form:
├─ Full Name (text)
├─ Email (email)
├─ Password (password)
├─ Designation (dropdown - calls Firebase)
└─ Company/Organization (text/dropdown)

Firebase receives request:
├─ Validates credentials
├─ Calls Cloud Function: ValidateDesignation
├─ Cloud Function checks if designation exists
├─ Returns: approval_required = true
├─ Creates User document with status = "pending_approval"
└─ Sends notification to parent designation

RESULT: Registration pending manager approval
```

### 4.2 Approval Workflow

```
┌─────────────────────────────────────────────────┐
│ STEP 2: Manager Approves Registration           │
├─────────────────────────────────────────────────┤

MANAGER'S VIEW (Manager Screen):
├─ Sees "Pending Approvals" widget
├─ Shows new registrants + their proposed designation
├─ Can click "Approve" or "Reject"

On APPROVE:
├─ Updates User.status = "active"
├─ Sets User.approved_at = now
├─ Sets User.approved_by = managerId
├─ Triggers Cloud Function: OnUserApproved
├─ Cloud Function:
│  ├─ Creates initial role assignments
│  ├─ Sends email: "Your registration approved!"
│  ├─ Triggers notification: "You can now login"
└─ Returns success

On REJECT:
├─ Updates User.status = "rejected"
├─ Sets rejection reason
├─ Sends email: "Your registration was rejected"
└─ Allows user to re-register after 24 hours

RESULT: New user now has active account + assigned roles
```

### 4.3 Session Management

```
Firebase Authentication:
├─ User authenticates with email/password
├─ Firebase returns JWT token (1 hour expiry)
├─ Token stored in secure storage (MAUI SecureStorage)
├─ Auto-refresh 5 minutes before expiry
├─ On logout: token revoked, local cache cleared
└─ On token expiry: automatic re-authentication (silent)

MAUI Application:
├─ Stores token in platform-specific secure storage
│  ├─ Windows: DPAPI-encrypted local file
│  ├─ Web: Secure cookie (HttpOnly flag)
├─ Refreshes token automatically
├─ Validates token signature on each request
└─ Redirects to login if token invalid
```

---

## 5. METADATA-DRIVEN ARCHITECTURE

### 5.1 Configuration Hierarchy

```
Firestore Structure:

tenants/{tenantId}/
├── metadata/
│   ├── designations.json
│   ├── formSchemas.json
│   ├── workflowDefinitions.json
│   ├── rolePermissions.json
│   └── organizationStructure.json
├── organizations/
│   ├── {orgNodeId}/
│   │   ├── name
│   │   ├── type (plant, warehouse, office, etc.)
│   │   ├── parent_id
│   │   ├── manager_id
│   │   └── metadata{}
├── designations/
│   ├── {designationId}/
│   │   ├── name (CEO, Manager, Developer, etc.)
│   │   ├── hierarchy_level
│   │   ├── reports_to (parent designation)
│   │   ├── permissions[]
│   │   ├── default_forms[]
│   │   ├── requires_approval (boolean)
│   │   └── approval_by (parent designation or role)
└── ...
```

### 5.2 Dynamic Designation System

**Instead of hardcoded roles**, use **configurable designations**:

```json
{
  "designations": {
    "ceo": {
      "name": "Chief Executive Officer",
      "hierarchy_level": 1,
      "reports_to": null,
      "permissions": ["all"],
      "default_roles": ["admin", "manager", "developer"],
      "screen_access": ["developer", "admin", "manager"],
      "requires_approval": false
    },
    "manager": {
      "name": "Department Manager",
      "hierarchy_level": 3,
      "reports_to": ["ceo", "vp"],
      "permissions": ["create_task", "assign_task", "approve_task", "view_analytics"],
      "default_roles": ["manager"],
      "screen_access": ["manager"],
      "requires_approval": true,
      "approval_by": "parent_designation"
    },
    "employee": {
      "name": "Software Developer",
      "hierarchy_level": 5,
      "reports_to": ["manager", "tech_lead"],
      "permissions": ["view_task", "update_task", "complete_task"],
      "default_roles": ["employee"],
      "screen_access": ["employee"],
      "requires_approval": true,
      "approval_by": "manager"
    }
  }
}
```

**Impact:**
- Company can add **custom designations** without code changes
- Each designation has **custom permissions**
- Hierarchical approval flows through **designation chain**
- Screens shown based on **designation access list**

### 5.3 Form Schema System

**Every input form is a JSON document**:

```json
{
  "formId": "user_registration",
  "name": "User Registration Form",
  "description": "Form for new user registration",
  "version": 1,
  "fields": [
    {
      "id": "fullName",
      "type": "text",
      "label": "Full Name",
      "required": true,
      "validation": "^[a-zA-Z\\s]{3,50}$",
      "placeholder": "John Doe"
    },
    {
      "id": "email",
      "type": "email",
      "label": "Email Address",
      "required": true,
      "validation": "^[^@]+@[^@]+\\.[^@]+$"
    },
    {
      "id": "designation",
      "type": "dropdown",
      "label": "Your Designation",
      "required": true,
      "dataSource": "firestore",
      "collection": "designations",
      "displayField": "name",
      "valueField": "id",
      "filter": { "status": "active" }
    },
    {
      "id": "department",
      "type": "autocomplete",
      "label": "Department",
      "required": true,
      "dataSource": "firestore",
      "collection": "organizations",
      "displayField": "name",
      "filter": { "type": "department" }
    },
    {
      "id": "manager",
      "type": "userPicker",
      "label": "Your Manager",
      "required": false,
      "dataSource": "firestore",
      "collection": "users",
      "filter": { "roles": ["manager"] }
    }
  ],
  "workflow": {
    "onSubmit": "validateAndSubmit",
    "onValidate": "checkEmailUnique",
    "nextStep": "requestApproval"
  }
}
```

**Runtime behavior:**
- MAUI reads this JSON
- **Dynamically generates form UI** (TextBox, Combobox, etc.)
- **Fetches dropdown data** from Firestore
- **Applies client-side validation**
- **Sends to backend with validation**
- **Can change form WITHOUT app update**

---

## 6. ORGANIZATION HIERARCHY SYSTEM

### 6.1 Dynamic Hierarchy Builder

**Hierarchical org structure, not flat**:

```
Firestore Document:

{
  tenantId: "acme_corp",
  organizationId: "org_2024_001",
  
  tree: {
    "ceo_node": {
      id: "ceo_node",
      name: "CEO",
      type: "organization_node",
      designation: "ceo",
      manager_id: "user_1",
      parent_id: null,
      level: 0,
      children: ["vp_sales_node", "vp_ops_node", "cfo_node"]
    },
    
    "vp_sales_node": {
      id: "vp_sales_node",
      name: "VP Sales",
      type: "organization_node",
      designation: "vp",
      manager_id: "user_2",
      parent_id: "ceo_node",
      level: 1,
      children: ["sales_mgr_north", "sales_mgr_south"]
    },
    
    "sales_mgr_north": {
      id: "sales_mgr_north",
      name: "Sales Manager - North Region",
      type: "organization_node",
      designation: "manager",
      manager_id: "user_3",
      parent_id: "vp_sales_node",
      level: 2,
      children: ["sales_rep_node_1", "sales_rep_node_2"]
    },
    
    "sales_rep_node_1": {
      id: "sales_rep_node_1",
      name: "Sales Rep - Bangalore",
      type: "organization_node",
      designation: "employee",
      manager_id: "user_4",
      parent_id: "sales_mgr_north",
      level: 3,
      children: []
    }
  }
}
```

### 6.2 Hierarchy Features

**DEVELOPER SCREEN allows:**
- Create/edit nodes
- Change parent relationships
- Bulk import from CSV
- Assign managers to nodes
- Define inheritance rules
- Set delegation policies

**AUTOMATIC PROPAGATION:**
- Permissions flow down tree
- Approvals escalate up tree
- Reports aggregate down tree
- Tasks inherit context from parent

### 6.3 Dynamic Queries Based on Hierarchy

```
When Manager requests "My Team's Tasks":
├─ Query finds this manager's node in tree
├─ Gets all child nodes
├─ Gets all users assigned to those nodes
├─ Gets all tasks assigned to those users
├─ Returns aggregated list with hierarchy context
└─ UI shows tasks organized by team/department
```

---

## 7. DYNAMIC FORMS ENGINE

### 7.1 Form Types

```
SYSTEM FORMS (pre-defined):
├─ Login Form
├─ Registration Form
├─ Profile Setup Form
└─ Password Recovery Form

CUSTOM FORMS (configurable):
├─ Task Creation Form (different fields per project)
├─ Approval Request Form (varies by process)
├─ Employee Onboarding Form (company-specific fields)
├─ Customer Intake Form (industry-specific)
└─ Expense Submission Form (company policies)

DYNAMIC FIELDS (metadata-driven):
├─ Text input
├─ Email input
├─ Phone number (with country code)
├─ Date picker
├─ Time picker
├─ Date+Time picker
├─ Dropdown (static list)
├─ Dropdown (dynamic from Firestore)
├─ Autocomplete (searchable)
├─ User picker
├─ Organization picker
├─ File upload
├─ Checkbox
├─ Radio buttons
├─ Text area (multi-line)
├─ Rich text editor
├─ Signature pad
└─ Currency field (with formatting)
```

### 7.2 Form Rendering Engine

```
MAUI Process:

1. Download form schema from Firestore
   └─ Form ID references specific form

2. Parse JSON schema
   └─ Iterate through fields array

3. For each field:
   ├─ Create appropriate XAML control
   ├─ If dataSource = "firestore":
   │  ├─ Query Firestore collection
   │  ├─ Apply filters
   │  └─ Populate dropdown/picker
   ├─ If validation rules exist:
   │  └─ Set up client-side validation
   └─ Bind to view model

4. Render complete form
   └─ Auto-layout based on field types

5. User submits
   ├─ Validate all fields
   ├─ Show validation errors if any
   ├─ Send to backend if valid
   └─ Handle response
```

### 7.3 Form Customization Example

**Before (hardcoded):**
```csharp
// Code change required every time
public class UserRegistrationForm
{
    public string FullName { get; set; }
    public string Email { get; set; }
    public string Designation { get; set; }
    public string Department { get; set; }
    // Add new field = code change
}
```

**After (metadata-driven):**
```
// No code change
{
  "formId": "user_registration",
  "fields": [
    { "id": "fullName", "type": "text", "label": "Full Name" },
    { "id": "email", "type": "email", "label": "Email" },
    { "id": "designation", "type": "dropdown", ... },
    { "id": "department", "type": "dropdown", ... },
    // Add new field here, instantly available in app
    { "id": "officeLocation", "type": "dropdown", ... }
  ]
}
```

---

## 8. TASK MANAGEMENT WORKFLOW

### 8.1 Task Lifecycle

```
┌──────────────────────┐
│ TASK CREATED         │  Manager creates task
├──────────────────────┤
│ Status: PENDING      │
│ Assignee: unset      │
└─────────────┬────────┘
              │
              ↓
┌──────────────────────┐
│ TASK ASSIGNED        │  Task assigned to employee
├──────────────────────┤
│ Status: ASSIGNED     │
│ Assignee: employee   │
│ Due Date: set        │
└─────────────┬────────┘
              │
              ↓
┌──────────────────────┐
│ TASK IN_PROGRESS     │  Employee starts work
├──────────────────────┤
│ Status: IN_PROGRESS  │
│ Started At: now      │
│ Progress: 0%         │
└─────────────┬────────┘
              │
              ↓
┌──────────────────────┐
│ TASK REQUIRES_INFO   │  Employee needs clarification (optional)
├──────────────────────┤
│ Status: BLOCKED      │
│ Reason: clarification│
│ Assigned to: manager │
└─────────────┬────────┘
              │
              ↓
┌──────────────────────┐
│ TASK COMPLETED       │  Employee marks done
├──────────────────────┤
│ Status: AWAITING_    │
│         REVIEW       │
│ Completed At: now    │
│ Requires Approval: Y │
└─────────────┬────────┘
              │
              ↓
┌──────────────────────┐
│ APPROVAL PENDING     │  Manager reviews
├──────────────────────┤
│ Status: PENDING_     │
│         APPROVAL     │
│ Reviewer: manager    │
└─────────────┬────────┘
        ┌─────┴─────┐
        ↓           ↓
    APPROVED    REJECTED
        │           │
        ↓           ↓
┌──────────────────────┐
│ TASK CLOSED          │
├──────────────────────┤
│ Status: COMPLETED    │
│ Approved By: manager │
│ Closed At: now       │
└──────────────────────┘
```

### 8.2 Task Fields (Dynamic)

```
CORE FIELDS (fixed):
├─ Task ID
├─ Title
├─ Description
├─ Created By
├─ Created At
├─ Due Date
├─ Status
├─ Priority
├─ Assignee
├─ Approver
└─ Updated At

CUSTOM FIELDS (form-dependent):
├─ Project ID
├─ Cost Center
├─ Customer ID
├─ Machine ID
├─ Quality Score
├─ Estimated Hours
├─ Actual Hours
├─ Resources Required
└─ [Company-specific fields]
```

### 8.3 Task Approval Logic

```
When task marked COMPLETED:
├─ Check if task requires approval
├─ Query task approval chain from metadata
├─ Find manager/approver in hierarchy
├─ Create Approval record:
│  ├─ Task ID
│  ├─ Approver ID
│  ├─ Status: PENDING
│  ├─ Created At: now
│  └─ Expires At: now + 48 hours
├─ Send notification to approver
├─ Trigger Cloud Function: OnApprovalRequired
└─ Set task.status = PENDING_APPROVAL

Approver receives notification:
├─ Clicks "Review Task"
├─ Sees task details + custom fields
├─ Can ask clarifying questions (comments)
├─ Can request changes:
│  ├─ Sets status back to IN_PROGRESS
│  ├─ Adds note explaining changes needed
│  └─ Task reassigned to employee
└─ Or approves:
   ├─ Sets Approval.status = APPROVED
   ├─ Sets task.status = COMPLETED
   ├─ Sends completion notification
   └─ Task removed from active list
```

---

## 9. MULTI-SCREEN ARCHITECTURE

### 9.1 Screen Access Control

```
DEVELOPER SCREEN:
├─ Access: Only "Developer" role
├─ Sections:
│  ├─ Tenant Management
│  ├─ Database Manager
│  │  ├─ Organization Hierarchy Builder
│  │  ├─ Designation Management
│  │  ├─ Form Schema Editor
│  │  ├─ Workflow Designer
│  │  └─ Raw Firestore Explorer (debug)
│  ├─ User Management
│  ├─ System Logs
│  ├─ Performance Metrics
│  └─ Backup/Restore Tools
└─ Features: Full system control, no restrictions

ADMIN SCREEN:
├─ Access: "Admin" role
├─ Sections:
│  ├─ Tenant Administration
│  ├─ Organization Structure
│  ├─ User Management
│  ├─ Form Configuration (create/edit forms)
│  ├─ Workflow Configuration
│  ├─ Role & Permission Management
│  ├─ Approval Queue
│  └─ Audit Logs
└─ Features: Org-level configuration, limited to assigned org

MANAGER SCREEN:
├─ Access: "Manager" role
├─ Sections:
│  ├─ My Team Dashboard
│  ├─ Task Management
│  │  ├─ Create/Assign Tasks
│  │  ├─ View Team Tasks
│  │  ├─ Approve Completed Tasks
│  │  └─ Escalate Overdue Tasks
│  ├─ Team Analytics
│  ├─ Performance Reports
│  ├─ Approvals Queue
│  └─ Team Members
└─ Features: Manage team, approve work, view performance

EMPLOYEE SCREEN:
├─ Access: "Employee" role (default)
├─ Sections:
│  ├─ My Tasks
│  │  ├─ Assigned to Me
│  │  ├─ In Progress
│  │  ├─ Awaiting Approval
│  │  └─ Completed
│  ├─ My Profile
│  ├─ Submit New Requests
│  ├─ View My Performance
│  └─ Help & Support
└─ Features: Complete tasks, view status, request clarification
```

### 9.2 Screen Display Logic

```
On login, system determines user's screen:

1. Get user record from Firestore
   └─ Get user.designation_id

2. Look up designation in metadata
   └─ Get designation.screen_access = ["manager", "employee"]

3. Check if multiple screens accessible
   ├─ If 1 screen → automatically show that screen
   └─ If multiple screens → show screen selector

4. If screen selector shown:
   ├─ User chooses screen from list
   ├─ System loads that screen's UI
   ├─ Stores selection in preferences
   └─ Next login remembers selection

5. Load screen data from Firestore
   ├─ Query: tenants/{tenantId}/[screen-specific-collections]
   ├─ Apply filters based on user's organization/hierarchy
   ├─ Display dashboard/widgets
   └─ Set up real-time listeners for updates
```

### 9.3 Example: Manager Screen Layout

```
┌─────────────────────────────────────────────────────────┐
│ HEADER: Wall-D | Manager: John Smith | Logout          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────┐  ┌──────────────────────────────┐ │
│  │ NAVIGATION       │  │ MAIN CONTENT AREA            │ │
│  ├──────────────────┤  ├──────────────────────────────┤ │
│  │ ◆ Dashboard      │  │ MY TEAM DASHBOARD            │ │
│  │ ◆ My Tasks       │  │                              │ │
│  │ ◆ Team Tasks     │  │ ┌────────┐  ┌────────┐      │ │
│  │ ◆ Approvals (3)  │  │ │Tasks   │  │Pending │      │ │
│  │ ◆ Analytics      │  │ │Due     │  │Apps.   │      │ │
│  │ ◆ Reports        │  │ │Today   │  │ 3      │      │ │
│  │ ◆ Team Members   │  │ │ 5      │  └────────┘      │ │
│  │ ◆ Settings       │  │ └────────┘                   │ │
│  │                  │  │                              │ │
│  └──────────────────┘  │ ┌──────────────────────────┐ │ │
│                        │ │ RECENT TASKS             │ │ │
│                        │ ├──────────────────────────┤ │ │
│                        │ │ [+] Create New Task      │ │ │
│                        │ │                          │ │ │
│                        │ │ 1. Setup Database        │ │ │
│                        │ │    Assigned: Ram         │ │ │
│                        │ │    Status: IN_PROGRESS   │ │ │
│                        │ │    Due: Tomorrow         │ │ │
│                        │ │                          │ │ │
│                        │ │ 2. Security Audit        │ │ │
│                        │ │    Assigned: Priya       │ │ │
│                        │ │    Status: PENDING_APP   │ │ │
│                        │ │    [APPROVE] [REJECT]    │ │ │
│                        │ │                          │ │ │
│                        │ └──────────────────────────┘ │ │
│                        │                              │ │
└────────────────────────┴──────────────────────────────┘ │
│ Status: ✓ Synced | Last sync: 2 mins ago               │
└─────────────────────────────────────────────────────────┘
```

---

## 10. REAL-TIME SYNCHRONIZATION

### 10.1 WebSocket Architecture

```
MAUI Application (Client):
├─ Maintains persistent WebSocket connection to Firebase Realtime DB
├─ Receives JSON messages in real-time
├─ Updates local state
├─ Triggers UI re-renders
└─ Reconnects automatically if connection drops

Firebase:
├─ Cloud Functions listen for Firestore changes
├─ When document updates:
│  ├─ Check affected users/screens
│  ├─ Broadcast update to subscribed clients
│  └─ Message includes: type, document, timestamp
└─ Rate limiting to prevent message storms

Local Cache (SQLite):
├─ Stores recently fetched data
├─ Enables offline viewing
├─ Syncs on reconnection
├─ Auto-purges old records
└─ < 100MB total size limit
```

### 10.2 Sync Scenarios

**Scenario 1: Task Status Update**
```
Manager changes task status on MANAGER SCREEN:
├─ MAUI sends update to Firebase
├─ Firestore updates task document
├─ Cloud Function triggers: OnTaskStatusChanged
├─ Function broadcasts to:
│  ├─ Task assignee (EMPLOYEE SCREEN)
│  ├─ Task creator (MANAGER SCREEN)
│  └─ Approver if applicable
├─ All clients receive notification:
│  ├─ Beep/sound notification
│  ├─ Toast popup: "Task status updated"
│  ├─ Dashboard refreshes live
│  └─ Shows new status instantly

Assignee sees:
├─ Task status changed in real-time
├─ No refresh needed
├─ Notification popup
└─ Next action automatically highlighted
```

**Scenario 2: New Approval Request**
```
Employee marks task COMPLETED:
├─ MAUI sends update
├─ Task status → AWAITING_REVIEW
├─ Cloud Function: OnTaskCompleted
├─ Function identifies approver from hierarchy
├─ Creates Approval record
├─ Sends notification to approver

Manager receives notification:
├─ Sound alert
├─ Toast: "New task awaiting approval"
├─ Approval counter increments (3 → 4)
├─ Dashboard updates live
├─ Manager can click and approve immediately
└─ Employee sees approval status change live
```

### 10.3 Conflict Resolution

**Multiple users editing simultaneously:**
```
Both Manager A and Manager B try to assign same task:

Local: A sends update at T1
Local: B sends update at T2 (simultaneous)

Firebase receives at T1:
├─ Updates task.assignee = A
├─ Sets updated_at = T1
├─ Broadcasts to all clients

B's update arrives at T2:
├─ Firestore sees updated_at mismatch
├─ Applies B's update anyway (last-write-wins)
├─ Broadcasts to all clients
├─ B's version becomes truth

Result:
├─ Task assigned to B's value
├─ A's version overwritten
├─ Both managers see final result
├─ System shows "Task was reassigned by Manager B"
└─ Conflict resolved transparently
```

---

## 11. APPROVAL & ESCALATION ENGINE

### 11.1 Approval Chain Resolution

```
When task marked COMPLETED:

1. Fetch task details from Firestore
   └─ Get task.approval_required = true

2. Look up approval chain:
   ├─ Get task assignee's designation
   ├─ Query metadata for approvers
   ├─ Approval chain: task.designated_approver or hierarchy_based
   └─ Example: Employee → Team Lead → Manager → Director

3. Create Approval records:
   ├─ Approval #1
   │  ├─ Approver: Team Lead (if exists)
   │  ├─ Level: 1
   │  ├─ Status: PENDING
   │  └─ Expires: +48 hours
   ├─ Approval #2
   │  ├─ Approver: Manager
   │  ├─ Level: 2
   │  ├─ Status: PENDING (waits for #1)
   │  └─ Expires: +48 hours (from #1 approval)
   └─ [... more levels if applicable]

4. Notify first approver:
   ├─ Send notification
   ├─ Add to approvals queue
   ├─ Update counter on MANAGER SCREEN
   └─ Set reminder for 24 hours if not approved

5. When first approver approves:
   ├─ Mark Approval #1 → APPROVED
   ├─ Create Approval #2 (next level)
   ├─ Notify next approver
   ├─ Repeat until all approvals done
   └─ Task status → COMPLETED

6. If any approver rejects:
   ├─ Mark Approval → REJECTED
   ├─ Stop approval chain
   ├─ Task status → NEEDS_REVISION
   ├─ Notify assignee with reason
   └─ Allow employee to resubmit
```

### 11.2 Escalation Rules

```
Task escalation defined in metadata:

{
  "escalationRules": {
    "task_id_123": [
      {
        "trigger": "overdue",
        "after_days": 1,
        "escalate_to": "manager",
        "action": "send_email"
      },
      {
        "trigger": "overdue",
        "after_days": 3,
        "escalate_to": "parent_manager",
        "action": ["send_email", "send_sms", "notify_app"]
      },
      {
        "trigger": "pending_approval",
        "after_days": 2,
        "escalate_to": "ceo",
        "action": "send_urgent_notification"
      }
    ]
  }
}
```

**Escalation Engine (Cloud Function):**
```
Runs every 1 hour:
├─ Query all non-completed tasks
├─ For each task:
│  ├─ Calculate days_overdue
│  ├─ Check escalation rules
│  ├─ If rule triggered:
│  │  ├─ Escalate to next level manager
│  │  ├─ Send notifications (email/SMS/app)
│  │  ├─ Create escalation record
│  │  └─ Update task.escalation_level
│  └─ Continue checking next rules
└─ Complete
```

---

## 12. NOTIFICATION SYSTEM

### 12.1 Notification Types

```
SYSTEM NOTIFICATIONS:
├─ Task assigned to me
├─ Task due in 24 hours
├─ Task overdue
├─ New task in my team
├─ Approval request
├─ Approval completed
├─ Escalation alert
├─ System maintenance
└─ Security alert

NOTIFICATION CHANNELS:
├─ In-App (toast, banner, badge)
├─ Email (SMTP via Cloud Function)
├─ SMS (Twilio API)
├─ Desktop notification (Windows)
└─ Push notification (if mobile app)
```

### 12.2 Notification Preferences

```
User can configure:
├─ Which notifications to receive
├─ Which channels for each notification
├─ Do Not Disturb hours (8 PM - 8 AM)
├─ Digest frequency (immediate, daily, weekly)
├─ Notification sounds (on/off per type)
└─ Email preferences (summary, individual, none)

Stored in Firestore:
{
  "userId": "user_123",
  "notificationPreferences": {
    "taskAssigned": {
      "enabled": true,
      "channels": ["inApp", "email"],
      "sound": true
    },
    "taskOverdue": {
      "enabled": true,
      "channels": ["inApp", "sms"],
      "sound": true
    },
    "approvalRequired": {
      "enabled": true,
      "channels": ["inApp", "email", "sms"],
      "sound": true
    },
    "doNotDisturbHours": { "start": "20:00", "end": "08:00" },
    "timezone": "Asia/Kolkata"
  }
}
```

### 12.3 Notification Delivery

```
When notification triggered:

1. Check user preferences
   ├─ Is notification type enabled?
   ├─ Is it within DND hours?
   └─ What channels to use?

2. Prepare notification:
   ├─ Render message
   ├─ Add action links
   ├─ Set priority
   └─ Set expiry

3. Send via selected channels:
   ├─ InApp: Broadcast via WebSocket
   ├─ Email: Queue in Cloud Function
   ├─ SMS: Call Twilio API
   └─ Push: Send to device token

4. Track delivery:
   ├─ Log notification sent
   ├─ Track read/click events
   ├─ Update user's notification history
   └─ Use for analytics
```

---

## 13. DATABASE SCHEMA STRATEGY

### 13.1 Firestore Structure

```
firestore/
├── tenants/
│   └── {tenantId}/
│       ├── metadata/
│       │   ├── designations
│       │   ├── formSchemas
│       │   ├── workflowDefinitions
│       │   ├── rolePermissions
│       │   └── settings
│       ├── users/
│       │   └── {userId}/
│       │       ├── profile_data
│       │       ├── roles
│       │       ├── permissions
│       │       └── settings
│       ├── organizations/
│       │   └── {orgNodeId}/
│       │       ├── name, type, hierarchy_data
│       │       └── manager_id
│       ├── tasks/
│       │   └── {taskId}/
│       │       ├── title, description, status
│       │       ├── assignee_id, created_by
│       │       ├── due_date, priority
│       │       ├── custom_fields{}
│       │       ├── approvals[] (sub-collection)
│       │       └── comments[] (sub-collection)
│       ├── approvals/
│       │   └── {approvalId}/
│       │       ├── task_id, approver_id
│       │       ├── status (PENDING/APPROVED/REJECTED)
│       │       ├── created_at, expires_at
│       │       └── reason/notes
│       ├── forms/
│       │   └── {formId}/
│       │       ├── name, description
│       │       ├── fields[] (JSON)
│       │       ├── version
│       │       └── updated_at
│       ├── workflows/
│       │   └── {workflowId}/
│       │       ├── name, description
│       │       ├── steps[] (JSON)
│       │       ├── triggers
│       │       └── version
│       ├── notifications/
│       │   └── {notificationId}/
│       │       ├── user_id, type
│       │       ├── message, action_link
│       │       ├── read_at
│       │       └── created_at
│       └── auditLogs/
│           └── {logId}/
│               ├── action, actor_id, resource
│               ├── before_state, after_state
│               ├── timestamp
│               └── ip_address

auth/
└── {userId}/ (Firebase Auth)
    ├── email, password_hash
    ├── email_verified
    ├── tenant_id
    └── last_login
```

### 13.2 Data Access Patterns

```
Get user's tasks:
└─ Query: tenants/{tenantId}/tasks 
   └─ Filter: assignee_id == userId
   └─ Order: due_date ASC
   └─ Result: [task1, task2, ...]

Get manager's team:
└─ Query: tenants/{tenantId}/organizations
   └─ Filter: manager_id == userId
   └─ Get: children nodes
   └─ Get: users in those nodes
   └─ Result: [user1, user2, ...]

Get pending approvals:
└─ Query: tenants/{tenantId}/approvals
   └─ Filter: approver_id == userId
   └─ Filter: status == "PENDING"
   └─ Order: created_at DESC
   └─ Result: [approval1, approval2, ...]

Get tasks due today:
└─ Query: tenants/{tenantId}/tasks
   └─ Filter: status != "COMPLETED"
   └─ Filter: due_date <= today
   └─ Filter: assignee_id == userId
   └─ Result: [overdue_task1, overdue_task2, ...]
```

---

## 14. SECURITY & COMPLIANCE

### 14.1 Authentication Security

```
REGISTRATION:
├─ Password: min 12 chars, upper+lower+number+special
├─ Email verification: 24-hour link
├─ Rate limiting: 5 attempts per 15 minutes
├─ Honeypot field: detect bots
└─ CAPTCHA: reCAPTCHA v3

LOGIN:
├─ Firebase Auth handles authentication
├─ JWT token: 1-hour expiry
├─ Refresh token: 30-day expiry
├─ MFA: optional per user
├─ Brute force: 10 failed attempts → 24-hour lockout
├─ Session: device fingerprint verification
└─ Anomalous login: detect unusual location/device

TOKEN SECURITY:
├─ Stored in secure storage (platform-specific)
├─ Never logged or exposed
├─ Transmitted over HTTPS only
├─ Verified on every API call
└─ Revoked on logout
```

### 14.2 Data Security

```
FIRESTORE RULES:
├─ All data requires authentication
├─ Multi-tenancy enforced at document level
├─ Users can only access their tenant's data
├─ Deletion: audit logs mandatory
├─ Encryption: all data encrypted at rest

CLIENT-SIDE ENCRYPTION:
├─ Sensitive fields encrypted before sending
├─ Encryption key: derived from user password
├─ Decryption: only in user's session
└─ No plaintext in transit

SERVER-SIDE ENCRYPTION:
├─ All data encrypted at rest (Firebase)
├─ Encryption keys managed by Google Cloud KMS
├─ Automatic key rotation: quarterly
└─ Backups: encrypted separately
```

### 14.3 Audit & Compliance

```
AUDIT LOGGING:
├─ All data modifications logged
├─ Includes: who, what, when, why
├─ Immutable: cannot be modified/deleted
├─ Retention: 7 years (regulatory requirement)
├─ Searchable: by user, date, resource, action

GDPR COMPLIANCE:
├─ Right to be forgotten: soft delete + permanent delete after review
├─ Data portability: export user data as JSON
├─ Consent management: track user consents
├─ Privacy policy: available in-app
├─ DPA: data processing agreement available

SOC2 COMPLIANCE:
├─ Security: encryption, authentication, RBAC
├─ Availability: 99.9% uptime SLA
├─ Processing Integrity: audit logs
├─ Confidentiality: data isolation
└─ Privacy: GDPR compliance
```

---

## 15. IMPLEMENTATION PHASES

### Phase 1: Foundation (Months 1-3)
**Goal:** Core desktop app + authentication + basic task management

**Deliverables:**
- MAUI WinUI3 shell application
- Firebase authentication (email/password)
- User registration with manager approval
- Basic database structure
- Simple task CRUD
- Real-time sync (WebSocket)
- Metadata framework

### Phase 2: Hierarchy & Forms (Months 4-6)
**Goal:** Organization hierarchy + dynamic forms

**Deliverables:**
- Org hierarchy tree builder (DEVELOPER SCREEN)
- Designation system (configurable)
- Dynamic form engine
- Form schema editor (ADMIN SCREEN)
- Form rendering in MAUI

### Phase 3: Workflows & Approvals (Months 7-9)
**Goal:** Approval workflows + escalation

**Deliverables:**
- Workflow designer (visual)
- Multi-level approval chain
- Escalation engine (Cloud Functions)
- Notification system (in-app + email)
- Audit logging

### Phase 4: Multi-Screen Interfaces (Months 10-12)
**Goal:** Complete DEVELOPER, ADMIN, MANAGER, EMPLOYEE screens

**Deliverables:**
- DEVELOPER SCREEN: Full system control
- ADMIN SCREEN: Organization management
- MANAGER SCREEN: Team task management
- EMPLOYEE SCREEN: Task execution
- Screen selector / role-based access

### Phase 5: Analytics & Reporting (Months 13-15)
**Goal:** Dashboard widgets + reports

**Deliverables:**
- Task completion dashboard
- Team performance analytics
- Approval SLA tracking
- Custom reports
- Export functionality (Excel, PDF)

### Phase 6: Integrations & Polish (Months 16-18)
**Goal:** External integrations + production readiness

**Deliverables:**
- Slack integration
- Email integration
- Calendar sync
- Performance optimization
- Security audit
- Documentation
- Training materials

---

## EXTREME SUMMARY

This unified plan delivers a **complete enterprise platform** that:

✅ Covers entire desktop screen (wallpaper replacement)  
✅ Cannot be closed/minimized (always visible accountability)  
✅ Starts on login (automatic daemon)  
✅ Connects to Firebase (real-time, no infrastructure)  
✅ Uses .NET MAUI WinUI3 (cross-platform capable)  
✅ Supports 4 screens (Developer, Admin, Manager, Employee)  
✅ Metadata-driven (no code changes for customization)  
✅ Dynamic forms (configurable without code)  
✅ Hierarchical org structure (adapts to any company)  
✅ Multi-level approval workflows (automatic escalation)  
✅ Real-time synchronization (all devices live)  
✅ Enterprise security (GDPR, SOC2, audit logs)  
✅ Production-ready (18-24 months development)

**No more scattered tasks. No more forgotten deadlines. No more manual follow-ups. Wall-D makes work impossible to ignore.**
