# Case Module Design: CQRS + Event Sourcing

> Source PRD: PRD_AILU.md

## Goal
Build a robust case and advocate matching backend using CQRS and event sourcing for auditability and future scaling.

## Key concepts

- Command side: handles intent, validation, business rules, and emits domain events.
- Event store: append-only persistent store of all domain events by case aggregate ID.
- Projection handlers: consume events to update query/read models for fast retrieval.
- Query side: read models optimized for UI queries and reporting.

## Interfaces

### Command gateway

`ICaseCommandService`
- `Task<CommandResult> HandleAsync(ICaseCommand command);`

`ICaseCommand` includes:
- `Guid CaseId`
- `Guid ActorId` (user performing action)
- `DateTimeOffset Timestamp`

Commands:
- `CreateCaseCommand` (title, court, parties, fee type, initial advocate preference)
- `UpdateCaseCommand` (partial edit fields)
- `AddCaseDocumentCommand` (doc metadata + storage key)
- `AssignAdvocateCommand` (advocateId, role=Vakalat/Review)
- `RequestReviewAdvocateCommand` (review reason, target advocate criteria)
- `UpdateCaseStatusCommand` (new status, note)

### Event store

`ICaseEventStore`
- `Task AppendAsync(Guid aggregateId, IReadOnlyCollection<IDomainEvent> events);
- `Task<IReadOnlyCollection<IDomainEvent>> LoadAsync(Guid aggregateId);`
- `Task<bool> ExistsAsync(Guid aggregateId);`

Domain events:
- `CaseCreated` (initial metadata)
- `CaseUpdated`
- `CaseDocumentAdded`
- `AdvocateAssigned`
- `ReviewAdvocateRequested`
- `CaseStatusChanged`
- `CaseAccessChecked` (optional security audit)

### Case aggregate root (write-side business logic)

`CaseAggregate` accepts events and state:
- state fields: case metadata, assigned advocates, status, history ids
- methods: `Apply` for each event type
- method: `Handle(CreateCaseCommand)` etc. returns events
- invariants:
  - can only assign one primary vakalat advocate
  - status transitions follow valid set
  - documents can only be added in relevant statuses

### Projection handlers

Examples:
- `CaseReadModelProjection` updates case view store
- `CaseHistoryProjection` stores per-case timeline items
- `CaseMetricsProjection` updates counters (monthly cases, active, conversion)

Each projection implements:
- `Task HandleAsync(IDomainEvent @event)`

### Query gateway

`ICaseQueryService`
- `Task<CaseReadModel> GetCaseAsync(Guid caseId);`
- `Task<PagedResult<CaseReadModel>> SearchCasesAsync(CaseSearchCriteria criteria);`
- `Task<IEnumerable<AdvocateProfile>> SearchAdvocatesAsync(AdvocateSearchCriteria criteria);`
- `Task<CaseDashboard> GetCaseDashboardAsync(Guid ownerId);`

### Advocate matching support

`AdvocateSearchCriteria` fields:
- `PracticeArea`, `Region`, `PenaltyStatus`, `RatingMin`, `Availability`
- `IncludeReviewSupport` (for second-opinion requests)

`AdvocateMatchService` (or query service helper) uses weighted scoring and fallback to manual.

## Persistence

Write model event store can use PostgreSQL table `case_events`:
- `aggregate_id`, `sequence`, `event_type`, `data`, `created_at`

Read model tables:
- `case_read_models`, `case_history`, `case_metrics`.

## Anticipated API flow

1. Client: `POST /cases` → command service `CreateCaseCommand`.
2. Command handler creates case aggregate, emits `CaseCreated`.
3. Event store append + projections update `case_read_models`.
4. Client: `GET /cases/{id}` → query service returns from read model.
5. Advocate assignment via `POST /cases/{id}/assign` → `AssignAdvocateCommand` → event `AdvocateAssigned`.
6. History and metrics are automatically updated via projections.

## Acceptance criteria

- [ ] Case creation through command is stored as `CaseCreated` event.
- [ ] Case read model is available immediately from projections.
- [ ] Assigning advocate emits event + updates both case state + query model.
- [ ] Case status changes are validated and audited.
- [ ] Case document upload creates `CaseDocumentAdded` event and stores reference.

## Notes

- Keep command side isolated from query DB for performance and scaling.
- Keep all event objects small and explicit for easy migration.
- Consider compatibility hook for future external event consumers (webhooks / reporting).