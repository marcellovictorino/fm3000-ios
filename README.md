# fm3000-ios

My own build of the official Infinitary iPhone app (`ios/Infinitary` in the Infinitary desktop source, Apache 2.0).
It pairs with the Mac like the official app and installs beside it under its own bundle identifier, `com.marcellovictorino.infinitary`.

The previous hand-written client is kept: tag `fm3000-final`, branch `archive/fm3000`.

## Build

1. Open `Infinitary.xcodeproj`, select the `Infinitary` target, Signing & Capabilities, and choose your own team.
2. Run on your phone. A free Apple account's builds stop opening after 7 days.
3. On the Mac: Settings → Devices → A phone, then scan the code or paste the link.

No team is committed; set it in Xcode (it stays local) or pass `DEVELOPMENT_TEAM=<id>` to `xcodebuild`.

## Take in a new Infinitary version

```
git checkout upstream && ./scripts/sync-upstream.sh   # one commit per version
git checkout main && git merge upstream               # keeps my changes
git push origin upstream main
```

Use a merge commit, not squash, so `upstream` stays an ancestor of `main`. See `AGENTS.md` and `CHANGES.md`.

## Licence

Apache 2.0 (`LICENSE`, `NOTICE`), copyright Kun Chen. Files I changed are listed in `CHANGES.md`.
