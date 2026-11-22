# App Check

App Check makes Firestore and Auth accept requests only from a binary the
platform can vouch for. This repository now registers the providers. It does
**not** enforce anything: enforcement is a per-product switch in the Firebase
console, and no agent may touch the console.

## What the code does

`lib/app/app_check.dart` picks the providers. `CloudConnectionService.connect()` in
`lib/core/services/cloud_connection_service.dart` (called from `lib/app/bootstrap.dart`)
calls `activateAppCheck(env: appEnv, isDebugBuild: kDebugMode)`
right after `Firebase.initializeApp`, before the emulator switch, the anonymous
sign-in and the first Firestore read. Requests made after that carry a token.

| Build | Android | iOS |
| --- | --- | --- |
| `APP_ENV=dev`, debug (`kDebugMode`) | `AndroidDebugProvider` | `AppleDebugProvider` |
| everything else, including `APP_ENV=prod` in debug | `AndroidPlayIntegrityProvider` | `AppleAppAttestWithDeviceCheckFallbackProvider` |

The debug provider mints tokens anyone can copy, so it is limited to dev debug
builds. `test/app_check_providers_test.dart` fails if a production build ever
selects it. The package is `firebase_app_check: ^0.5.1`; the provider classes
come from the package's own exports, not from memory.

## What is still an owner step

None of this can be done from the repository, and nothing below has been done
yet. Until step 1 and 2 are finished the app still boots, sends unattested
requests and the console reports them as unverified.

1. Register the providers in the console, per project, per app.
   - Android `sleep-optimizer-59c83` (app id `1:790423794853:android:b834a222cb28203f1fc94c`)
     and the dev project's Android app: App Check → Apps → Play Integrity.
     Play Integrity also has to be enabled for the project in Google Cloud.
   - iOS `com.snoozefriend.snoozemate` in both projects: App Check → Apps →
     App Attest. This needs the **App Attest capability added in Xcode**
     (Signing & Capabilities → + Capability → App Attest). Without that
     entitlement `activate` throws on iOS and the app stops on its boot error
     screen. If the capability cannot be added for a build, use DeviceCheck
     instead and say so here.
2. Register one debug token for the dev project only. Run a dev debug build,
   copy the token it prints, then App Check → Apps → dev Android app → Manage
   debug tokens → Add. Never add a debug token to the production project, and
   never commit one.
3. Watch the numbers before switching anything on. In App Check → APIs →
   Firestore (then Identity Toolkit), read *Unverified requests* for the dev
   project for at least a day of real use, then for production. The metric
   should fall to near zero once steps 1 and 2 work. A large unverified count
   means the app is still shipping without attestation, and enforcement would
   break those clients.

## How to check it works

- Debug build: the debug provider prints its token in the run log. A token
  shows up in App Check → Apps → dev app → Debug tokens after the first use.
- Release or profile build: App Check → Apps → request metrics show
  *Verified* requests climbing next to *Unverified* ones.
- Wrong provider on purpose (mismatched project): requests fail with
  `permission-denied` once enforcement is on, and *Verified* stays at zero.

## Enforcement and rollback

Enforcement is a console action for the project owner, one product at a time
(Firestore first, Auth later), after step 3 shows a clean metric. Turning it on
does not need a release.

Rollback is the same screen: turn the enforcement switch off. It applies within
minutes and needs no deploy. If clients are already broken, also check that the
shipped build is the one with `activateAppCheck` in `bootstrap.dart` and not an
older binary from before this change.

## Limits worth knowing

- Enforcement is per product and per project. Turning it on for Firestore in
  production hides nothing else.
- App Check does not replace `firestore.rules`. It says *which app* is calling;
  the rules still say *which user* may read what.
- Emulator runs (`USE_FIREBASE_EMULATOR=true`) ignore App Check. A dev debug
  token is only useful against the real dev project.
