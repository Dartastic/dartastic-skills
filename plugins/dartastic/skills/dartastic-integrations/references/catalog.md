# otel_* packages

All are on pub.dev under Apache-2.0, depend only on the OpenTelemetry API,
and work with DOTel once `DOTel.initialize` has run and the
`dependency_overrides` entry is in place. Add with `flutter pub add <name>`
(or `dart pub add`), then check its README for the version you got.

## Network

| Package                   | Instruments          | Setup                                                     |
|---------------------------|----------------------|-----------------------------------------------------------|
| `otel_http`               | `http`               | `OTelHttpClient(http.Client())`                           |
| `otel_dio`                | `dio`                | `dio.interceptors.insert(0, OTelDioInterceptor())`        |
| `otel_chopper`            | `chopper`            | `ChopperClient(interceptors: [OTelChopperInterceptor()])` |
| `otel_graphql`            | `gql` links          | `OTelGraphqlLink` in the link chain                       |
| `otel_graphql_flutter`    | `graphql_flutter`    | As `otel_graphql`                                         |
| `otel_grpc`               | `grpc`               | `OTelGrpcClientInterceptor`, `OTelGrpcServerInterceptor`  |
| `otel_web_socket_channel` | `web_socket_channel` | `OTelWebSocketChannel(...)`                               |
| `otel_socket_io_client`   | `socket_io_client`   | `tracedSocketHandler(...)`                                |
| `otel_connectivity_plus`  | `connectivity_plus`  | `tracedCheckConnectivity()`, `listenConnectivityTraced()` |
| `otel_url_launcher`       | `url_launcher`       | `tracedLaunchUrl(uri)`                                    |

## Navigation

| Package           | Instruments  | Setup                                                                     |
|-------------------|--------------|---------------------------------------------------------------------------|
| `otel_go_router`  | `go_router`  | `GoRouter(observers: [OTelGoRouterObserver()])`, and on each `ShellRoute` |
| `otel_auto_route` | `auto_route` | `config(navigatorObservers: () => [OTelAutoRouterObserver()])`            |

These add route-change spans. Screen views and screen timing come from
`DartasticViewObserver`, which is still required.

## Firebase

| Package                   | Instruments          | Setup                                                        |
|---------------------------|----------------------|--------------------------------------------------------------|
| `otel_cloud_firestore`    | `cloud_firestore`    | `doc.tracedGet()`, `tracedSet`, `tracedFirestoreTransaction` |
| `otel_cloud_functions`    | `cloud_functions`    | `tracedHttpsCall(callable, name:, parameters:)`              |
| `otel_firebase_auth`      | `firebase_auth`      | `auth.tracedSignInWithEmailAndPassword(...)` and the others  |
| `otel_firebase_analytics` | `firebase_analytics` | `analytics.tracedLogEvent(...)`                              |

`otel_firebase_auth` records `enduser.id` unless `recordUserId: false`.

## State and app structure

| Package                 | Instruments        | Setup                                                    |
|-------------------------|--------------------|----------------------------------------------------------|
| `otel_bloc`             | `bloc`             | `Bloc.observer = OTelBlocObserver()`                     |
| `otel_flutter_bloc`     | `flutter_bloc`     | As `otel_bloc`                                           |
| `otel_riverpod`         | `riverpod`         | `ProviderContainer(observers: [OTelRiverpodObserver()])` |
| `otel_flutter_riverpod` | `flutter_riverpod` | `OTelProviderScope(child: ...)`                          |
| `otel_provider`         | `provider`         | `with OTelChangeNotifierMixin` on a `ChangeNotifier`     |
| `otel_mobx`             | `mobx`             | Spy and action tracing                                   |
| `otel_redux`            | `redux`            | Middleware                                               |
| `otel_get_it`           | `get_it`           | `getIt.tracedAllReady()`                                 |
| `otel_command_it`       | `command_it`       | `cmd.runTraced(...)`                                     |
| `otel_watch_it`         | `watch_it`         | `callOnceTraced`, `pushScopeTraced`                      |

State values are off by default (`recordStateValues`, `recordValues`).
Keep them off unless the state holds nothing personal.

## Logging

| Package              | Instruments     | Setup                            |
|----------------------|-----------------|----------------------------------|
| `otel_logging`       | `logging`       | `PackageLoggingBridge.install()` |
| `otel_logger`        | `logger`        | `OTelLogOutput` as the output    |
| `otel_talker`        | `talker`        | `OTelTalkerObserver`             |
| `otel_loggy`         | `loggy`         | `OTelLoggyPrinter`               |
| `otel_fimber`        | `fimber`        | Plant `OTelFimberTree`           |
| `otel_simple_logger` | `simple_logger` | Log bridge                       |

## Storage and databases

| Package                       | Instruments              | Setup                                              |
|-------------------------------|--------------------------|----------------------------------------------------|
| `otel_shared_preferences`     | `shared_preferences`     | `prefs.tracedSetString(...)` and the others        |
| `otel_flutter_secure_storage` | `flutter_secure_storage` | `storage.tracedRead(...)`                          |
| `otel_hive`                   | `hive`                   | `box.tracedPut(...)`                               |
| `otel_get_storage`            | `get_storage`            | `box.writeTraced(...)`                             |
| `otel_sqflite`                | `sqflite`                | `db.tracedQuery(...)`                              |
| `otel_drift`                  | `drift`                  | `OTelDriftInterceptor`                             |
| `otel_isar`                   | `isar`                   | `tracedIsarCall(operation:, collection:, invoke:)` |
| `otel_postgres`               | `postgres`               | `session.executeTraced(...)`                       |
| `otel_mysql`                  | `mysql_client`           | `conn.executeTraced(...)`                          |
| `otel_mongodb`                | `mongo_dart`             | `coll.findOneTraced(...)`                          |
| `otel_redis`                  | `redis`                  | `cmd.sendObjectTraced(...)`                        |

## Servers and messaging

| Package            | Instruments   | Setup                                                     |
|--------------------|---------------|-----------------------------------------------------------|
| `otel_serverpod`   | `serverpod`   | `OtelServerpod.install(pod)` and its database interceptor |
| `otel_amqp`        | `dart_amqp`   | `exchange.publishTraced(...)`                             |
| `otel_mqtt_client` | `mqtt_client` | `client.tracedConnect(...)`                               |

For shelf and dart_frog, use the middleware in
`dartastic-distributed-tracing`'s `references/dart-servers.md`.

## Device and platform

| Package                            | Instruments                   | Setup                                         |
|------------------------------------|-------------------------------|-----------------------------------------------|
| `otel_flutter_local_notifications` | `flutter_local_notifications` | Traced wrappers, `recordNotificationResponse` |
| `otel_google_sign_in`              | `google_sign_in`              | `gsi.tracedAuthenticate()`                    |
| `otel_workmanager`                 | `workmanager`                 | Wrap the task body                            |

Every package also offers a way to suppress its own instrumentation for a
block of code (`runWithout...Instrumentation`), for calls that should not
be traced.
