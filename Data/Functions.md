# Functions

Every script under `Modules` that is a function. The router looks up `<Module> <Action>` here and dispatches the
function by its level.

## Schema

`FunctionName: string`: The script name (`Fn` + Module + Action).

`FunctionModule: string`: The module, as typed on the command line (case insensitive).

`FunctionAction: string`: The action, as typed on the command line (case insensitive).

`FunctionLevel: Organization | Suite | Project | Root`: The level the function runs at.
- `Organization`: called once as `Fn <OrgId> <Args...>`. Only reachable from an organization entry (`considera ...`).
- `Suite`: called as `Fn <OrgId> <SuiteId> <Args...>`. From an organization entry it runs once per active suite; from a
  suite entry it runs once. It never takes a project: a project argument is rejected.
- `Project`: called as `Fn <OrgId> <SuiteId> <ProjectId> <Args...>`. Fans out over every active suite and project unless
  a suite or project is given.
- `Root`: internal helper. Never dispatched.

`FunctionDescription: string`: One line. No commas, since the readers split on them.
