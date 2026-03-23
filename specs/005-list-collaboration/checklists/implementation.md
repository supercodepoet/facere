# Implementation Readiness Checklist: List Collaboration

**Purpose**: Validate that requirements are complete, clear, and unambiguous before Claude Code begins implementation. "Unit tests for English."
**Created**: 2026-03-23
**Feature**: [spec.md](../spec.md) | [plan.md](../plan.md) | [tasks.md](../tasks.md)

## Requirement Completeness

- [ ] CHK001 Are authorization requirements defined for ALL existing controllers that touch todo_list data (items, sections, comments, checklist_items, tags, attachments, notify_people)? [Completeness, Spec §FR-020]
- [ ] CHK002 Are requirements defined for what happens when a collaborator's session is active and they are removed mid-session? (e.g., do they see an error on next action, or are they force-redirected?) [Gap, Spec §FR-014]
- [ ] CHK003 Is the invitation email content specified — what information must it include (list name, inviter name, role, expiration date)? [Completeness, Spec §FR-003]
- [ ] CHK004 Are requirements defined for the invitation acceptance landing page when the user is NOT logged in? (redirect to sign-in? show list preview?) [Gap, Spec §US1]
- [ ] CHK005 Is the collaboration panel's trigger location and behavior specified — where does it appear, how does it open (modal, slide-out, inline)? [Completeness, Spec §US1]
- [ ] CHK006 Are requirements specified for what the owner sees when all 25 collaborator slots are filled? (disabled invite button? message?) [Completeness, Spec §FR-001]
- [ ] CHK007 Are requirements defined for the `item_assignees` data migration — what happens to existing `assigned_to_user_id` data during the transition? [Gap, data-model.md §item_assignees]
- [ ] CHK008 Is the behavior specified for when a list owner tries to edit their own list's name/description/color — are these still owner-only or editor-accessible? [Gap, Spec §FR-007]

## Requirement Clarity

- [ ] CHK009 Is "immediately revoking access" (FR-014) quantified — does it mean next request returns 404, or real-time broadcast disconnects the user? [Clarity, Spec §FR-014 / SC-005]
- [ ] CHK010 Is "collaboration indicator" (FR-016) defined with specific visual requirements — avatar stack, count badge, sharing icon, or all three? [Clarity, Spec §FR-016]
- [ ] CHK011 Is the term "collaborator pool" consistently defined — does it include the owner, or just invited collaborators? (Spec says "including the owner" in FR-010 but "collaborator pool" is used loosely elsewhere) [Clarity, Spec §FR-010/FR-011]
- [ ] CHK012 Is "historical record" (US3 acceptance scenario 3) defined — does it mean the avatar stays on the item, or just that the item_assignee DB record persists? What does the UI show for a removed user's assignment? [Clarity, Spec §US3]
- [ ] CHK013 Is "Shared by [name]" on the overview card specified — is it the owner's full name, first name, or initials? [Clarity, Spec §FR-006]
- [ ] CHK014 Are the email notification templates' required fields clearly enumerated for both invitation and completion emails? [Clarity, Spec §FR-003/FR-012]

## Requirement Consistency

- [ ] CHK015 Are editor permissions consistent across items and sections? (FR-007 lists items + sections, but US2 acceptance scenarios only mention items — sections are implied but not explicitly tested) [Consistency, Spec §FR-007 vs §US2]
- [ ] CHK016 Is the viewer commenting permission consistent between FR-008 (viewers cannot modify) and FR-009 (viewers can comment)? Specifically: can viewers like comments? (existing CommentLike model) [Consistency, Spec §FR-008 vs §FR-009]
- [ ] CHK017 Is the "Shared with me" sidebar behavior consistent between the sidebar partial (US8) and the overview page (US8)? Both should show the same shared lists. [Consistency, Spec §US8]
- [ ] CHK018 Are the owner's permissions consistently defined — can the owner do everything an editor can PLUS manage collaborators, or is the owner a separate role with its own distinct permission set? [Consistency, Spec §FR-002/FR-017]
- [ ] CHK019 Is the comment deletion behavior consistent — FR-009 says viewers can comment, but can a viewer delete their OWN comment? (US5 says "users can edit and delete their own comments" but is that scoped to all collaborators?) [Consistency, Spec §US5 vs §FR-008]

## Acceptance Criteria Quality

- [ ] CHK020 Can SC-002 ("95% of users can successfully invite") be objectively measured during development, or is it aspirational? [Measurability, Spec §SC-002]
- [ ] CHK021 Can SC-007 ("identify shared lists within 2 seconds") be objectively verified without user testing? [Measurability, Spec §SC-007]
- [ ] CHK022 Is SC-009 ("within 2 seconds") achievable with SQLite + Solid Cable in production? Are there requirements for measuring broadcast latency? [Measurability, Spec §SC-009]
- [ ] CHK023 Are acceptance scenarios defined for the invitation expiration flow — what does the user see when clicking an expired link? [Gap, Spec §FR-018]
- [ ] CHK024 Are acceptance scenarios defined for the "leave list" flow — is there a confirmation prompt? Where does the user land after leaving? [Gap, Spec §FR-015]

## Scenario Coverage — Authorization

- [ ] CHK025 Are requirements defined for what happens when a viewer accesses an item detail URL directly — do they see the full detail page with disabled controls, or a restricted view? [Coverage, Spec §US6]
- [ ] CHK026 Are requirements defined for CommentLikesController authorization — can viewers like comments? Can removed collaborators' likes persist? [Gap]
- [ ] CHK027 Are requirements defined for what status code unauthorized access returns — 404 per constitution, but is this explicitly stated in the spec? [Coverage, constitution §Security vs Spec §FR-020]
- [ ] CHK028 Are requirements defined for preventing a collaborator from inviting others? (FR-017 says "managing other collaborators' roles" but does "managing" include sending invitations?) [Clarity, Spec §FR-017]

## Scenario Coverage — Invitation Flow

- [ ] CHK029 Are requirements defined for inviting someone who already has a PENDING invitation on the same list? (Spec §US1 scenario 4 covers "already a collaborator" but not "already invited") [Coverage, Spec §US1]
- [ ] CHK030 Are requirements defined for what happens when an invitation token is used twice (e.g., user clicks the email link after already accepting)? [Edge Case, Gap]
- [ ] CHK031 Are requirements defined for case sensitivity in invitation emails — is "User@Example.com" treated the same as "user@example.com"? [Edge Case, Spec §FR-001]
- [ ] CHK032 Are requirements defined for rate limiting invitation sends — can an owner spam invitations? [Gap, Non-Functional]
- [ ] CHK033 Are requirements defined for the invitation cancellation flow — does the cancelled invitation's token immediately become invalid? [Coverage, Spec §FR-019]

## Scenario Coverage — Real-Time Broadcasting

- [ ] CHK034 Are requirements defined for which specific model changes trigger broadcasts — is it all CRUD on items/sections/comments, or a specific subset? [Completeness, Spec §FR-021]
- [ ] CHK035 Are requirements defined for broadcast scope — does a change on one item broadcast to ALL collaborators viewing the list, or only those viewing that specific item? [Clarity, Spec §FR-021]
- [ ] CHK036 Are requirements defined for handling broadcast failures — what if a collaborator's WebSocket connection drops? Do they see stale data with no indication? [Gap, Non-Functional]
- [ ] CHK037 Are requirements defined for broadcast behavior during the `assigned_to_user_id` → `item_assignees` migration — will broadcasts work correctly during/after the data migration? [Gap, data-model.md]

## Scenario Coverage — Edge Cases

- [ ] CHK038 Are requirements defined for a user who is both the owner of list A and a collaborator on list B — do sidebar sections correctly separate these? [Edge Case, Spec §US8]
- [ ] CHK039 Are requirements defined for the search functionality in the sidebar/header — should search include shared lists? [Gap, Spec §US8]
- [ ] CHK040 Are requirements defined for what happens to items assigned to a removed collaborator — does the avatar show a "removed user" state, or does it just show their original initials? [Edge Case, Spec §FR-014]
- [ ] CHK041 Are requirements defined for what happens when the owner of a shared list changes their email — do existing invitations to the old email still reference the correct list? [Edge Case, Gap]
- [ ] CHK042 Are requirements defined for mobile responsiveness of the collaboration panel? [Gap, constitution §III Joyful UX / responsive]

## Non-Functional Requirements

- [ ] CHK043 Are performance requirements defined for loading shared lists — eager loading strategy for collaborator associations to prevent N+1? [Non-Functional, constitution §IV]
- [ ] CHK044 Are security requirements defined for the invitation token — length, entropy, resistance to brute force? (Or is `generates_token_for` sufficient as documented?) [Non-Functional, Spec §Clarifications]
- [ ] CHK045 Are requirements defined for email delivery failures — what if the invitation email bounces? Is there retry logic or owner notification? [Non-Functional, Spec §Edge Cases]
- [ ] CHK046 Are accessibility requirements defined for the collaboration panel — keyboard navigation, screen reader labels for role pickers and avatar stacks? [Non-Functional, constitution §III / WCAG 2.1 AA]

## Dependencies & Assumptions

- [ ] CHK047 Is the assumption that `generates_token_for` handles token expiration automatically validated against the 30-day requirement? [Assumption, Spec §FR-018 / research.md §2]
- [ ] CHK048 Is the assumption that Solid Queue is configured and running for `deliver_later` email delivery validated? [Assumption, research.md §5]
- [ ] CHK049 Is the dependency on the existing `assigned_to_user_id` column documented for the migration path — are there views, partials, or Stimulus controllers that reference `assigned_to` that must be updated? [Dependency, data-model.md]
- [ ] CHK050 Is the assumption that `turbo_stream_from` with signed stream names provides sufficient authorization validated — can a malicious user subscribe to another list's stream? [Assumption, research.md §7]

## Notes

- Check items off as completed: `[x]`
- Items marked [Gap] indicate requirements that may need to be added to spec.md
- Items marked [Clarity] indicate requirements that exist but need sharpening
- Items marked [Consistency] indicate potential conflicts between spec sections
- Claude Code should address [Gap] and [Clarity] items by making reasonable decisions during implementation and documenting them in the spec's Clarifications section
