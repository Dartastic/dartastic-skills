---
name: dartastic-resource-attributes
description: Choose and set OpenTelemetry resource attributes for Dartastic apps and Dart servers - service.name, service.version, deployment.environment.name, build ids, flavors, white-label clients, distribution channel, tenants. Use this whenever someone is naming a service, setting OTEL_RESOURCE_ATTRIBUTES or resourceAttributes in DOTel.initialize, building one codebase for several brands or customers, adding flavors (dev, staging, prod), or asks why telemetry from two builds, environments or clients is mixed together or split apart in the Observatory.
---

# Resource attributes for Dartastic

A resource attribute describes the process that sent the telemetry, and it
is the same on every span, log and metric that process sends. Choose them
well and every Observatory screen can be filtered and compared by them;
choose badly and data from two builds is mixed, or one app is scattered
over ten service names.

## The test: is it fixed for the whole run?

Put a value on the resource only if it cannot change while the process
runs. The app's version, flavor, white-label client, store channel and
environment are fixed. The signed-in user, the user's tenant or plan, the
current screen, the network type and feature flag values are not: they go
on spans and logs, or on the session (see `dartastic-custom-telemetry`).
Changing a resource attribute means a new process.

## What Dartastic sets for you

Don't set these by hand; the SDK and the Flutter plugin discover them:

| Attribute                                                | From                                                   |
|----------------------------------------------------------|--------------------------------------------------------|
| `app.name`, `app.version`, `app.build.number`            | The platform's package info                            |
| `app.build_id`                                           | Version and build number (`1.4.0+27`)                  |
| `dartastic.snapshot.build_id`                            | The compiled binary itself; matches crashes to symbols |
| `app.installation.id`                                    | A per-install id                                       |
| `device.model.identifier`, `device.manufacturer`, `os.*` | The device                                             |
| `flutter.build.mode`                                     | release, profile or debug                              |
| `service.instance.id`                                    | A per-process id                                       |
| `telemetry.distro.name`, `telemetry.distro.version`      | The SDK                                                |

`flutter.app_package_name` is discovered too, except in obfuscated builds,
where it cannot be. Pass it in every release build (see
`dartastic-errors-and-symbols`).

## What you choose

### `service.name`: the product, not the package

Use a short, stable, kebab-case name for what the user knows as one
product: `checkout-app`, `orders-api`. Rules:

- The same name on every platform. Android, iOS and web builds of one app
  are one service; `os.type` already tells them apart.
- Not the pubspec package name (`my_app_v2`), not the bundle id, and not
  a name with a version, environment or client in it.
- Each backend gets its own name (`orders-api`, `payments-worker`), so the
  trace view shows which service did what.
- Serverless functions: one name for the codebase (`acme-functions`) plus
  `faas.name` for the function is easy to compare; one name per function
  is also fine when they are owned separately. Pick one and keep it.

Set it with `DOTel.initialize(serviceName: ...)` or `OTEL_SERVICE_NAME`.

### `service.version`: the release

The version users run, from `pubspec.yaml` for an app (`1.4.0`), or the
deployed release for a server (a semver or a git SHA). Keep it in one
place. Read it with `package_info_plus` in an app, or stamp it at build
time, rather than typing it twice.

### `deployment.environment.name`: where it runs

`dev`, `staging`, `prod` (or the team's own words, used consistently), and
`local` for a developer's machine or an emulator. Never mix environments
in one view: a production error rate that includes a developer's crash
loop is wrong. Resolve it from something exact (a build flavor, the cloud
project id) and fail loudly when it is unknown, rather than defaulting to
`prod`.

### Flavors

If the app has flavors (`--flavor dev`), pass the flavor's environment as
`deployment.environment.name`. Don't invent a separate flavor attribute
when it means the same thing.

### White-label builds: one codebase, several clients

When one codebase ships as several branded apps, keep **one
`service.name`** and add an attribute that names the client, so every
Observatory screen can compare clients or filter to one. There is no
OpenTelemetry convention for this, so use the developer's own namespace
(their company or product, reverse-domain style):

```text
acme.client.id   = "northwind"      (stable, lowercase, never shown to users)
acme.client.name = "Northwind Bank" (optional, for display)
```

Ask the developer for their namespace; never use `dartastic.*`, `app.*`,
`service.*` or another OpenTelemetry namespace for their own keys.
If each client must see only its own telemetry, that is a separate
organization per client (separate OTLP tokens), not an attribute.

### Distribution channel

When it matters which store a build came from, add
`acme.distribution.channel`: `play`, `app_store`, `testflight`,
`internal`, `enterprise`, `web`. Set it per build with a define.

### A tenant of a B2B app

A tenant is usually a property of the signed-in user, not of the process.
Put it on spans (and in baggage to reach the backend; see
`dartastic-distributed-tracing`), not on the resource. The exception is a
backend deployed once per tenant: there it is fixed, so it belongs on the
resource.

## How to set them

Precedence, highest first: attributes passed in code to `DOTel.initialize`
(`resourceAttributes:`), then `OTEL_RESOURCE_ATTRIBUTES`, then what the
plugin discovers.

**Per build, without code**, with a define (comma separated `key=value`):

```sh
flutter build ipa --release --flavor prod \
  --dart-define=OTEL_RESOURCE_ATTRIBUTES=deployment.environment.name=prod,acme.client.id=northwind,flutter.app_package_name=acme_app
```

**In code**, with keys as constants rather than strings scattered through
the app:

```dart
enum AcmeResource implements OTelSemantic {
  clientId('acme.client.id'),
  distributionChannel('acme.distribution.channel');

  const AcmeResource(this.key);
  @override
  final String key;
}

final identity = await DartasticAppIdentity.resourceAttributes();
await DOTel.initialize(
  serviceName: 'acme-app',
  serviceVersion: info.version,
  resourceAttributes: identity.copyWithAttributes(
    DOTel.attributesFromSemanticMap({
      Deployment.deploymentEnvironmentName: flavor.environment,
      AcmeResource.clientId: flavor.clientId,
    }),
  ),
);
```

Use the OpenTelemetry semantic-convention constants for standard keys
(they come with the SDK) and an enum implementing `OTelSemantic` for the
app's own. On a server, `OTEL_RESOURCE_ATTRIBUTES` in the deployment's
environment is usually simplest.

## Never on the resource

- Anything personal: email, name, phone, precise location, device name
  (which is often the owner's name).
- Secrets or tokens.
- Values with many distinct values that change per run, such as a
  timestamp or a random id. `service.instance.id` already identifies the
  process.

## Check it

After a run, use `dartastic-verify-telemetry` to list the services and
open one span. Confirm `service.name`, `service.version`,
`deployment.environment.name` and each custom attribute are present, with
the values you meant.
