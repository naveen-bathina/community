# ADR 0003: Single Community-Wide Group Chat Instead of Multiple Groups

**Status:** Accepted  
**Date:** 2026-11-01  
**Deciders:** Product Owner  

## Context

Group chat functionality could be implemented in multiple ways:

- **Single community-wide group chat:** One chat for all approved Members
- **Multiple topic-based groups:** Practice area groups (Family Law, Immigration, etc.), regional groups, interest groups
- **Hybrid:** Main community chat plus optional sub-groups
- **No group chat:** Only 1-1 conversations

For a legal professional networking platform, we need to balance community cohesion with focused discussions.

## Decision

We will implement a **single community-wide Group Chat** visible to all approved Members, with no support for multiple groups or sub-chats.

## Consequences

### Positive
- **Simple architecture:** One Firestore collection for group messages, straightforward security rules
- **Community cohesion:** Everyone participates in the same conversation space
- **No fragmentation:** All Members see all community discussions
- **Easier moderation:** Admins monitor one chat instead of many
- **Lower data usage:** Clients sync one chat stream instead of multiple
- **Clear purpose:** Group Chat is for community-wide networking; 1-1 Conversations handle specific topics

### Negative
- **Signal-to-noise ratio:** All topics in one chat may become noisy as membership grows
- **No topic focus:** Can't have dedicated spaces for practice areas or regions
- **Scalability concerns:** One high-traffic chat could become overwhelming with 500+ Members
- **No privacy tiers:** Can't have private sub-groups for specific cohorts

### Neutral
- Members can mute Group Chat notifications if it becomes too active
- Important discussions naturally move to 1-1 Conversations
- Admins can pin important messages to surface them above chatter

## Alternatives Considered

**Multiple topic-based groups:**
- Rejected: Added complexity for MVP; unclear which groups to create; risk of empty/dead groups

**Hybrid (main + sub-groups):**
- Rejected: Double the implementation work; better to validate single group first

**No group chat (1-1 only):**
- Rejected: Community-wide coordination is a core requirement

## When to Revisit

Reconsider adding multiple groups when:
- The single Group Chat consistently has 100+ messages per day and Members report it's too noisy
- Clear demand emerges for practice area or regional sub-groups
- Moderation burden grows due to off-topic discussions
- User feedback strongly requests topic-specific spaces

**Migration path:** A future "Groups" feature could be added without removing the main community chat—it would become one group among many.

## Implementation Notes

- Firestore collection: `groupChat` (flat collection of message documents)
- Security Rules: All approved Members can read; only non-muted Members can write
- Admins can delete any message, pin messages, and mute Members from Group Chat participation
- Message ordering: Server timestamp, paginated with infinite scroll
