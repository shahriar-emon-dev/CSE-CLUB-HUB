# CSE Club Hub - Implementation Task Plan

## Source Documents Reviewed

- Emon Hossain-223071044-SRS for CSE CLUB HUB (1).pdf
- Emon Hossain-223071044-CSE CLUB HUB & QUEUELESS(1).pdf

## Key Findings

- The product vision is a centralized mobile app for CSE clubs with role-based access.
- Target roles are three-tier:
  - Super Admin
  - Club Executive
  - Regular Student
- Role governance is strict: executive role assignment is controlled by Super Admin only.
- Core modules required by SRS:
  - Authentication and profile management
  - Club feed and interactions
  - Club management and follow system
  - Events and RSVP
  - Notifications (including 24-hour reminders)
  - Search and discovery
  - Admin panel
- Timeline in SRS is explicitly 8 weeks.
- Primary backend in the PDFs is Firebase (Auth, Firestore, Storage, FCM).

## Architecture/Scope Notes

- The current project codebase uses Supabase for auth/profile flows.
- Requirement-level features from SRS can still be implemented with Supabase equivalents:
  - Firebase Auth -> Supabase Auth
  - Firestore -> Supabase Postgres + Realtime
  - Firebase Storage -> Supabase Storage
  - FCM -> push service integration (can still use FCM for mobile delivery)
- Decision needed before full build-out:
  - Option A: Continue with Supabase stack (recommended for current code continuity)
  - Option B: Migrate to Firebase to match SRS wording exactly

## Functional Requirements to Implement (FR)

### Authentication and User Management (FR-01 to FR-08)

- University email signup and domain validation
- Email/password login/logout
- Profile setup fields:
  - name
  - student ID
  - batch
  - section
  - department
  - avatar
- Role-based session handling
- Admin-controlled executive role assignment/revocation
- Profile edit capability after registration

### Club Feed and Posts (FR-09 to FR-16)

- Personalized feed from followed clubs
- Department-wide global feed
- Executive-only post creation (text/image)
- Pin one key post per club
- Reactions: Like, Fire, Clap
- Comments
- Executive edit/delete own posts
- Reverse chronological feed with pinned post precedence

### Club Management (FR-17 to FR-21)

- List all six clubs + more (can add)
- Follow/unfollow clubs( react, comment, can share in other social platform)
- Club details page with bio/cover/logo
- Show executive member list----andmin can see all the userdetails
- Executive can update club profile data

### Events (FR-22 to FR-27)

- Executive event creation (title, description, date/time, venue, poster)
- Upcoming events screen
- RSVP statuses: Going / Interested
- Event edit/cancel by executive
- Show RSVP counts
- 24-hour reminder notifications

### Notifications (FR-28 to FR-32)

- Notify followers on new post
- Notify followers on new event
- Notify users on comments
- Notification center screen with read/unread
- Mark all as read

### Search and Discovery (FR-33 to FR-35)

- Search posts, events, clubs, users
- Feed filtering by club/department
- Real-time search results while typing

### Admin Panel (FR-36 to FR-40)

- Admin-only dashboard
- Promote/revoke executives
- Delete any post/event
- Platform stats (users, posts per club, events)

## Non-Functional Targets (NFR)

- Home feed load under 3 seconds (4G baseline)
- Realtime update propagation under 2 seconds
- Push delivery target under 5 seconds
- Secure password handling via auth provider
- Role-based write restrictions at DB policy level
- Responsive UI for phone sizes
- Light and dark mode support
- APK target under 50 MB
- Maintainable modular codebase

## Week-by-Week Execution Plan (from SRS timeline)

## Week 1 - Setup and Authentication

- Project scaffold and architecture baseline
- Backend config and env setup
- Signup/login/logout screens
- Session persistence
- Initial role-aware session state
- Deliverable:
  - Working auth flow
  - user record creation

## Week 2 - Profiles and Clubs

- Profile setup/edit screens
- Avatar upload pipeline
- Club list screen and club detail scaffold
- Follow/unfollow feature
- Deliverable:
  - Live profile + club follow system

## Week 3 - Post System

- Executive-only create post flow
- Image upload for posts
- Post storage + retrieval
- Base feed rendering
- Deliverable:
  - Executives can publish notices, feed displays posts

## Week 4 - Feed and Interactions

- Personalized + global feeds
- Reaction model and UI
- Comment threads
- Pin post capability
- Deliverable:
  - Full interaction-capable feed

## Week 5 - Events Module

- Event create/edit/cancel
- Events listing and details
- RSVP model and counts
- Deliverable:
  - End-to-end event + RSVP module

## Week 6 - Notifications

- Push integration
- Triggering notifications from post/event/comment actions
- Notification center read/unread
- 24-hour reminder job
- Deliverable:
  - Live notification pipeline

## Week 7 - Admin and Search

- Admin dashboard
- Executive assignment/revocation workflow
- Admin moderation actions
- Search screen with realtime query
- Deliverable:
  - Admin controls + search fully functional

## Week 8 - Polish and Release Prep

- UI refinement and consistency pass
- Dark mode and accessibility pass
- Bug fixing and edge-case handling
- Performance tuning
- Release build preparation
- Deliverable:
  - Production-ready APK for submission

## Role-Based Access Rules (Implementation Baseline)

- Student:
  - View posts/events
  - React/comment
  - Follow clubs
  - RSVP
- Executive:
  - All student permissions
  - Create/edit own posts and events
  - Manage assigned club content
- Admin:
  - All permissions
  - Manage users/roles
  - Moderate any content
  - Access admin dashboard and platform stats

## Security Tasks (Must Implement)

- Enforce role checks in database policies, not only UI
- Prevent client-side self-assignment of executive/admin
- Validate university email domain at signup
- Restrict privileged operations to verified admin role
- Audit profile and role mutation APIs

## Data Model Baseline (minimum)

- users (auth-managed)
- profiles
- clubs
- club_memberships (follow relation)
- posts
- post_reactions
- comments
- events
- event_rsvps
- notifications
- admin_audit_logs

## Done Definition for v1

- All High-priority FR items complete
- Security policy tests pass for role-based access
- End-to-end auth, profile, club follow, post, event, and admin role assignment flows pass
- Notification flow works for core triggers
- App is stable enough for beta distribution

## Next Immediate Steps (Execution Order)

1. Finalize backend direction (Firebase strict vs Supabase equivalent).
2. Freeze schema for all modules and write migration files.
3. Complete authentication/profile/admin role governance end-to-end.
4. Build clubs and follow subsystem.
5. Continue week-by-week per this document.
