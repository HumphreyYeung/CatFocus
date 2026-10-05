# CatFocus Analytics Events

CatFocus uses Firebase Analytics (Google Analytics for Firebase) for anonymous product analytics. Do not send names, email addresses, free-text onboarding answers, notification contents, or other direct identifiers as Analytics parameters.

## Event schema

| Event | Trigger | Parameters |
| --- | --- | --- |
| `onboarding_started` | Onboarding flow first appears in this app view | — |
| `onboarding_step_completed` | User advances from a step; back-navigation is not counted | `step_name` (fixed values: `greeting_one`, `greeting_two`, `greeting_three`, `name`, `problems`, `goal`, `suggestion`, `trial`, `trial_finish`, `contract`, `notifications`) |
| `onboarding_completed` | Notification permission request resolves and onboarding finishes, whether granted or denied | — |
| `focus_session_started` | Focus timer first starts | `duration_minutes`, `is_first_session` |
| `focus_session_completed` | Timer reaches its planned duration | `planned_duration_minutes`, `actual_duration_seconds` |
| `focus_session_ended_early` | User confirms slide-to-cancel | `planned_duration_minutes`, `elapsed_seconds` |

Firebase's automatically collected `first_open`, `session_start`, and `user_engagement` events are the baseline for acquisition, active users, and retention. Avoid adding custom app-open or heartbeat events to duplicate them.

## Reports to build

Use Firebase Analytics reports for active users, retention, and event counts. For a step funnel and custom comparisons, open the linked Google Analytics 4 property and use **Explore → Funnel exploration**:

1. Onboarding funnel: `onboarding_started` → `onboarding_step_completed` (break down by `step_name`) → `onboarding_completed` → `focus_session_started` filtered to `is_first_session = true`.
2. Focus funnel: `focus_session_started` → either `focus_session_completed` or `focus_session_ended_early`.
3. Focus engagement: compare `focus_session_started` and `focus_session_completed` by `duration_minutes` / `planned_duration_minutes`; use `actual_duration_seconds` as the observed session length.
4. Retention: use Firebase/GA4 retention cohorts, and compare returning cohorts with `focus_session_completed`.

The GA4 property's **Admin → Custom definitions** now includes event-scoped dimensions for `step_name` and `is_first_session`. Definitions are not retroactive; allow time for newly collected events to populate reports. Register duration parameters as custom metrics only if aggregate duration reporting is needed. DebugView is for validating event delivery and is not a production dashboard.

The Firebase project has Google Analytics enabled and the CatFocus iOS data stream is linked. The GA4 property currently reports no iOS app data in standard reports; debug-mode events are for validation and are not a substitute for production reporting. Confirm normal (non-debug) events arrive after launching the app without Analytics debug mode, then build/save the funnel explorations described above.

## Verification

Enable Analytics debug mode for the development device, then inspect **Firebase Console → Analytics → DebugView** while exercising onboarding and one short focus session. Confirm event names, parameters, and one terminal outcome per focus session. Turn off debug mode before normal production use if it was enabled manually.
