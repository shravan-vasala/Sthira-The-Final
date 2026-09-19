# Social Firestore rules regression tests

Run from this directory with Node 20+ and a supported Java runtime:

```
npm install
firebase --config ../../firebase.emulator.json emulators:exec --only firestore --project demo-sthira-social "npm test"
```

The demo project runs locally; these tests do not use production accounts. The harness mirrors the client's atomic request, acceptance, acknowledgement and removal operations. Deploy the updated rules together with the updated client. Pending legacy requests remain acceptable; ambiguous legacy accepted markers are not automatically replayed because doing so can restore revoked access.

Latest verified checkpoint: **21 local emulator tests passed**, including request identity/state protection, recipient availability and private profile visibility. See [social audit](../../docs/social-connection-and-friend-details-review.md). This does not deploy rules or verify production accounts.
