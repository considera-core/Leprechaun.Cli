# Outstanding Issues

Known problems and loose ends in Leprechaun.Cli, Leprechaun.Gui and Leprechaun.Bff, as of 2026-11-25.

## CLI: behavior

- **Functions exit 0 on error.** The template's DESTRUCTOR ends with `EXIT /B %ERRORLEVEL%` right after `CALL FnEtcLogError`,
  which exits 0. Callers can't see failures: the dispatchers' "failed for ..." summaries never trigger for template
  functions, and `FnGitMerge*` has to check which branch it landed on instead of trusting `FnGitStory`/`FnGitHome`.
- **Resolvers and data readers clobber the caller's inputs.** `FnEtcResolve*` and `FnEtcData*` have no `SETLOCAL` and
  `SET Input_OrgId/Input_SuiteId/Input_ProjectId` themselves. Harmless when the values match, but `FnEtcRouter` has to
  reset them after each call. Cleaner: give them `SETLOCAL` and export only `Output_*` through `ENDLOCAL & SET`.
- **Stale `Output_Resolved_*` breaks lookups.** `FnEtcResolveSuite` skips its mapping loop while
  `Output_Resolved_SuiteId` is already defined, so a second resolve in the same scope can report a real suite as unknown
  when the cache misses. `FnEtcResolveProject` checks a local and is fine.
- **`FnEtcFlags` expands wildcards.** It loops `FOR %%T IN (%*)`, so an argument with `*` or `?` is matched against
  files. `FnAwsCloudFrontInvalidate` therefore always invalidates `/*` and takes no paths.
- **A project-shaped argument is always taken as the project.** From a suite entry, the first argument after the action
  is the project when it names one (`ConsideraWeb git story beta` targets project `beta`, not a branch called `beta`).
- **New-tab mode and quotes.** Without `--here`, functions re-run themselves through `powershell -Command "..."`.
  `FnGitExec`, `FnNpmExec` and `FnNpxExec` turn `"` into `'`; every other function passes its arguments raw, so a quoted
  argument breaks the tab's command line.
- **`Modules.Definitions.csv` is not enforced.** The router runs any module on any project. `FnEtcResolveModule` and
  `FnEtcResolveProjectModuleDefinition` exist but nothing calls them.
- **External projects are included in fan-out.** `FnEtcDispatchSuite` loops every project, including `IsExternal=true`
  ones (`cli`, `proxy`), while `FnEtcForEachProject` skips them. Pick one rule.
- **Organization root path has no drive letter** (`/Environments/Considera/Dev`), so paths depend on the current drive.

## CLI: data and leftovers

- `ConsideraWeb.Ng.MusicPortal` does not exist on disk, so every suite-wide command logs a path error for `music`.
- `FnAwsProfile` builds `consideraweb` / `consideraweb_prod`, but the samconfig files use `consideraweb-dev` /
  `consideraweb-prod`. It also only `SETX`es, so the current terminal is not updated.
- `FnGitState.bat` is empty and left out of `Functions.csv`; `FnGitPush` and `FnEtcHelp` are stubs.
- Legacy and unused: `FnEtcDispatch`, `FnEtcDispatchGlobal`, `FnEtcDispatchExternal`, and `FnEtcDispatchInternal` (which
  calls a `leprechaun function ...` command that no longer exists). `Leprechaun.bat` has `exec`/`function` commented out,
  and `edit` opens the old `LazyPolyRepoExpress` path.
- `_FnTemplate.bat` and `FnGitCommit.bat` still print a stray `echo 1` in `--help`, and the template calls
  `FnEtcResolveSuite`/`FnEtcResolveProject` without the OrgId/SuiteId they need.
- Git tracks both `config/` (lazy.default/static) and `Config/Lazy.config`. They are one folder on Windows, two on a
  case-sensitive checkout.
- `Lazy.cache` can hold a bare `=` line (from `ECHO. >` when the cache is created). Harmless; the BFF skips it.
- Fixed while working, worth knowing: `FnEtcCacheGet` used to clear every `Local_*` variable in its caller, which
  silently emptied values that callers set before resolving. And `FnEtcResolveOrganization/Suite/Project` read their
  row with `%Local_Index%` inside a `FOR` block, which is always `0`, so on a cache miss every lookup returned the first
  row of the CSV (a new project resolved to BetaPortal).
- `leprechaun-gui` and `leprechaun-bff` depend on each other on purpose, so launching either with `--deps` starts both.
  That is a cycle in the data, and stays safe only because `FnAppLaunch --deps` goes one level deep: dependencies are
  launched without `--deps`. Anything that walks dependencies recursively will need cycle detection.
- Leprechaun.Gui and Leprechaun.Bff live in ConsideraCore but are registered in the ConsideraWeb suite with
  `../ConsideraCore/...` paths. Leprechaun.Bff has no git repo yet, so the git module fails for it.

## CLI: untested

Not run live, because they need a feed, credentials, a running app or AWS: `FnNuget*`, `FnNpmCoverage`, `FnNpxKnip`,
`FnGitCountDependabot`, `FnGitRefreshDependabot`, `FnGitVulns`, `FnIdeRiderDebug` (uses `rider64 attach-to-process`),
`FnAwsSam*`, `FnAwsCloudFrontInvalidate`, and new-tab mode (running without `--here`) in general.

## Leprechaun.Gui

- **Private package not installed from the registry.** `NODE_AUTH_TOKEN` is not set on this machine. `node_modules`
  holds a local build of `ConsideraWeb.Extensions` master (0.0.0-development) plus `@angular/localize`; `package.json`
  and `package-lock.json` still name the registry version. Run `npm i` with the token to replace them.
- The library source declares `@tylertech/forge-angular ^7.2.0` as a peer while the template uses `^9.4.0`.
- Only compiled and served; the pages have not been looked at in a browser yet. Design is bare.
- Template leftovers that don't fit a local tool: `.github/workflows` (S3 deploy), `release/`, and the CDN steps in
  `TODO.md`. The `home` route just redirects to `modules`.
- No jobs list: a page shows only the job it started. Old jobs are still on the BFF (`GET /api/jobs`).
- Editing Data/Config/Cache while a command runs has no locking; last write wins.

## Leprechaun.Bff

- No authentication. It listens on localhost only, but anything on this machine can run commands through it.
- Jobs are kept in memory until deleted or the BFF restarts; nothing trims them.
- Without `--here`, functions open Windows Terminal tabs from the BFF's process.
- Not in git yet, and no tests.
