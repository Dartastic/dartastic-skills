# Dartastic skills

Skills that teach coding agents to instrument Flutter and Dart apps well
with Dartastic: what to install, where to initialize, how to name things,
and how to check that the telemetry arrived.

| Skill                           | What it covers                                                                          |
|---------------------------------|-----------------------------------------------------------------------------------------|
| `dartastic-flutter-setup`       | Packages, tokens, `DOTel.initialize`, screens, taps, sessions, replay, release builds   |
| `dartastic-resource-attributes` | Service names, versions, environments, flavors, white-label clients                     |
| `dartastic-errors-and-symbols`  | Uncaught and handled errors, crashes, obfuscated builds, publishing symbols             |
| `dartastic-custom-telemetry`    | The app's own spans, metrics, logs and attribute keys                                   |
| `dartastic-distributed-tracing` | App to server traces: Dart servers, Firebase Functions in Dart and TypeScript, CORS     |
| `dartastic-webviews`            | Telemetry from pages inside a WebView                                                   |
| `dartastic-integrations`        | The 651 open-source `otel_*` packages for libraries and services; LLM and payment calls |
| `dartastic-verify-telemetry`    | Proving it works with the Dartastic MCP server                                          |

## Install in Claude Code

```sh
claude plugin marketplace add dartastic/dartastic-skills
claude plugin install dartastic@dartastic
```

Or, inside Claude Code, `/plugin marketplace add dartastic/dartastic-skills`,
then `/plugin install dartastic@dartastic`.

## Install from the zip

Download `dartastic-skills.zip` from the Dartastic Help page **AI
assistants**, then unzip it into your skills folder:

```sh
unzip dartastic-skills.zip -d ~/.claude/skills        # every project
unzip dartastic-skills.zip -d .claude/skills          # this project only
```

Each folder is a standard Agent Skill (a `SKILL.md` and its references), so
other assistants that read the Agent Skills format can use the same files.

## Use them

Ask for what you want, in your own words: "add Dartastic to this app",
"why is this stack trace unreadable", "trace the checkout call through to
the Firebase function". The agent picks the skill that fits.

For the verification skill, connect the Dartastic MCP server too (see the
Help page **AI assistants**).

## Requirements

Flutter 3.44 and Dart 3.12 or newer for every feature, and the Dartastic
packages at 1.26.3 or newer.

## License

Apache-2.0. See [LICENSE](LICENSE).
