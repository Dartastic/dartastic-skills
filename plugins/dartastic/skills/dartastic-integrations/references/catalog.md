# otel_* packages

651 packages instrument the libraries and services Flutter and Dart
apps use. All are open source on pub.dev, depend only on the OpenTelemetry
API, and report through DOTel once `DOTel.initialize` has run, with no
other setup.

Find a package by searching this file for the library or service name. Add
it with `flutter pub add otel_<name>` (or `dart pub add`), then read its
README for the version you got. If pub cannot find it, it is not released
yet: wrap the call by hand as `SKILL.md` describes under "Libraries without
a package".

They come in two shapes:

- **Hooks** for a Dart library the app already uses: an interceptor,
  observer, client wrapper or extension method, set up once where the
  library is created (most of the first sections).
- **Call helpers** for a service: `tracedX(..., invoke: () => ...)` wraps
  the app's own call (through the vendor's SDK or its REST API) in a
  `CLIENT` span with that service's attributes. They don't depend on the
  vendor's SDK, so they work however the app calls it. The README shows
  what `invoke` returns.

Every package can also switch itself off for a block of code
(`runWithout...Instrumentation`), for calls that should not be traced.

## Contents

- [HTTP, APIs and networking](#http-apis-and-networking) (16)
- [Navigation](#navigation) (2)
- [Firebase and Google Cloud](#firebase-and-google-cloud) (28)
- [State management and app structure](#state-management-and-app-structure) (11)
- [Logging](#logging) (6)
- [Local storage](#local-storage) (3)
- [Databases, caches and search](#databases-caches-and-search) (46)
- [Servers and compute](#servers-and-compute) (2)
- [Messaging, queues, jobs and webhooks](#messaging-queues-jobs-and-webhooks) (26)
- [AI, LLMs, speech and documents](#ai-llms-speech-and-documents) (81)
- [Payments, finance and commerce](#payments-finance-and-commerce) (80)
- [Auth and identity](#auth-and-identity) (22)
- [Analytics, attribution, ads, feature flags and monitoring](#analytics-attribution-ads-feature-flags-and-monitoring) (42)
- [Email, SMS, push, chat and calls](#email-sms-push-chat-and-calls) (54)
- [Media, maps and device](#media-maps-and-device) (13)
- [AWS](#aws) (45)
- [Azure and Microsoft](#azure-and-microsoft) (22)
- [Infrastructure, DevOps and security](#infrastructure-devops-and-security) (54)
- [Data pipelines and automation](#data-pipelines-and-automation) (12)
- [Business and productivity services](#business-and-productivity-services) (86)

## HTTP, APIs and networking

| Package                   | Instruments                                                                       | Entry point                                                                                           |
|---------------------------|-----------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------|
| `otel_chopper`            | `chopper`                                                                         | `ChopperClient(interceptors: [OTelChopperInterceptor()])`                                             |
| `otel_connectivity_plus`  | `connectivity_plus`                                                               | `tracedCheckConnectivity()`, `listenConnectivityTraced()`                                             |
| `otel_dio`                | `dio`                                                                             | `dio.interceptors.insert(0, OTelDioInterceptor())`                                                    |
| `otel_envoy`              | Envoy (service proxy)                                                             | `tracedEnvoy(operation:, invoke:)`                                                                    |
| `otel_fastly`             | Fastly Compute@Edge backends and cache operations                                 | `tracedFastlyBackend(backend:, url:, invoke:)`, `tracedFastlyCacheLookup(store:, cacheKey:, invoke:)` |
| `otel_finch`              | Finch (unified HRIS/payroll API across 200+ providers)                            | `tracedFinch(operation:, invoke:)`                                                                    |
| `otel_graphql`            | `gql` links                                                                       | `OTelGraphqlLink` in the link chain                                                                   |
| `otel_graphql_flutter`    | `graphql_flutter`                                                                 | As `otel_graphql`                                                                                     |
| `otel_grpc`               | `grpc`                                                                            | `OTelGrpcClientInterceptor`, `OTelGrpcServerInterceptor`                                              |
| `otel_http`               | `http`                                                                            | `OTelHttpClient(http.Client())`                                                                       |
| `otel_ipdata`             | Ipdata (IP geolocation and threat intel: known abuser, attack source, bogon, Tor) | `tracedIpdata(operation:, invoke:)`                                                                   |
| `otel_ipinfo`             | IPinfo (ASN, geolocation, privacy detection, hosted domains, abuse contact)       | `tracedIpinfo(operation:, invoke:)`                                                                   |
| `otel_socket_io_client`   | `socket_io_client`                                                                | `tracedSocketHandler(...)`                                                                            |
| `otel_url_launcher`       | `url_launcher`                                                                    | `tracedLaunchUrl(uri)`                                                                                |
| `otel_web_socket_channel` | `web_socket_channel`                                                              | `OTelWebSocketChannel(...)`                                                                           |
| `otel_websocket`          | Outbound WebSocket connections and frames                                         | `tracedWebsocketConnect(url:, invoke:)`, `tracedWebsocketSend(destinationName:, invoke:)`             |

## Navigation

| Package           | Instruments  | Entry point                                                               |
|-------------------|--------------|---------------------------------------------------------------------------|
| `otel_auto_route` | `auto_route` | `config(navigatorObservers: () => [OTelAutoRouterObserver()])`            |
| `otel_go_router`  | `go_router`  | `GoRouter(observers: [OTelGoRouterObserver()])`, and on each `ShellRoute` |

These add route-change spans. Screen views and screen timing come from
`DartasticViewObserver`, which is still required.

## Firebase and Google Cloud

| Package                          | Instruments                                                                               | Entry point                                                                                                       |
|----------------------------------|-------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|
| `otel_bigquery`                  | Google BigQuery SQL and jobs                                                              | `tracedBigqueryQuery(statement:, project:, invoke:)`                                                              |
| `otel_cloud_firestore`           | `cloud_firestore`                                                                         | `doc.tracedGet()`, `tracedSet`, `tracedFirestoreTransaction`                                                      |
| `otel_cloud_functions`           | `cloud_functions`                                                                         | `tracedHttpsCall(callable, name:, parameters:)`                                                                   |
| `otel_crashlytics`               | Firebase Crashlytics (records, fatal/non-fatal, custom keys, logs)                        | `tracedCrashlytics(operation:, invoke:)`                                                                          |
| `otel_firebase_analytics`        | `firebase_analytics`                                                                      | `analytics.tracedLogEvent(...)`                                                                                   |
| `otel_firebase_app_check`        | Firebase App Check (providers, attestation, token validation)                             | `tracedFirebaseAppCheck(operation:, invoke:)`                                                                     |
| `otel_firebase_auth`             | `firebase_auth`                                                                           | `auth.tracedSignInWithEmailAndPassword(...)` and the others                                                       |
| `otel_firebase_functions`        | Firebase Cloud Functions (callable client)                                                | `tracedFirebaseFunctions(operation:, invoke:)`                                                                    |
| `otel_firebase_hosting`          | Firebase Hosting (static and dynamic site hosting)                                        | `tracedFirebaseHosting(operation:, invoke:)`                                                                      |
| `otel_firebase_in_app_messaging` | Firebase In-App Messaging (campaigns, impressions, clicks, dismisses)                     | `tracedFirebaseInAppMessaging(operation:, invoke:)`                                                               |
| `otel_firebase_performance`      | Firebase Performance Monitoring (http metrics, custom traces, screens)                    | `tracedFirebasePerformance(operation:, invoke:)`                                                                  |
| `otel_firestore`                 | Google Cloud Firestore (CRUD, queries, transactions)                                      | `tracedFirestoreDoc(operation:, collection:, documentId:, invoke:)`, `tracedFirestoreQuery(collection:, invoke:)` |
| `otel_gcp_artifact_registry`     | GCP Artifact Registry (containers and packages)                                           | `tracedGcpArtifactRegistry(operation:, invoke:)`                                                                  |
| `otel_gcp_bigquery`              | GCP BigQuery (serverless data warehouse)                                                  | `tracedGcpBigQuery(operation:, invoke:)`                                                                          |
| `otel_gcp_bigtable`              | GCP Bigtable (wide-column NoSQL)                                                          | `tracedGcpBigtable(operation:, invoke:)`                                                                          |
| `otel_gcp_cloud_functions`       | GCP Cloud Functions (Gen 2)                                                               | `tracedGcpCloudFunctions(operation:, invoke:)`                                                                    |
| `otel_gcp_cloud_run`             | GCP Cloud Run (serverless containers)                                                     | `tracedGcpCloudRun(operation:, invoke:)`                                                                          |
| `otel_gcp_cloud_sql`             | GCP Cloud SQL (Postgres / MySQL / SQL Server)                                             | `tracedGcpCloudSql(operation:, invoke:)`                                                                          |
| `otel_gcp_cloud_storage`         | Google Cloud Storage (GCS)                                                                | `tracedGcpCloudStorage(operation:, invoke:)`                                                                      |
| `otel_gcp_compute_engine`        | GCP Compute Engine (VMs)                                                                  | `tracedGcpComputeEngine(operation:, invoke:)`                                                                     |
| `otel_gcp_firestore`             | GCP Firestore (managed NoSQL document DB)                                                 | `tracedGcpFirestore(operation:, invoke:)`                                                                         |
| `otel_gcp_gke`                   | GCP GKE (managed Kubernetes)                                                              | `tracedGcpGKE(operation:, invoke:)`                                                                               |
| `otel_gcp_pubsub`                | GCP Pub/Sub (publish, receive, ack)                                                       | `tracedGcpPubsubPublish(project:, topic:, invoke:)`, `tracedGcpPubsubReceive(project:, subscription:, invoke:)`   |
| `otel_gcp_secret_manager`        | GCP Secret Manager                                                                        | `tracedGcpSecretManager(operation:, invoke:)`                                                                     |
| `otel_gcp_spanner`               | GCP Cloud Spanner (globally distributed SQL)                                              | `tracedGcpSpanner(operation:, invoke:)`                                                                           |
| `otel_google_fonts`              | Google Fonts (web font CDN)                                                               | `tracedGoogleFonts(operation:, invoke:)`                                                                          |
| `otel_google_mobile_ads`         | Google Mobile Ads / AdMob (publisher side: banner, interstitial, rewarded, native, app... | `tracedGoogleMobileAds(operation:, invoke:)`                                                                      |
| `otel_google_sign_in`            | `google_sign_in`                                                                          | `gsi.tracedAuthenticate()`                                                                                        |

`otel_firebase_auth` records `enduser.id` unless `recordUserId: false`.

## State management and app structure

| Package                 | Instruments        | Entry point                                              |
|-------------------------|--------------------|----------------------------------------------------------|
| `otel_bloc`             | `bloc`             | `Bloc.observer = OTelBlocObserver()`                     |
| `otel_command_it`       | `command_it`       | `cmd.runTraced(...)`                                     |
| `otel_flutter_bloc`     | `flutter_bloc`     | As `otel_bloc`                                           |
| `otel_flutter_command`  | `flutter_command`  | `OTelCommand` around a command                           |
| `otel_flutter_riverpod` | `flutter_riverpod` | `OTelProviderScope(child: ...)`                          |
| `otel_get_it`           | `get_it`           | `getIt.tracedAllReady()`                                 |
| `otel_mobx`             | `mobx`             | Spy and action tracing                                   |
| `otel_provider`         | `provider`         | `with OTelChangeNotifierMixin` on a `ChangeNotifier`     |
| `otel_redux`            | `redux`            | Middleware                                               |
| `otel_riverpod`         | `riverpod`         | `ProviderContainer(observers: [OTelRiverpodObserver()])` |
| `otel_watch_it`         | `watch_it`         | `callOnceTraced`, `pushScopeTraced`                      |

State values are off by default (`recordStateValues`, `recordValues`).
Keep them off unless the state holds nothing personal.

## Logging

| Package              | Instruments     | Entry point                      |
|----------------------|-----------------|----------------------------------|
| `otel_fimber`        | `fimber`        | Plant `OTelFimberTree`           |
| `otel_logger`        | `logger`        | `OTelLogOutput` as the output    |
| `otel_logging`       | `logging`       | `PackageLoggingBridge.install()` |
| `otel_loggy`         | `loggy`         | `OTelLoggyPrinter`               |
| `otel_simple_logger` | `simple_logger` | Log bridge                       |
| `otel_talker`        | `talker`        | `OTelTalkerObserver`             |

## Local storage

| Package                       | Instruments              | Entry point                                 |
|-------------------------------|--------------------------|---------------------------------------------|
| `otel_flutter_secure_storage` | `flutter_secure_storage` | `storage.tracedRead(...)`                   |
| `otel_get_storage`            | `get_storage`            | `box.writeTraced(...)`                      |
| `otel_shared_preferences`     | `shared_preferences`     | `prefs.tracedSetString(...)` and the others |

## Databases, caches and search

| Package                 | Instruments                                                                              | Entry point                                                                                                          |
|-------------------------|------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------|
| `otel_aerospike`        | Aerospike real-time NoSQL (key-value, batch, secondary index)                            | `tracedAerospike(operation:, invoke:)`                                                                               |
| `otel_algolia`          | Algolia search (search, index, browse)                                                   | `tracedAlgoliaSearch(indexName:, query:, invoke:)`, `tracedAlgoliaIndexOp(operation:, indexName:, invoke:)`          |
| `otel_appwrite`         | Appwrite BaaS calls                                                                      | `tracedAppwriteAccount(operation:, invoke:)`, `tracedAppwriteDb(databaseId:, collectionId:, operation:, invoke:)`    |
| `otel_arangodb`         | ArangoDB multi-model database (AQL, graph, document, KV)                                 | `tracedArangodb(operation:, invoke:)`                                                                                |
| `otel_cassandra`        | Apache Cassandra (CQL native protocol)                                                   | `tracedCassandra(operation:, statementSummary:, invoke:)`                                                            |
| `otel_clickhouse`       | ClickHouse OLAP (HTTP, native TCP, gRPC)                                                 | `tracedClickhouse(invoke:, statementSummary:)`                                                                       |
| `otel_clickhouse_cloud` | ClickHouse Cloud (analytical DB)                                                         | `tracedClickhouseCloud(operation:, invoke:)`                                                                         |
| `otel_cloudflare_d1`    | Cloudflare D1 (SQLite at the edge)                                                       | `tracedCloudflareD1(operation:, invoke:)`                                                                            |
| `otel_cockroachdb`      | CockroachDB (distributed SQL)                                                            | `tracedCockroachDB(operation:, invoke:)`                                                                             |
| `otel_couchbase`        | Couchbase Capella (KV and N1QL/SQL++)                                                    | `tracedCouchbaseKv(operation:, bucket:, docId:, invoke:)`, `tracedCouchbaseQuery(statement:, invoke:)`               |
| `otel_couchdb`          | CouchDB (document database)                                                              | `tracedCouchDB(operation:, invoke:)`                                                                                 |
| `otel_databricks`       | Databricks SQL and Jobs API                                                              | `tracedDatabricksSql(statement:, invoke:)`, `tracedDatabricksJob(action:, invoke:)`                                  |
| `otel_dragonfly`        | Dragonfly (Redis and Memcached compatible, multi-threaded)                               | `tracedDragonfly(command:, invoke:)`                                                                                 |
| `otel_drift`            | `drift`                                                                                  | `OTelDriftInterceptor`                                                                                               |
| `otel_duckdb`           | DuckDB (embedded analytics DB)                                                           | `tracedDuckDB(operation:, invoke:)`                                                                                  |
| `otel_elasticsearch`    | Elasticsearch (search, index, bulk)                                                      | `tracedElasticsearchSearch(index:, invoke:)`, `tracedElasticsearchBulk(index:, invoke:)`                             |
| `otel_etcd`             | Etcd distributed KV (v3 gRPC API, leases, watches, txns)                                 | `tracedEtcd(operation:, invoke:)`                                                                                    |
| `otel_fauna`            | Fauna distributed document database (FQL v10 and v4)                                     | `tracedFaunaQuery(invoke:)`                                                                                          |
| `otel_glean`            | Glean enterprise AI search (search, chat, datasources, citations)                        | `tracedGlean(operation:, invoke:)`                                                                                   |
| `otel_hive`             | `hive`                                                                                   | `box.tracedPut(...)`                                                                                                 |
| `otel_influxdb`         | InfluxDB time-series (v2 and v3 IOx, Flux, InfluxQL)                                     | `tracedInfluxdb(operation:, invoke:)`                                                                                |
| `otel_isar`             | `isar`                                                                                   | `tracedIsarCall(operation:, collection:, invoke:)`                                                                   |
| `otel_meilisearch`      | Meilisearch (search, index management)                                                   | `tracedMeilisearchSearch(index:, query:, invoke:)`, `tracedMeilisearchIndexOp(operation:, index:, invoke:)`          |
| `otel_memcached`        | Memcached (binary and text protocol)                                                     | `tracedMemcached(command:, invoke:)`                                                                                 |
| `otel_mongodb`          | `mongo_dart`                                                                             | `coll.findOneTraced(...)`                                                                                            |
| `otel_mongodb_atlas`    | MongoDB Atlas Data API and Search                                                        | `tracedMongodbAtlasDataApi(action:, collection:, invoke:)`, `tracedMongodbAtlasSearch(index:, collection:, invoke:)` |
| `otel_mysql`            | `mysql_client`                                                                           | `conn.executeTraced(...)`                                                                                            |
| `otel_neo4j`            | Neo4j graph database (Cypher, Bolt protocol)                                             | `tracedNeo4j(operation:, cypherSummary:, invoke:)`                                                                   |
| `otel_neon`             | Neon (serverless Postgres) queries                                                       | `tracedNeonQuery(statement:, database:, invoke:)`                                                                    |
| `otel_opensearch`       | AWS OpenSearch / OpenSearch Project                                                      | `tracedOpensearchSearch(index:, invoke:)`                                                                            |
| `otel_planetscale`      | PlanetScale (serverless MySQL) queries                                                   | `tracedPlanetscaleQuery(statement:, database:, invoke:)`                                                             |
| `otel_postgres`         | `postgres`                                                                               | `session.executeTraced(...)`                                                                                         |
| `otel_questdb`          | QuestDB high-perf time-series (InfluxDB Line Protocol and PostgreSQL wire and REST)      | `tracedQuestdb(operation:, invoke:)`                                                                                 |
| `otel_redis`            | `redis`                                                                                  | `cmd.sendObjectTraced(...)`                                                                                          |
| `otel_scylladb`         | ScyllaDB (Cassandra-compatible wide-column NoSQL)                                        | `tracedScyllaDB(operation:, invoke:)`                                                                                |
| `otel_snowflake`        | Snowflake SQL queries (REST and connector)                                               | `tracedSnowflakeQuery(statement:, invoke:)`                                                                          |
| `otel_sqflite`          | `sqflite`                                                                                | `db.tracedQuery(...)`                                                                                                |
| `otel_supabase`         | `supabase_flutter`: auth, postgrest, storage, edge functions as CLIENT spans             | `tracedSupabaseAuth(operation:, invoke:)`, `tracedSupabaseDb(table:, operation:, invoke:)`                           |
| `otel_surrealdb`        | SurrealDB multi-model database (SurrealQL)                                               | `tracedSurrealdb(invoke:)`                                                                                           |
| `otel_tidb`             | TiDB (distributed HTAP SQL)                                                              | `tracedTiDB(operation:, invoke:)`                                                                                    |
| `otel_timescaledb`      | TimescaleDB time-series (PostgreSQL extension and hypertables and continuous aggregates) | `tracedTimescaledb(operation:, statementSummary:, invoke:)`                                                          |
| `otel_turso`            | Turso / libSQL (SQLite on the edge)                                                      | `tracedTursoQuery(statement:, invoke:)`                                                                              |
| `otel_typesense`        | Typesense search                                                                         | `tracedTypesenseSearch(collection:, query:, invoke:)`, `tracedTypesenseIndexOp(operation:, collection:, invoke:)`    |
| `otel_upstash`          | Upstash Redis, Kafka, and QStash REST APIs                                               | `tracedUpstashRedis(command:, invoke:)`, `tracedUpstashQstashPublish(destination:, invoke:)`                         |
| `otel_xata`             | Xata serverless database                                                                 | `tracedXataQuery(operation:, tableName:, invoke:)`                                                                   |
| `otel_yugabytedb`       | YugabyteDB (distributed SQL)                                                             | `tracedYugabyteDB(operation:, invoke:)`                                                                              |

## Servers and compute

| Package          | Instruments | Entry point                                               |
|------------------|-------------|-----------------------------------------------------------|
| `otel_serverpod` | `serverpod` | `OtelServerpod.install(pod)` and its database interceptor |
| `otel_shelf`     | `shelf`     | Use the middleware in `dartastic-distributed-tracing`     |

For shelf and dart_frog, use the middleware in
`dartastic-distributed-tracing`'s `references/dart-servers.md`.

## Messaging, queues, jobs and webhooks

| Package                | Instruments                                                                  | Entry point                                                                                                                              |
|------------------------|------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------|
| `otel_ably`            | Ably realtime (publish, subscribe, presence)                                 | `tracedAblyPublish(channel:, event:, invoke:)`, `tracedAblyAttach(channel:, invoke:)`                                                    |
| `otel_amqp`            | `dart_amqp`                                                                  | `exchange.publishTraced(...)`                                                                                                            |
| `otel_bullmq`          | BullMQ (Node.js Redis-backed queue)                                          | `tracedBullMQ(operation:, invoke:)`                                                                                                      |
| `otel_celery`          | Celery (Python distributed task queue)                                       | `tracedCelery(operation:, invoke:)`                                                                                                      |
| `otel_confluent_cloud` | Confluent Cloud (managed Kafka)                                              | `tracedConfluentCloud(operation:, invoke:)`                                                                                              |
| `otel_convoy`          | Convoy OSS webhook gateway (projects, endpoints, events, retries)            | `tracedConvoy(operation:, invoke:)`                                                                                                      |
| `otel_defer`           | Defer.run background jobs (executions, queues, attempts, concurrency)        | `tracedDefer(operation:, invoke:)`                                                                                                       |
| `otel_hatchet`         | Hatchet distributed task queue (workflows, steps, workers, tenants)          | `tracedHatchet(operation:, invoke:)`                                                                                                     |
| `otel_hookdeck`        | Hookdeck webhook gateway (routes, sources, destinations, attempts, retries)  | `tracedHookdeck(operation:, invoke:)`                                                                                                    |
| `otel_inngest`         | Inngest event-driven workflows and durable functions                         | `tracedInngestSend(eventName:, invoke:)`                                                                                                 |
| `otel_kafka`           | Apache Kafka (produce, consume)                                              | `tracedKafkaProduce(topic:, invoke:)`, `tracedKafkaConsume(topic:, consumerGroup:, invoke:)`                                             |
| `otel_mqtt_client`     | `mqtt_client`                                                                | `client.tracedConnect(...)`                                                                                                              |
| `otel_nats`            | NATS (publish, subscribe, request/reply, JetStream)                          | `tracedNatsPublish(subject:, invoke:)`, `tracedNatsConsume(subject:, invoke:)`                                                           |
| `otel_pubnub`          | PubNub messaging (publish, subscribe)                                        | `tracedPubnubPublish(channel:, invoke:)`, `tracedPubnubSubscribe(channel:, invoke:)`                                                     |
| `otel_pusher`          | Pusher Channels (WebSocket-as-a-service)                                     | `tracedPusher(operation:, invoke:)`                                                                                                      |
| `otel_pusher_channels` | Pusher Channels (publish, subscribe, presence)                               | `tracedPusherChannelsPublish(channel:, event:, invoke:)`, `tracedPusherChannelsSubscribe(channel:, invoke:)`                             |
| `otel_quirrel`         | Quirrel job queue (jobs, queues, attempts, cron)                             | `tracedQuirrel(operation:, invoke:)`                                                                                                     |
| `otel_rabbitmq`        | RabbitMQ (publish, consume, ack)                                             | `tracedRabbitmqPublish(exchange:, routingKey:, invoke:)`, `tracedRabbitmqConsume(queue:, invoke:)`                                       |
| `otel_redpanda`        | Redpanda (Kafka-compatible streaming)                                        | `tracedRedpanda(operation:, invoke:)`                                                                                                    |
| `otel_restate`         | Restate durable execution (invocations, services, handlers, journal entries) | `tracedRestate(operation:, invoke:)`                                                                                                     |
| `otel_sidekiq`         | Sidekiq (Ruby background jobs)                                               | `tracedSidekiq(operation:, invoke:)`                                                                                                     |
| `otel_svix`            | Svix webhook delivery (applications, endpoints, message events, attempts)    | `tracedSvix(operation:, invoke:)`                                                                                                        |
| `otel_temporal`        | Temporal workflows (start/signal/query)                                      | `tracedTemporalStartWorkflow(workflowType:, workflowId:, taskQueue:, invoke:)`, `tracedTemporalSignal(operation:, workflowId:, invoke:)` |
| `otel_temporal_cloud`  | Temporal Cloud (durable execution)                                           | `tracedTemporalCloud(operation:, invoke:)`                                                                                               |
| `otel_trigger_dev`     | Trigger.dev background jobs and tasks (v3)                                   | `tracedTriggerDevEnqueue(taskId:, invoke:)`                                                                                              |
| `otel_webhook`         | Generic outbound webhook POSTs                                               | `tracedWebhookPost(url:, invoke:)`                                                                                                       |

## AI, LLMs, speech and documents

| Package                       | Instruments                                                                                | Entry point                                                                                            |
|-------------------------------|--------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| `otel_anthropic`              | `anthropic_sdk_dart`                                                                       | `tracedAnthropicMessage(request:, invoke:)`                                                            |
| `otel_anyscale`               | Anyscale (managed Ray jobs and services and endpoints)                                     | `tracedAnyscale(operation:, invoke:)`                                                                  |
| `otel_arize`                  | Arize AI (ML and LLM observability)                                                        | `tracedArize(operation:, invoke:)`                                                                     |
| `otel_assemblyai`             | AssemblyAI speech-to-text and LeMUR LLM                                                    | `tracedAssemblyaiTranscribe(invoke:)`, `tracedAssemblyaiLemur(finalModel:, invoke:)`                   |
| `otel_autogen`                | Microsoft AutoGen (multi-agent)                                                            | `tracedAutoGen(operation:, invoke:)`                                                                   |
| `otel_aws_bedrock`            | AWS Bedrock Converse                                                                       | `tracedBedrockConverse(modelId:, invoke:)`                                                             |
| `otel_azure_openai`           | Azure OpenAI                                                                               | `tracedAzureOpenAiChat(deploymentName:, invoke:)`                                                      |
| `otel_baseten`                | Baseten model serving (Truss and dedicated deployments)                                    | `tracedBaseten(modelId:, invoke:)`                                                                     |
| `otel_bland_ai`               | Bland.ai voice agents (calls, pathways, voices, transfer)                                  | `tracedBlandAi(operation:, invoke:)`                                                                   |
| `otel_braintrust`             | Braintrust (LLM eval and observability)                                                    | `tracedBraintrust(operation:, invoke:)`                                                                |
| `otel_cartesia`               | Cartesia Sonic ultra-low-latency text-to-speech                                            | `tracedCartesiaTts(voiceId:, modelId:, invoke:)`                                                       |
| `otel_chroma`                 | Chroma vector database                                                                     | `tracedChromaQuery(collection:, invoke:)`, `tracedChromaUpsert(operation:, collection:, invoke:)`      |
| `otel_cloudflare_ai`          | Cloudflare Workers AI inference and AI Gateway                                             | `tracedCloudflareAi(model:, invoke:)`                                                                  |
| `otel_cohere`                 | Cohere chat / generate                                                                     | `tracedCohereChat(modelName:, invoke:)`, `tracedCohereRerank(modelName:, invoke:)`                     |
| `otel_crewai`                 | CrewAI multi-agent framework (crews, agents, tasks, tools)                                 | `tracedCrewai(operation:, invoke:)`                                                                    |
| `otel_deepgram`               | Deepgram speech-to-text (pre-recorded and streaming)                                       | `tracedDeepgramTranscribe(model:, invoke:)`                                                            |
| `otel_deepl`                  | DeepL translation and document translation                                                 | `tracedDeeplTranslate(targetLang:, invoke:)`                                                           |
| `otel_deepseek`               | DeepSeek LLM chat and code completions                                                     | `tracedDeepseek(model:, invoke:)`                                                                      |
| `otel_elevenlabs`             | ElevenLabs text-to-speech and voice cloning                                                | `tracedElevenlabsTts(voiceId:, modelId:, invoke:)`                                                     |
| `otel_exa`                    | Exa neural search (formerly Metaphor)                                                      | `tracedExa(operation:, invoke:)`                                                                       |
| `otel_fal_ai`                 | Fal.ai serverless inference (image, video, audio, LLM models)                              | `tracedFalAi(endpoint:, invoke:)`                                                                      |
| `otel_firecrawl`              | Firecrawl (web scraping for LLMs)                                                          | `tracedFirecrawl(operation:, invoke:)`                                                                 |
| `otel_fireworks_ai`           | Fireworks AI LLM and embedding inference                                                   | `tracedFireworksAi(model:, invoke:)`                                                                   |
| `otel_google_ai`              | `google_generative_ai` (Gemini)                                                            | `tracedGenerateContent(model:, modelName:, prompt:)`, `tracedGenerateContentCall(modelName:, invoke:)` |
| `otel_google_translate`       | Google Cloud Translation API (Basic and Advanced)                                          | `tracedGoogleTranslate(targetLang:, invoke:)`                                                          |
| `otel_groq`                   | Groq chat / completions                                                                    | `tracedGroqChat(modelName:, invoke:)`                                                                  |
| `otel_haystack`               | Haystack (deepset LLM pipelines)                                                           | `tracedHaystack(operation:, invoke:)`                                                                  |
| `otel_helicone`               | Helicone (LLM proxy and observability)                                                     | `tracedHelicone(operation:, invoke:)`                                                                  |
| `otel_heygen`                 | HeyGen AI avatar video generation, talking photo, translate video, streaming avatars       | `tracedHeygen(model:, operation:, invoke:)`                                                            |
| `otel_huggingface`            | Hugging Face Inference API                                                                 | `tracedHuggingface(model:, task:, invoke:)`                                                            |
| `otel_ideogram`               | Ideogram image generation with high-fidelity typography                                    | `tracedIdeogram(model:, operation:, invoke:)`                                                          |
| `otel_jina_ai`                | Jina AI embeddings, rerank, reader, and segmenter APIs                                     | `tracedJinaEmbeddings(model:, invoke:)`, `tracedJinaRerank(model:, invoke:)`                           |
| `otel_lancedb`                | LanceDB embedded vector database                                                           | `tracedLancedbSearch(table:, invoke:)`, `tracedLancedbWrite(operation:, table:, invoke:)`              |
| `otel_langchain`              | Langchain                                                                                  | `tracedRunnableInvoke(runnable:, input:, invoke:)`, `tracedSequenceInvoke(sequence:, input:)`          |
| `otel_langfuse`               | Langfuse (LLM observability)                                                               | `tracedLangfuse(operation:, invoke:)`                                                                  |
| `otel_langgraph`              | LangGraph agent graphs (nodes, edges, state, checkpoints)                                  | `tracedLanggraph(operation:, invoke:)`                                                                 |
| `otel_leonardo_ai`            | Leonardo.AI image generation and 3D texture APIs                                           | `tracedLeonardoAi(modelId:, invoke:)`                                                                  |
| `otel_llamaindex`             | LlamaIndex (RAG framework)                                                                 | `tracedLlamaIndex(operation:, invoke:)`                                                                |
| `otel_llamaparse`             | LlamaParse (LLM-native PDF and doc parsing)                                                | `tracedLlamaParse(operation:, invoke:)`                                                                |
| `otel_lmnt`                   | LMNT ultra-low-latency TTS streaming and voice cloning                                     | `tracedLmnt(voiceId:, modelId:, invoke:)`                                                              |
| `otel_luma`                   | Luma Labs Dream Machine video generation and Photon image                                  | `tracedLuma(model:, invoke:)`                                                                          |
| `otel_mendable`               | Mendable AI docs assistant (chat, search, conversations, sources)                          | `tracedMendable(operation:, invoke:)`                                                                  |
| `otel_milvus`                 | Milvus / Zilliz Cloud vector database                                                      | `tracedMilvusSearch(collection:, invoke:)`, `tracedMilvusInsert(operation:, collection:, invoke:)`     |
| `otel_mindee`                 | Mindee document AI (predictions, products, pages, confidence)                              | `tracedMindee(operation:, invoke:)`                                                                    |
| `otel_mistral`                | Mistral AI chat                                                                            | `tracedMistralChat(modelName:, invoke:)`                                                               |
| `otel_mlkit_barcode_scanning` | Google ML Kit Barcode Scanning                                                             | `tracedMlkitBarcodeScanning(operation:, invoke:)`                                                      |
| `otel_mlkit_face_detection`   | Google ML Kit Face Detection                                                               | `tracedMlkitFaceDetection(operation:, invoke:)`                                                        |
| `otel_mlkit_text_recognition` | Google ML Kit Text Recognition (OCR)                                                       | `tracedMlkitTextRecognition(operation:, invoke:)`                                                      |
| `otel_modal`                  | Modal serverless GPU functions                                                             | `tracedModalCall(appName:, functionName:, invoke:)`                                                    |
| `otel_nanonets`               | Nanonets (OCR and document AI)                                                             | `tracedNanonets(operation:, invoke:)`                                                                  |
| `otel_octoai`                 | OctoAI (LLM and image and custom-endpoint inference)                                       | `tracedOctoAi(operation:, invoke:)`                                                                    |
| `otel_openai`                 | `openai_dart`                                                                              | `tracedOpenAiChat(request:, invoke:)`                                                                  |
| `otel_perplexity`             | Perplexity AI chat completions                                                             | `tracedPerplexity(model:, invoke:)`                                                                    |
| `otel_perplexity_sonar`       | Perplexity Sonar Search and Deep Research API (search, deep research, async jobs, sources) | `tracedPerplexitySonar(operation:, invoke:)`                                                           |
| `otel_perspective_api`        | Google Perspective API content moderation                                                  | `tracedPerspectiveAnalyze(invoke:)`                                                                    |
| `otel_pgvector`               | Postgres pgvector similarity queries                                                       | `tracedPgvectorSearch(table:, invoke:)`                                                                |
| `otel_pika`                   | Pika video generation (text-to-video, image-to-video, Pikaffects)                          | `tracedPika(model:, invoke:)`                                                                          |
| `otel_pinecone`               | Pinecone vector DB calls                                                                   | `tracedPineconeUpsert(indexName:, invoke:)`, `tracedPineconeQuery(indexName:, invoke:)`                |
| `otel_play_ht`                | Play.ht text-to-speech (Play3.0 streaming and voice cloning and agents)                    | `tracedPlayHt(voiceId:, modelId:, invoke:)`                                                            |
| `otel_qdrant`                 | Qdrant vector-DB calls                                                                     | `tracedQdrantUpsert(collectionName:, invoke:)`, `tracedQdrantSearch(collectionName:, invoke:)`         |
| `otel_recraft`                | Recraft AI vector and raster image generation                                              | `tracedRecraft(model:, operation:, invoke:)`                                                           |
| `otel_reducto`                | Reducto (LLM-native document parsing)                                                      | `tracedReducto(operation:, invoke:)`                                                                   |
| `otel_replicate`              | Replicate (run prediction-style model invocations)                                         | `tracedReplicateRun(modelVersion:, invoke:)`                                                           |
| `otel_retell_ai`              | Retell AI voice agents (calls, agents, llm websocket, transcript)                          | `tracedRetellAi(operation:, invoke:)`                                                                  |
| `otel_rev_ai`                 | Rev.ai speech-to-text (async and streaming and human-verified transcripts)                 | `tracedRevAi(operation:, invoke:)`                                                                     |
| `otel_runpod`                 | RunPod serverless GPU endpoints                                                            | `tracedRunpod(endpointId:, invoke:)`                                                                   |
| `otel_runway`                 | Runway video generation (Gen-3, Gen-3 Alpha Turbo, Act-One)                                | `tracedRunway(model:, invoke:)`                                                                        |
| `otel_speechmatics`           | Speechmatics enterprise ASR (batch and real-time and speaker ID, language ID)              | `tracedSpeechmatics(invoke:)`                                                                          |
| `otel_stability_ai`           | Stability AI image generation (Stable Diffusion, SDXL, Stable Image)                       | `tracedStabilityAi(model:, invoke:)`                                                                   |
| `otel_suno`                   | Suno music generation (Bark backend, custom songs, instrumentals, stems)                   | `tracedSuno(model:, invoke:)`                                                                          |
| `otel_synthesia`              | Synthesia corporate AI video generation                                                    | `tracedSynthesia(operation:, invoke:)`                                                                 |
| `otel_tavily`                 | Tavily AI search (LLM-optimized web search)                                                | `tracedTavily(operation:, invoke:)`                                                                    |
| `otel_together_ai`            | Together.ai LLM inference and embeddings                                                   | `tracedTogetherAi(model:, invoke:)`                                                                    |
| `otel_unstructured_io`        | Unstructured.io document parsing (partitions, elements, pages, strategies)                 | `tracedUnstructuredIo(operation:, invoke:)`                                                            |
| `otel_vapi`                   | Vapi AI voice agents (calls, assistants, minutes, transports)                              | `tracedVapi(operation:, invoke:)`                                                                      |
| `otel_vertex`                 | Vertex Cloud (sales tax, VAT, returns, certificates, exemptions for enterprise)            | `tracedVertex(operation:, invoke:)`                                                                    |
| `otel_vertex_ai`              | Google Vertex AI (chat / generate_content)                                                 | `tracedVertexAiChat(model:, invoke:)`                                                                  |
| `otel_voiceflow`              | Voiceflow conversational AI (interactions, projects, dialogs, knowledge bases)             | `tracedVoiceflow(operation:, invoke:)`                                                                 |
| `otel_voyage_ai`              | Voyage AI embeddings and rerank                                                            | `tracedVoyageEmbeddings(model:, invoke:)`, `tracedVoyageRerank(model:, invoke:)`                       |
| `otel_weaviate`               | Weaviate vector DB calls                                                                   | `tracedWeaviateInsert(className:, invoke:)`, `tracedWeaviateQuery(className:, invoke:)`                |
| `otel_writer`                 | Writer / Palmyra LLM chat and completions                                                  | `tracedWriterChat(model:, invoke:)`                                                                    |

## Payments, finance and commerce

| Package                | Instruments                                                                                 | Entry point                                                                                                     |
|------------------------|---------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------|
| `otel_adp`             | ADP (Workforce Now, RUN, DataConnect APIs: workers, payroll, time)                          | `tracedAdp(operation:, invoke:)`                                                                                |
| `otel_adyen`           | Adyen global enterprise payments, 3DS, marketplace splits, in-person                        | `tracedAdyen(operation:, invoke:)`                                                                              |
| `otel_alchemy`         | Alchemy (Ethereum and L2 RPC and NFT/Webhook APIs)                                          | `tracedAlchemy(operation:, invoke:)`                                                                            |
| `otel_alloy`           | Alloy identity decisioning (entities, evaluations, journeys, workflows)                     | `tracedAlloy(operation:, invoke:)`                                                                              |
| `otel_anrok`           | Anrok (SaaS-native sales tax: ephemeral and canonical transactions, registrations...        | `tracedAnrok(operation:, invoke:)`                                                                              |
| `otel_apphud`          | Apphud (IAP and paywall orchestrator)                                                       | `tracedApphud(operation:, invoke:)`                                                                             |
| `otel_avalara`         | Avalara AvaTax (transactions, customers, returns, exemption certificates, nexus, address... | `tracedAvalara(operation:, invoke:)`                                                                            |
| `otel_bigcommerce`     | BigCommerce v3 API                                                                          | `tracedBigcommerce(resource:, action:, storeHash:, invoke:)`                                                    |
| `otel_binance`         | Binance (crypto exchange)                                                                   | `tracedBinance(operation:, invoke:)`                                                                            |
| `otel_braintree`       | Braintree payments                                                                          | `tracedBraintree(operation:, invoke:)`                                                                          |
| `otel_brex`            | Brex (corporate cards and spend mgmt)                                                       | `tracedBrex(operation:, invoke:)`                                                                               |
| `otel_chargebee`       | Chargebee subscription billing                                                              | `tracedChargebee(resource:, action:, invoke:)`                                                                  |
| `otel_checkout_com`    | Checkout.com (global payments)                                                              | `tracedCheckoutCom(operation:, invoke:)`                                                                        |
| `otel_clover_pos`      | Clover POS (retail point-of-sale)                                                           | `tracedCloverPOS(operation:, invoke:)`                                                                          |
| `otel_coinbase`        | Coinbase (Advanced Trade and Commerce)                                                      | `tracedCoinbase(operation:, invoke:)`                                                                           |
| `otel_commercetools`   | Commercetools (composable commerce, GraphQL and REST, projects, carts, orders, inventory)   | `tracedCommercetools(operation:, invoke:)`                                                                      |
| `otel_firstpromoter`   | FirstPromoter (affiliate / referral)                                                        | `tracedFirstPromoter(operation:, invoke:)`                                                                      |
| `otel_freshbooks`      | FreshBooks (SMB invoicing and accounting)                                                   | `tracedFreshBooks(operation:, invoke:)`                                                                         |
| `otel_gocardless`      | GoCardless bank debit (SEPA and BACS and ACH and Autogiro and PAD)                          | `tracedGocardless(operation:, invoke:)`                                                                         |
| `otel_gusto`           | Gusto (payroll, employees, contractors, benefits, time tracking)                            | `tracedGusto(operation:, invoke:)`                                                                              |
| `otel_helius`          | Helius (Solana RPC and DAS and webhooks)                                                    | `tracedHelius(operation:, invoke:)`                                                                             |
| `otel_impact`          | Impact partnership platform (campaigns, actions, conversions, payouts)                      | `tracedImpact(operation:, invoke:)`                                                                             |
| `otel_in_app_purchase` | Apple StoreKit and Google Play Billing in-app purchases (products, purchases, restore...    | `tracedInAppPurchase(operation:, invoke:)`                                                                      |
| `otel_increase`        | Increase (banking-as-a-service)                                                             | `tracedIncrease(operation:, invoke:)`                                                                           |
| `otel_infura`          | Infura (Ethereum and L2 RPC, IPFS)                                                          | `tracedInfura(operation:, invoke:)`                                                                             |
| `otel_kraken`          | Kraken (crypto exchange)                                                                    | `tracedKraken(operation:, invoke:)`                                                                             |
| `otel_lago`            | Lago usage-based billing (events, customers, subscriptions, invoices)                       | `tracedLago(operation:, invoke:)`                                                                               |
| `otel_lemonsqueezy`    | Lemon Squeezy (Merchant of Record billing)                                                  | `tracedLemonsqueezy(resource:, action:, invoke:)`                                                               |
| `otel_lightspeed`      | Lightspeed (retail and restaurant POS)                                                      | `tracedLightspeed(operation:, invoke:)`                                                                         |
| `otel_lithic`          | Lithic (card issuing and KYC)                                                               | `tracedLithic(operation:, invoke:)`                                                                             |
| `otel_magento`         | Magento / Adobe Commerce (REST and GraphQL: products, orders, carts, customers, inventory)  | `tracedMagento(operation:, invoke:)`                                                                            |
| `otel_marqeta`         | Marqeta (modern card issuing)                                                               | `tracedMarqeta(operation:, invoke:)`                                                                            |
| `otel_medusa`          | Medusa (open-source headless commerce: admin, store, products, orders, carts, regions)      | `tracedMedusa(operation:, invoke:)`                                                                             |
| `otel_mercury`         | Mercury startup banking API (accounts, payments, treasury sweeps, statements)               | `tracedMercury(operation:, invoke:)`                                                                            |
| `otel_metronome`       | Metronome usage-based billing (events, billable metrics, contracts, invoices)               | `tracedMetronome(operation:, invoke:)`                                                                          |
| `otel_modern_treasury` | Modern Treasury business banking (ACH, Wire, RTP, ledger, virtual accounts)                 | `tracedModernTreasury(resource:, operation:, invoke:)`                                                          |
| `otel_mollie`          | Mollie payments (EU and local methods: iDEAL, Bancontact, SEPA, Klarna, Apple Pay)          | `tracedMollie(operation:, invoke:)`                                                                             |
| `otel_monzo`           | Monzo (UK challenger bank)                                                                  | `tracedMonzo(operation:, invoke:)`                                                                              |
| `otel_moov`            | Moov (embedded payments and money movement)                                                 | `tracedMoov(operation:, invoke:)`                                                                               |
| `otel_moralis`         | Moralis (Web3 data and RPC and streams)                                                     | `tracedMoralis(operation:, invoke:)`                                                                            |
| `otel_mx`              | MX (financial data aggregation)                                                             | `tracedMx(operation:, invoke:)`                                                                                 |
| `otel_numeral`         | Numeral (SaaS tax filing and remittance, transactions, registrations, returns)              | `tracedNumeral(operation:, invoke:)`                                                                            |
| `otel_okx`             | OKX (crypto exchange and Web3)                                                              | `tracedOkx(operation:, invoke:)`                                                                                |
| `otel_onfido`          | Onfido (applicants, checks, reports, documents, live photos, watchlists)                    | `tracedOnfido(operation:, invoke:)`                                                                             |
| `otel_orb`             | Orb usage-based billing (events, subscriptions, invoices, plans)                            | `tracedOrb(operation:, invoke:)`                                                                                |
| `otel_paddle`          | Paddle (Merchant of Record billing)                                                         | `tracedPaddle(resource:, action:, invoke:)`                                                                     |
| `otel_paypal`          | PayPal Orders and Payments REST API                                                         | `tracedPaypal(resource:, action:, invoke:)`                                                                     |
| `otel_paystack`        | Paystack payments (Africa)                                                                  | `tracedPaystack(operation:, invoke:)`                                                                           |
| `otel_plaid`           | Plaid (Link, transactions, balances)                                                        | `tracedPlaid(endpoint:, invoke:)`                                                                               |
| `otel_qonversion`      | Qonversion (IAP subscription analytics and paywalls)                                        | `tracedQonversion(operation:, invoke:)`                                                                         |
| `otel_quaderno`        | Quaderno (invoices, credits, evidence, contacts, taxes, VAT MOSS)                           | `tracedQuaderno(operation:, invoke:)`                                                                           |
| `otel_quicknode`       | QuickNode (multi-chain RPC and indexing)                                                    | `tracedQuickNode(operation:, invoke:)`                                                                          |
| `otel_ramp`            | Ramp (corporate cards and spend mgmt)                                                       | `tracedRamp(operation:, invoke:)`                                                                               |
| `otel_razorpay`        | Razorpay (India payments and UPI and subscriptions and RazorpayX banking)                   | `tracedRazorpay(operation:, invoke:)`                                                                           |
| `otel_recharge`        | Recharge subscriptions (subscriptions, charges, orders, customers, bundles)                 | `tracedRecharge(operation:, invoke:)`                                                                           |
| `otel_recurly`         | Recurly subscription billing                                                                | `tracedRecurly(resource:, action:, invoke:)`                                                                    |
| `otel_revenuecat`      | RevenueCat                                                                                  | `tracedRevenueCatPurchase(productIdentifier:, invoke:)`, `tracedRevenueCatRestore(invoke:)`                     |
| `otel_revolut`         | Revolut Business (multi-currency banking and cards)                                         | `tracedRevolut(operation:, invoke:)`                                                                            |
| `otel_rewardful`       | Rewardful affiliate program (campaigns, affiliates, referrals, commissions)                 | `tracedRewardful(operation:, invoke:)`                                                                          |
| `otel_sage_intacct`    | Sage Intacct (mid-market financial mgmt)                                                    | `tracedSageIntacct(operation:, invoke:)`                                                                        |
| `otel_saleor`          | Saleor (GraphQL-first headless commerce with channels and stock locations)                  | `tracedSaleor(operationName:, invoke:)`                                                                         |
| `otel_shopify`         | Shopify Admin GraphQL and REST API                                                          | `tracedShopifyGraphql(operationName:, shop:, invoke:)`, `tracedShopifyRest(resource:, action:, shop:, invoke:)` |
| `otel_shopify_pos`     | Shopify POS (in-store and omnichannel)                                                      | `tracedShopifyPOS(operation:, invoke:)`                                                                         |
| `otel_sovos`           | Sovos (sales/use/VAT, e-invoicing, withholding, IPT, returns)                               | `tracedSovos(operation:, invoke:)`                                                                              |
| `otel_square`          | Square (Payments, Orders, Catalog, Customers, Terminal, Cash App Pay)                       | `tracedSquare(operation:, invoke:)`                                                                             |
| `otel_stigg`           | Stigg (usage-based billing and entitlements)                                                | `tracedStigg(operation:, invoke:)`                                                                              |
| `otel_stripe`          | Stripe API calls                                                                            | `tracedStripeCall(resource:, operation:, invoke:)`                                                              |
| `otel_stripe_tax`      | Stripe Tax (sales tax automation)                                                           | `tracedStripeTax(operation:, invoke:)`                                                                          |
| `otel_sumsub`          | Sumsub (applicants, reviews, KYC/KYB levels, transaction monitoring, AML)                   | `tracedSumsub(operation:, invoke:)`                                                                             |
| `otel_taxjar`          | TaxJar (tax calculation, orders, refunds, customers, nexus, validation, AutoFile)           | `tracedTaxjar(operation:, invoke:)`                                                                             |
| `otel_thirdweb`        | Thirdweb (Web3 client SDK and Engine)                                                       | `tracedThirdweb(operation:, invoke:)`                                                                           |
| `otel_toast`           | Toast (restaurant POS and management)                                                       | `tracedToast(operation:, invoke:)`                                                                              |
| `otel_truelayer`       | TrueLayer open banking (Payments, Data API, Auth, Verification)                             | `tracedTruelayer(product:, operation:, invoke:)`                                                                |
| `otel_unit`            | Unit (embedded banking / BaaS)                                                              | `tracedUnit(operation:, invoke:)`                                                                               |
| `otel_veriff`          | Veriff (sessions, decisions, attempts, watchlist, AML)                                      | `tracedVeriff(operation:, invoke:)`                                                                             |
| `otel_vtex`            | VTEX IO commerce platform (orders, catalog, checkout, master data, pricing, OMS)            | `tracedVtex(operation:, invoke:)`                                                                               |
| `otel_walletconnect`   | WalletConnect (Web3 wallet bridge protocol)                                                 | `tracedWalletConnect(operation:, invoke:)`                                                                      |
| `otel_wise`            | Wise (international transfers and multi-currency)                                           | `tracedWise(operation:, invoke:)`                                                                               |
| `otel_woocommerce`     | WooCommerce REST API (products, orders, customers, refunds, webhooks)                       | `tracedWoocommerce(operation:, invoke:)`                                                                        |
| `otel_yodlee`          | Envestnet Yodlee (financial data aggregation)                                               | `tracedYodlee(operation:, invoke:)`                                                                             |

## Auth and identity

| Package                   | Instruments                                                                                | Entry point                                       |
|---------------------------|--------------------------------------------------------------------------------------------|---------------------------------------------------|
| `otel_appauth`            | AppAuth (generic OAuth 2.0 / OIDC client)                                                  | `tracedAppAuth(operation:, invoke:)`              |
| `otel_auth0`              | Auth0 authentication operations                                                            | `tracedAuth0(operation:, invoke:)`                |
| `otel_clerk`              | Clerk authentication operations                                                            | `tracedClerk(operation:, invoke:)`                |
| `otel_facebook_auth`      | Meta Facebook Login (login, permissions, access token, limited login)                      | `tracedFacebookAuth(operation:, invoke:)`         |
| `otel_frontegg`           | Frontegg (B2B identity, tenant and sub-account hierarchy, entitlements, vendor-side IAM)   | `tracedFrontegg(operation:, invoke:)`             |
| `otel_fusionauth`         | FusionAuth (user mgmt, OAuth2/OIDC/SAML, tenant and application scoping)                   | `tracedFusionauth(operation:, invoke:)`           |
| `otel_jumio`              | Jumio KYX (account creation, transactions, ID verification, screening, eMRTD, biometric... | `tracedJumio(operation:, invoke:)`                |
| `otel_kakao`              | Kakao SDK (KakaoTalk login and share)                                                      | `tracedKakao(operation:, invoke:)`                |
| `otel_keycloak`           | Keycloak (realms, clients, OAuth2/OIDC/SAML, fine-grained authZ, admin API)                | `tracedKeycloak(operation:, realm:, invoke:)`     |
| `otel_kinde`              | Kinde auth (B2B orgs, RBAC, feature flags, billing tier scoping)                           | `tracedKinde(operation:, invoke:)`                |
| `otel_line`               | LINE SDK (login and messaging)                                                             | `tracedLine(operation:, invoke:)`                 |
| `otel_logto`              | Logto open-source auth (OIDC, social/SSO, M2M, RBAC, orgs)                                 | `tracedLogto(operation:, invoke:)`                |
| `otel_oauth`              | Generic OAuth 2.0 / OIDC flows                                                             | `tracedOauth(endpoint:, issuer:, invoke:)`        |
| `otel_okta`               | Okta authentication operations                                                             | `tracedOkta(operation:, invoke:)`                 |
| `otel_ory`                | Ory Network (Kratos identity, Hydra OAuth2/OIDC, Keto AuthZ, Oathkeeper proxy)             | `tracedOry(service:, operation:, invoke:)`        |
| `otel_persona`            | Persona (identity verification: inquiries, accounts, cases, reports, workflows)            | `tracedPersona(operation:, invoke:)`              |
| `otel_sign_in_with_apple` | Sign in with Apple (authorization, credential state, real name, JWT verification)          | `tracedSignInWithApple(operation:, invoke:)`      |
| `otel_stytch`             | Stytch auth (magic links, passkeys, biometrics, OAuth, M2M)                                | `tracedStytch(operation:, invoke:)`               |
| `otel_supertokens`        | SuperTokens open-source auth (recipes for session, passwordless, third-party...            | `tracedSupertokens(recipe:, operation:, invoke:)` |
| `otel_trulioo`            | Trulioo GlobalGateway and EmbedID (identity verify, business verify, watchlist, document)  | `tracedTrulioo(operation:, invoke:)`              |
| `otel_workos`             | WorkOS (B2B SSO, SCIM, Directory Sync, AuthKit, Audit Logs)                                | `tracedWorkos(operation:, module:, invoke:)`      |
| `otel_zitadel`            | ZITADEL (cloud-native IAM)                                                                 | `tracedZitadel(operation:, invoke:)`              |

## Analytics, attribution, ads, feature flags and monitoring

| Package                | Instruments                                                                                  | Entry point                                                                                  |
|------------------------|----------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| `otel_adjust`          | Adjust mobile attribution (sessions, events, callbacks, deferred deep links)                 | `tracedAdjust(operation:, invoke:)`                                                          |
| `otel_amplitude`       | Amplitude product analytics                                                                  | `OTelAmplitude`                                                                              |
| `otel_appdynamics`     | AppDynamics Mobile / Browser SDK events                                                      | `OTelAppdynamics`                                                                            |
| `otel_appsflyer`       | AppsFlyer mobile attribution (conversions, installs, events, DDL, OAID)                      | `tracedAppsflyer(operation:, invoke:)`                                                       |
| `otel_branch_io`       | Branch deep linking and attribution (links, sessions, identity, events)                      | `tracedBranchIo(operation:, invoke:)`                                                        |
| `otel_bugsnag`         | `bugsnag_flutter`                                                                            | `installOTelBugsnagBridge(client)`                                                           |
| `otel_clarity`         | Microsoft Clarity (heatmaps and session replay)                                              | `tracedClarity(operation:, invoke:)`                                                         |
| `otel_configcat`       | ConfigCat feature flags (settings, targeting, segments, environments, products)              | `tracedConfigcat(operation:, invoke:)`                                                       |
| `otel_datadog`         | `datadog_flutter_plugin` RUM                                                                 | `OTelDatadogRum`                                                                             |
| `otel_devcycle`        | DevCycle feature flags (variables, features, environments, targeting, edge SDK metrics)      | `tracedDevcycle(operation:, invoke:)`                                                        |
| `otel_dynatrace`       | OpenTelemetry export plumbing and RUM bridge for Dynatrace                                   | `OTelDynatrace`                                                                              |
| `otel_embrace`         | Package:embrace                                                                              | `OTelEmbrace`                                                                                |
| `otel_eppo`            | Eppo experimentation (flags, randomized experiments, metric measurement, holdouts, bandit... | `tracedEppo(operation:, invoke:)`                                                            |
| `otel_flagsmith`       | Flagsmith feature flags (flags, traits, identities, segments, environments, audit)           | `tracedFlagsmith(operation:, invoke:)`                                                       |
| `otel_fullstory`       | FullStory (events, identify, session metadata)                                               | `OTelFullstory`                                                                              |
| `otel_go_feature_flag` | GO Feature Flag (variation, all_flags, exporters, retrieval, evaluation context)             | `tracedGoFeatureFlag(operation:, invoke:)`                                                   |
| `otel_google_ads`      | Google Ads (campaigns, ad groups, conversions, spend micros)                                 | `tracedGoogleAds(operation:, invoke:)`                                                       |
| `otel_growthbook`      | GrowthBook feature flags and A/B experiments                                                 | `tracedGrowthbookFlag(flagKey:, invoke:)`, `tracedGrowthbookFeature(featureKey:, invoke:)`   |
| `otel_heap`            | Heap product analytics                                                                       | `OTelHeap`                                                                                   |
| `otel_honeycomb`       | Honeycomb events and queries API                                                             | `tracedHoneycombSend(dataset:, invoke:)`                                                     |
| `otel_hotjar`          | Hotjar Identify and Events                                                                   | `OTelHotjar`                                                                                 |
| `otel_hypertune`       | Hypertune typed feature flags and A/B testing (queries, mutations, logical types, flag...    | `tracedHypertune(operation:, invoke:)`                                                       |
| `otel_launchdarkly`    | LaunchDarkly feature-flag evaluations                                                        | `tracedLaunchDarklyEval(flagKey:, invoke:)`                                                  |
| `otel_linkedin_ads`    | LinkedIn Ads (campaigns, audience size, sponsored content, B2B spend)                        | `tracedLinkedinAds(operation:, invoke:)`                                                     |
| `otel_logrocket`       | LogRocket session replay and events                                                          | `OTelLogrocket`                                                                              |
| `otel_meta_ads`        | Meta Ads (campaigns, ad sets, objective, spend, ROAS)                                        | `tracedMetaAds(operation:, invoke:)`                                                         |
| `otel_mixpanel`        | Mixpanel product analytics (track, people, groups)                                           | `OTelMixpanel`                                                                               |
| `otel_new_relic`       | `newrelic_mobile`                                                                            | `OTelNewrelic`                                                                               |
| `otel_optimizely`      | Optimizely feature flags and decisions                                                       | `tracedOptimizelyFeature(featureKey:, invoke:)`, `tracedOptimizelyDecide(flagKey:, invoke:)` |
| `otel_pendo`           | Pendo product analytics and guides                                                           | `OTelPendo`                                                                                  |
| `otel_pinterest_ads`   | Pinterest Ads (campaigns, ad groups, shopping objective, spend)                              | `tracedPinterestAds(operation:, invoke:)`                                                    |
| `otel_posthog`         | PostHog analytics                                                                            | `OTelPostHog`                                                                                |
| `otel_reddit_ads`      | Reddit Ads (campaigns, ad groups, subreddit targeting, spend)                                | `tracedRedditAds(operation:, invoke:)`                                                       |
| `otel_segment`         | Segment analytics                                                                            | `OTelSegment`                                                                                |
| `otel_sentry`          | Sentry / sentry_flutter                                                                      | `installOTelSentryBridge(options)`                                                           |
| `otel_singular`        | Singular (mobile attribution and marketing analytics)                                        | `tracedSingular(operation:, invoke:)`                                                        |
| `otel_snap_ads`        | Snap Ads (campaigns, ad squads, snap pixel, spend)                                           | `tracedSnapAds(operation:, invoke:)`                                                         |
| `otel_split`           | Split.io feature flags (treatments, events, segments, splits, attributes)                    | `tracedSplit(operation:, invoke:)`                                                           |
| `otel_statsig`         | Statsig feature-flag evaluations and experiments                                             | `tracedStatsigGate(gateName:, invoke:)`, `tracedStatsigConfig(configName:, invoke:)`         |
| `otel_tiktok_ads`      | TikTok Ads (campaigns, ad groups, spark ads, spend)                                          | `tracedTiktokAds(operation:, invoke:)`                                                       |
| `otel_unleash`         | Unleash feature flags (toggles, variants, strategies, contexts, projects, metrics)           | `tracedUnleash(operation:, invoke:)`                                                         |
| `otel_x_ads`           | X Ads (campaigns, line items, objective, spend)                                              | `tracedXAds(operation:, invoke:)`                                                            |

## Email, SMS, push, chat and calls

| Package                            | Instruments                                                                               | Entry point                                                                   |
|------------------------------------|-------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------|
| `otel_agora`                       | Agora real-time engagement (voice/video/RTM/cloud recording)                              | `tracedAgora(service:, operation:, invoke:)`                                  |
| `otel_airship`                     | Airship (mobile and web push, in-app messages, SMS, email, journeys, named users...       | `tracedAirship(operation:, invoke:)`                                          |
| `otel_apns`                        | Apple Push Notification service (HTTP/2 send, priorities, collapse ids, feedback)         | `tracedApns(operation:, invoke:)`                                             |
| `otel_beehiiv`                     | Beehiiv (newsletters, subscriptions, posts, ad placements, custom fields, segments)       | `tracedBeehiiv(operation:, invoke:)`                                          |
| `otel_braze`                       | Braze customer engagement (custom events, user attributes, in-app messages)               | `OTelBraze`                                                                   |
| `otel_brevo`                       | Brevo (formerly Sendinblue): transactional email, SMS, contacts, lists, campaigns...      | `tracedBrevo(operation:, invoke:)`                                            |
| `otel_briteverify`                 | BriteVerify (email verification)                                                          | `tracedBriteVerify(operation:, invoke:)`                                      |
| `otel_courier`                     | Courier notifications (send, templates, users, preferences, lists, brands, inbox)         | `tracedCourier(operation:, invoke:)`                                          |
| `otel_crisp`                       | Crisp (live chat and helpdesk, conversations, sessions, people, MagicType)                | `tracedCrisp(operation:, invoke:)`                                            |
| `otel_customer_io`                 | Customer.io (track, identify, screen, profile attributes)                                 | `OTelCustomerIo`                                                              |
| `otel_daily_co`                    | Daily.co WebRTC video rooms and recording                                                 | `tracedDailyCo(operation:, invoke:)`                                          |
| `otel_discord`                     | Discord REST and Webhooks API                                                             | `tracedDiscord(resource:, action:, invoke:)`, `tracedDiscordWebhook(invoke:)` |
| `otel_expo_push`                   | Expo push notifications (tickets, receipts, priority, ttl)                                | `tracedExpoPush(operation:, invoke:)`                                         |
| `otel_fcm`                         | Firebase Cloud Messaging (topics, device tokens, multicast, priority)                     | `tracedFcm(operation:, invoke:)`                                              |
| `otel_flutter_local_notifications` | `flutter_local_notifications`                                                             | Traced wrappers, `recordNotificationResponse`                                 |
| `otel_front`                       | Front (shared inbox and email-first support, conversations, channels, rules)              | `tracedFront(operation:, invoke:)`                                            |
| `otel_front_app`                   | Front (shared inbox and customer ops)                                                     | `tracedFrontApp(operation:, invoke:)`                                         |
| `otel_gladly`                      | Gladly customer service (customer timelines, conversations, topics, agent availability)   | `tracedGladly(operation:, invoke:)`                                           |
| `otel_gorgias`                     | Gorgias (commerce-focused support: tickets, customers, integrations, macros, statistics)  | `tracedGorgias(operation:, invoke:)`                                          |
| `otel_hundredms`                   | 100ms (HMS) video and audio rooms, RTMP ingest, HLS                                       | `tracedHundredms(operation:, invoke:)`                                        |
| `otel_intercom`                    | Intercom Messenger (user events, conversations)                                           | `OTelIntercom`                                                                |
| `otel_iterable`                    | Iterable cross-channel marketing events                                                   | `OTelIterable`                                                                |
| `otel_jitsi_meet`                  | Jitsi Meet (open-source video conferencing)                                               | `tracedJitsiMeet(operation:, invoke:)`                                        |
| `otel_kit`                         | Kit (formerly ConvertKit): subscribers, broadcasts, sequences, forms, tags, purchases     | `tracedKit(operation:, invoke:)`                                              |
| `otel_knock`                       | Knock notifications (workflows, recipients, preferences, channels, schedules)             | `tracedKnock(operation:, invoke:)`                                            |
| `otel_kustomer`                    | Kustomer (CRM-style support: customers, conversations, messages, workflows, queues)       | `tracedKustomer(operation:, invoke:)`                                         |
| `otel_livekit`                     | LiveKit (SFU rooms, Cloud, Agents, Egress, Ingress)                                       | `tracedLivekit(service:, operation:, invoke:)`                                |
| `otel_loops`                       | Loops transactional email and contact sync                                                | `tracedLoops(operation:, invoke:)`                                            |
| `otel_magicbell`                   | MagicBell (in-app inbox and multi-channel: notifications, users, preferences, channels... | `tracedMagicbell(operation:, invoke:)`                                        |
| `otel_mailchimp`                   | Mailchimp Marketing (audiences, campaigns, automations, e-commerce, reports, tags)        | `tracedMailchimp(operation:, invoke:)`                                        |
| `otel_mailgun`                     | Mailgun email API                                                                         | `tracedMailgunSend(domain:, from:, to:, invoke:)`                             |
| `otel_mailparser`                  | Mailparser email parsing (mailboxes, parsing rules, downloads, webhook delivery)          | `tracedMailparser(operation:, invoke:)`                                       |
| `otel_mandrill`                    | Mandrill (transactional email from Mailchimp: messages, templates, webhooks, rejects...   | `tracedMandrill(operation:, invoke:)`                                         |
| `otel_neverbounce`                 | NeverBounce email verification (single, batch, jobs, credits)                             | `tracedNeverbounce(operation:, invoke:)`                                      |
| `otel_nylas`                       | Nylas (universal calendar, email, contacts API with per-mailbox connected billing)        | `tracedNylas(operation:, invoke:)`                                            |
| `otel_onesignal`                   | OneSignal push notifications (send, click, foreground, tags)                              | `tracedOnesignalSend(appId:, invoke:)`                                        |
| `otel_plivo`                       | Plivo (SMS / MMS / Voice / WhatsApp)                                                      | `tracedPlivo(operation:, invoke:)`                                            |
| `otel_postmark`                    | Postmark transactional email API                                                          | `tracedPostmarkSend(from:, to:, invoke:)`                                     |
| `otel_resend`                      | Resend transactional email API                                                            | `tracedResendSend(from:, to:, invoke:)`                                       |
| `otel_sendbird`                    | Sendbird chat (channels, messages, users, push, AI bot)                                   | `tracedSendbird(operation:, invoke:)`                                         |
| `otel_sendgrid`                    | SendGrid email sends                                                                      | `tracedSendGridSend(to:, invoke:)`                                            |
| `otel_sinch`                       | Sinch (SMS / Voice / Verification / Conversation)                                         | `tracedSinch(operation:, invoke:)`                                            |
| `otel_slack`                       | Slack Web API and Incoming Webhooks                                                       | `tracedSlackApi(method:, invoke:)`, `tracedSlackWebhook(invoke:)`             |
| `otel_sparkpost`                   | SparkPost (transmissions, templates, recipient lists, subaccounts, webhooks, message...   | `tracedSparkpost(operation:, invoke:)`                                        |
| `otel_stream_chat`                 | Stream Chat (channels, messages, threads, reactions, permissions)                         | `tracedStreamChat(operation:, invoke:)`                                       |
| `otel_telegram`                    | Telegram Bot API                                                                          | `tracedTelegram(method:, invoke:)`                                            |
| `otel_twilio`                      | Twilio API calls                                                                          | `tracedTwilioMessage(to:, invoke:)`, `tracedTwilioCall(to:, invoke:)`         |
| `otel_twilio_engage`               | Twilio Engage / Segment Personas (audiences, traits, journeys, profiles)                  | `tracedTwilioEngage(operation:, invoke:)`                                     |
| `otel_vonage`                      | Vonage Communications APIs (SMS / Voice / Verify, formerly Nexmo)                         | `tracedVonage(operation:, invoke:)`                                           |
| `otel_wechat`                      | WeChat SDK (login and pay and share)                                                      | `tracedWechat(operation:, invoke:)`                                           |
| `otel_whereby`                     | Whereby Embedded video meetings and recordings                                            | `tracedWhereby(operation:, invoke:)`                                          |
| `otel_zendesk`                     | Zendesk Support API (tickets, users)                                                      | `tracedZendesk(resource:, action:, subdomain:, invoke:)`                      |
| `otel_zerobounce`                  | ZeroBounce email validation (validate, bulk, scoring, ai-scoring, credits)                | `tracedZerobounce(operation:, invoke:)`                                       |
| `otel_zoom`                        | Zoom Meetings and Webinars REST API                                                       | `tracedZoom(resource:, action:, invoke:)`                                     |

## Media, maps and device

| Package                 | Instruments                                                                               | Entry point                                                                         |
|-------------------------|-------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------|
| `otel_app_links`        | Native app links (uni_links / app_links)                                                  | `tracedAppLinks(operation:, invoke:)`                                               |
| `otel_cloudinary`       | Cloudinary (upload, transformations, video, asset management, admin)                      | `tracedCloudinary(operation:, invoke:)`                                             |
| `otel_google_maps`      | Google Maps Platform (Directions, Places, Geocoding, Roads, Distance Matrix, Street View) | `tracedGoogleMaps(api:, invoke:)`                                                   |
| `otel_here_maps`        | HERE Location Services (Routing, Geocoding, Search, Tour Planning, Matrix Routing)        | `tracedHereMaps(service:, invoke:)`                                                 |
| `otel_imgix`            | Imgix (rendering URLs, purges, sources, asset management, AI assets)                      | `tracedImgix(operation:, invoke:)`                                                  |
| `otel_mapbox`           | Mapbox Geocoding / Directions / Matrix / Search API calls                                 | `tracedMapboxGeocode(query:, invoke:)`, `tracedMapboxDirections(profile:, invoke:)` |
| `otel_mux`              | Mux video player events (play, pause, error, rebuffer)                                    | `OTelMux`                                                                           |
| `otel_outlook_calendar` | Microsoft Graph Outlook calendar (events, findMeetingTimes, calendarView, delta sync)     | `tracedOutlookCalendar(operation:, invoke:)`                                        |
| `otel_radar`            | Radar location platform (geofencing, places, search, trip tracking, routing)              | `tracedRadar(operation:, invoke:)`                                                  |
| `otel_spotify`          | Spotify Web API (catalog and user and playback)                                           | `tracedSpotify(operation:, invoke:)`                                                |
| `otel_tomtom`           | TomTom Maps APIs (search, routing, traffic, maps, EV charging, geofencing)                | `tracedTomtom(product:, invoke:)`                                                   |
| `otel_uploadcare`       | Uploadcare (file uploads, image CDN and transforms, groups, webhooks, AWS Rekognition)    | `tracedUploadcare(operation:, invoke:)`                                             |
| `otel_workmanager`      | `workmanager`                                                                             | Wrap the task body                                                                  |

## AWS

| Package                   | Instruments                                                                                 | Entry point                                                                                                                 |
|---------------------------|---------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| `otel_amplify`            | AWS Amplify BaaS calls                                                                      | `tracedAmplifyAuth(operation:, invoke:)`, `tracedAmplifyApi(apiName:, operation:, invoke:)`                                 |
| `otel_aws_amplify`        | AWS Amplify (full-stack mobile and web platform)                                            | `tracedAwsAmplify(operation:, invoke:)`                                                                                     |
| `otel_aws_api_gateway`    | AWS API Gateway (REST and HTTP and WebSocket APIs)                                          | `tracedAwsApiGateway(operation:, invoke:)`                                                                                  |
| `otel_aws_appsync`        | AWS AppSync (managed GraphQL)                                                               | `tracedAwsAppSync(operation:, invoke:)`                                                                                     |
| `otel_aws_athena`         | AWS Athena (serverless SQL)                                                                 | `tracedAwsAthena(operation:, invoke:)`                                                                                      |
| `otel_aws_cloudfront`     | AWS CloudFront (CDN)                                                                        | `tracedAwsCloudFront(operation:, invoke:)`                                                                                  |
| `otel_aws_cloudwatch`     | AWS CloudWatch (metrics and logs and alarms)                                                | `tracedAwsCloudWatch(operation:, invoke:)`                                                                                  |
| `otel_aws_cognito`        | AWS Cognito (User Pools and Identity Pools)                                                 | `tracedAwsCognito(operation:, invoke:)`                                                                                     |
| `otel_aws_comprehend`     | AWS Comprehend NLP (sentiment, entities, key phrases, PII, syntax)                          | `tracedAwsComprehend(operation:, invoke:)`                                                                                  |
| `otel_aws_dynamodb`       | AWS DynamoDB (managed NoSQL)                                                                | `tracedAwsDynamoDB(operation:, invoke:)`                                                                                    |
| `otel_aws_ecr`            | AWS ECR (container registry)                                                                | `tracedAwsECR(operation:, invoke:)`                                                                                         |
| `otel_aws_ecs`            | AWS ECS / Fargate                                                                           | `tracedAwsEcs(operation:, invoke:)`                                                                                         |
| `otel_aws_eks`            | AWS EKS (managed Kubernetes)                                                                | `tracedAwsEKS(operation:, invoke:)`                                                                                         |
| `otel_aws_eventbridge`    | AWS EventBridge (event bus)                                                                 | `tracedAwsEventBridge(operation:, invoke:)`                                                                                 |
| `otel_aws_glue`           | AWS Glue (ETL and Data Catalog)                                                             | `tracedAwsGlue(operation:, invoke:)`                                                                                        |
| `otel_aws_iot_core`       | AWS IoT Core (device connectivity and rules and jobs)                                       | `tracedAwsIoTCore(operation:, invoke:)`                                                                                     |
| `otel_aws_kinesis`        | AWS Kinesis Data Streams                                                                    | `tracedAwsKinesis(operation:, invoke:)`                                                                                     |
| `otel_aws_kms`            | AWS KMS encrypt/decrypt/sign/verify                                                         | `tracedAwsKms(operation:, invoke:)`                                                                                         |
| `otel_aws_lambda`         | AWS Lambda (serverless functions)                                                           | `tracedAwsLambda(operation:, invoke:)`                                                                                      |
| `otel_aws_msk`            | AWS MSK (managed Kafka)                                                                     | `tracedAwsMSK(operation:, invoke:)`                                                                                         |
| `otel_aws_neptune`        | AWS Neptune graph database (Gremlin, openCypher, SPARQL)                                    | `tracedAwsNeptune(operation:, language:, invoke:)`                                                                          |
| `otel_aws_polly`          | AWS Polly text-to-speech                                                                    | `tracedAwsPolly(voiceId:, engine:, invoke:)`                                                                                |
| `otel_aws_rds`            | AWS RDS (managed databases)                                                                 | `tracedAwsRds(operation:, invoke:)`                                                                                         |
| `otel_aws_rekognition`    | AWS Rekognition image and video analysis (labels, faces, moderation, text, celebs)          | `tracedAwsRekognition(operation:, invoke:)`                                                                                 |
| `otel_aws_route53`        | AWS Route 53 (DNS and domain registration and health checks)                                | `tracedAwsRoute53(operation:, invoke:)`                                                                                     |
| `otel_aws_s3`             | AWS S3 API calls                                                                            | `tracedS3Call(bucket:, operation:, invoke:)`                                                                                |
| `otel_aws_secretsmanager` | AWS Secrets Manager                                                                         | `tracedAwsSecretsmanager(operation:, invoke:)`                                                                              |
| `otel_aws_ses`            | Amazon SES (SendEmail, SendBulkEmail, SendRawEmail, SendTemplatedEmail, suppression list... | `tracedAwsSes(operation:, invoke:)`                                                                                         |
| `otel_aws_sns`            | AWS SNS (managed pub/sub)                                                                   | `tracedAwsSNS(operation:, invoke:)`                                                                                         |
| `otel_aws_sqs`            | AWS SQS (managed message queue)                                                             | `tracedAwsSQS(operation:, invoke:)`                                                                                         |
| `otel_aws_step_functions` | AWS Step Functions (state machine orchestration)                                            | `tracedAwsStepFunctions(operation:, invoke:)`                                                                               |
| `otel_aws_sts`            | AWS STS AssumeRole / GetCallerIdentity                                                      | `tracedAwsSts(operation:, invoke:)`                                                                                         |
| `otel_aws_textract`       | AWS Textract OCR, form/table analysis, and queries                                          | `tracedAwsTextract(operation:, invoke:)`                                                                                    |
| `otel_aws_transcribe`     | AWS Transcribe speech-to-text (batch and streaming and Medical)                             | `tracedAwsTranscribe(invoke:)`                                                                                              |
| `otel_cloudwatch_logs`    | AWS CloudWatch Logs (PutLogEvents)                                                          | `tracedCloudwatchLogsPutLogEvents(logGroup:, logStream:, invoke:)`                                                          |
| `otel_dynamodb`           | AWS DynamoDB (GetItem, PutItem, Query, etc.)                                                | `tracedDynamoDb(operation:, tableName:, invoke:)`                                                                           |
| `otel_dynamodb_streams`   | AWS DynamoDB Streams (consumer)                                                             | `tracedDynamodbStreamsConsume(tableName:, shardId:, invoke:)`                                                               |
| `otel_eventbridge`        | AWS EventBridge PutEvents                                                                   | `tracedEventbridgePutEvents(eventBus:, source:, detailType:, invoke:)`                                                      |
| `otel_kinesis`            | AWS Kinesis Data Streams (put, get records)                                                 | `tracedKinesisPutRecord(streamName:, invoke:)`, `tracedKinesisGetRecords(streamName:, shardId:, invoke:)`                   |
| `otel_lambda`             | AWS Lambda Invoke                                                                           | `tracedLambdaInvoke(functionName:, invoke:)`                                                                                |
| `otel_redshift`           | AWS Redshift and Redshift Data API                                                          | `tracedRedshiftQuery(statement:, invoke:)`                                                                                  |
| `otel_sns`                | AWS SNS (Publish to topic / SMS / email subscribers)                                        | `tracedSnsPublish(invoke:)`                                                                                                 |
| `otel_sqs`                | AWS SQS (send, receive, delete messages)                                                    | `tracedSqsSendMessage(queueUrl:, invoke:)`, `tracedSqsReceiveMessage(queueUrl:, invoke:)`                                   |
| `otel_step_functions`     | AWS Step Functions (StartExecution, state transitions)                                      | `tracedStepFunctionsStartExecution(stateMachineArn:, invoke:)`, `tracedStepFunctionsState(stateName:, stateType:, invoke:)` |
| `otel_xray`               | AWS X-Ray PutTraceSegments                                                                  | `tracedXrayPutSegments(invoke:)`                                                                                            |

## Azure and Microsoft

| Package                         | Instruments                                                                    | Entry point                                                      |
|---------------------------------|--------------------------------------------------------------------------------|------------------------------------------------------------------|
| `otel_azure_ai_search`          | Azure AI Search (formerly Cognitive Search)                                    | `tracedAzureAiSearch(operation:, invoke:)`                       |
| `otel_azure_aks`                | Azure AKS (managed Kubernetes)                                                 | `tracedAzureAKS(operation:, invoke:)`                            |
| `otel_azure_app_service`        | Azure App Service                                                              | `tracedAzureAppService(operation:, invoke:)`                     |
| `otel_azure_blob_storage`       | Azure Blob Storage                                                             | `tracedAzureBlobStorage(operation:, invoke:)`                    |
| `otel_azure_container_registry` | Azure Container Registry                                                       | `tracedAzureContainerRegistry(operation:, invoke:)`              |
| `otel_azure_content_safety`     | Azure AI Content Safety (text and image moderation, jailbreak / prompt shield) | `tracedAzureContentSafety(operation:, invoke:)`                  |
| `otel_azure_cosmos_db`          | Azure Cosmos DB (SQL/Mongo/Cassandra/Gremlin/Table)                            | `tracedAzureCosmosDb(operation:, invoke:)`                       |
| `otel_azure_devops`             | Azure DevOps (pipelines and repos and boards)                                  | `tracedAzureDevOps(operation:, invoke:)`                         |
| `otel_azure_event_hubs`         | Azure Event Hubs (Kafka-compatible streaming)                                  | `tracedAzureEventHubs(operation:, invoke:)`                      |
| `otel_azure_functions`          | Azure Functions (serverless)                                                   | `tracedAzureFunctions(operation:, invoke:)`                      |
| `otel_azure_iot_hub`            | Azure IoT Hub (device-to-cloud messaging and twins and jobs)                   | `tracedAzureIoTHub(operation:, invoke:)`                         |
| `otel_azure_key_vault`          | Azure Key Vault (secrets / keys / certificates)                                | `tracedAzureKeyVault(operation:, invoke:)`                       |
| `otel_azure_monitor`            | Azure Monitor (logs and metrics and alerts)                                    | `tracedAzureMonitor(operation:, invoke:)`                        |
| `otel_azure_service_bus`        | Azure Service Bus (messaging)                                                  | `tracedAzureServiceBus(operation:, invoke:)`                     |
| `otel_azure_speech`             | Azure Speech Services (STT, TTS, translation, speaker recognition)             | `tracedAzureSpeech(operation:, voice:, invoke:)`                 |
| `otel_azure_sql_database`       | Azure SQL Database                                                             | `tracedAzureSqlDatabase(operation:, invoke:)`                    |
| `otel_azure_translator`         | Azure AI Translator (text and document translation, language detection)        | `tracedAzureTranslator(invoke:)`                                 |
| `otel_azure_vision`             | Azure AI Vision (Image Analysis, Read OCR, Custom Vision)                      | `tracedAzureVision(operation:, invoke:)`                         |
| `otel_dynamics_365`             | Microsoft Dynamics 365 (CRM and ERP)                                           | `tracedDynamics365(operation:, invoke:)`                         |
| `otel_microsoft_teams`          | Microsoft Teams (chat and meetings and apps)                                   | `tracedMicrosoftTeams(operation:, invoke:)`                      |
| `otel_msal`                     | Microsoft Authentication Library (MSAL)                                        | `tracedMsal(operation:, invoke:)`                                |
| `otel_msteams`                  | Microsoft Teams Graph and Incoming Webhooks                                    | `tracedMsTeams(path:, invoke:)`, `tracedMsTeamsWebhook(invoke:)` |

## Infrastructure, DevOps and security

| Package                    | Instruments                                                                                | Entry point                                                                                                                   |
|----------------------------|--------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------|
| `otel_apigee`              | Apigee (Google API management)                                                             | `tracedApigee(operation:, invoke:)`                                                                                           |
| `otel_argocd`              | ArgoCD applications and sync operations                                                    | `tracedArgocd(resource:, action:, invoke:)`                                                                                   |
| `otel_backblaze_b2`        | Backblaze B2 (S3-compatible and Native API, buckets, files, large files, application keys) | `tracedBackblazeB2(operation:, invoke:)`                                                                                      |
| `otel_bitbucket_pipelines` | Bitbucket Pipelines (CI/CD)                                                                | `tracedBitbucketPipelines(operation:, invoke:)`                                                                               |
| `otel_browserstack`        | BrowserStack (cross-browser cloud testing)                                                 | `tracedBrowserStack(operation:, invoke:)`                                                                                     |
| `otel_buildkite`           | Buildkite REST API and Agent API                                                           | `tracedBuildkite(resource:, action:, invoke:)`                                                                                |
| `otel_bunny`               | Bunny.net (CDN pull zones, storage zones, Stream library, Edge Storage, Magic Containers)  | `tracedBunny(operation:, invoke:)`                                                                                            |
| `otel_circleci`            | CircleCI v2 API and webhook receivers                                                      | `tracedCircleci(resource:, action:, invoke:)`                                                                                 |
| `otel_cloudflare`          | Cloudflare R2 (S3-compatible), KV, and Workers RPC                                         | `tracedCloudflareR2(operation:, bucket:, objectKey:, invoke:)`, `tracedCloudflareKv(operation:, namespace:, kvKey:, invoke:)` |
| `otel_cloudflare_dns`      | Cloudflare DNS (authoritative DNS and DNSSEC)                                              | `tracedCloudflareDNS(operation:, invoke:)`                                                                                    |
| `otel_cloudflare_r2`       | Cloudflare R2 (S3-compatible object storage with zero egress, buckets, objects...          | `tracedCloudflareR2(operation:, invoke:)`                                                                                     |
| `otel_cloudflare_stream`   | Cloudflare Stream (video on demand and live streaming and Stream Connect)                  | `tracedCloudflareStream(operation:, invoke:)`                                                                                 |
| `otel_cloudflare_workers`  | Cloudflare Workers                                                                         | `tracedCloudflareWorkers(operation:, invoke:)`                                                                                |
| `otel_cloudfront`          | AWS CloudFront (invalidations, distribution mgmt, signed URLs)                             | `tracedCloudfront(operation:, distributionId:, invoke:)`                                                                      |
| `otel_codemagic`           | Codemagic CI/CD                                                                            | `tracedCodemagic(operation:, invoke:)`                                                                                        |
| `otel_digitalocean`        | DigitalOcean (droplets / spaces / databases / k8s / app platform / functions / load...     | `tracedDigitalOcean(operation:, invoke:)`                                                                                     |
| `otel_doppler`             | Doppler (secrets manager)                                                                  | `tracedDoppler(operation:, invoke:)`                                                                                          |
| `otel_drata`               | Drata compliance automation (controls, frameworks, evidence, monitors)                     | `tracedDrata(operation:, invoke:)`                                                                                            |
| `otel_fly_io`              | Fly.io (global edge PaaS)                                                                  | `tracedFlyIo(operation:, invoke:)`                                                                                            |
| `otel_github_actions`      | GitHub Actions workflow runs and jobs                                                      | `tracedGithubActions(resource:, action:, owner:, repo:, invoke:)`, `tracedGithubActionsStep(stepName:, invoke:)`              |
| `otel_gitlab_ci`           | GitLab CI/CD (pipelines and jobs and runners)                                              | `tracedGitlabCI(operation:, invoke:)`                                                                                         |
| `otel_grafana_cloud`       | Grafana Cloud OTLP / Loki / Mimir push                                                     | `tracedGrafanaLokiPush(invoke:)`, `tracedGrafanaMimirPush(invoke:)`                                                           |
| `otel_harbor`              | Harbor (self-hosted container registry)                                                    | `tracedHarbor(operation:, invoke:)`                                                                                           |
| `otel_incident_io`         | Incident.io (modern incident management)                                                   | `tracedIncidentIo(operation:, invoke:)`                                                                                       |
| `otel_infisical`           | Infisical (open-source secrets manager)                                                    | `tracedInfisical(operation:, invoke:)`                                                                                        |
| `otel_istio`               | Istio (service mesh)                                                                       | `tracedIstio(operation:, invoke:)`                                                                                            |
| `otel_jenkins`             | Jenkins REST API and Build trigger                                                         | `tracedJenkins(resource:, action:, invoke:)`                                                                                  |
| `otel_kong`                | Kong (API gateway)                                                                         | `tracedKong(operation:, invoke:)`                                                                                             |
| `otel_kubernetes_api`      | Kubernetes REST API (apply, watch, exec)                                                   | `tracedKubernetesApi(verb:, kind:, invoke:)`                                                                                  |
| `otel_lightstep`           | Lightstep (now ServiceNow Cloud Observability)                                             | `tracedLightstepPush(invoke:)`                                                                                                |
| `otel_linkerd`             | Linkerd (service mesh)                                                                     | `tracedLinkerd(operation:, invoke:)`                                                                                          |
| `otel_netlify`             | Netlify (web/serverless platform)                                                          | `tracedNetlify(operation:, invoke:)`                                                                                          |
| `otel_opsgenie`            | Atlassian Opsgenie alerts API                                                              | `tracedOpsgenieAlert(action:, invoke:)`                                                                                       |
| `otel_pagerduty`           | PagerDuty incidents and Events API                                                         | `tracedPagerdutyEvent(eventAction:, invoke:)`, `tracedPagerdutyRest(resource:, action:, invoke:)`                             |
| `otel_playwright`          | Playwright (browser automation)                                                            | `tracedPlaywright(operation:, invoke:)`                                                                                       |
| `otel_railway`             | Railway (PaaS)                                                                             | `tracedRailway(operation:, invoke:)`                                                                                          |
| `otel_render`              | Render (managed PaaS)                                                                      | `tracedRender(operation:, invoke:)`                                                                                           |
| `otel_saucelabs`           | Sauce Labs (cross-browser cloud testing)                                                   | `tracedSauceLabs(operation:, invoke:)`                                                                                        |
| `otel_secureframe`         | Secureframe compliance automation (frameworks, controls, tests, evidence)                  | `tracedSecureframe(operation:, invoke:)`                                                                                      |
| `otel_signoz`              | SigNoz open-source observability (custom event ingest and alerts API)                      | `tracedSignoz(operation:, invoke:)`                                                                                           |
| `otel_snyk`                | Snyk (SCA / SAST / IaC / Container security)                                               | `tracedSnyk(operation:, invoke:)`                                                                                             |
| `otel_sonarqube`           | SonarQube / SonarCloud (code quality and security)                                         | `tracedSonarQube(operation:, invoke:)`                                                                                        |
| `otel_sourcegraph`         | Sourcegraph (code search and intelligence and Cody)                                        | `tracedSourcegraph(operation:, invoke:)`                                                                                      |
| `otel_splunk`              | Splunk Observability Cloud and HEC events                                                  | `tracedSplunkHec(invoke:)`, `tracedSplunkO11y(metricName:, invoke:)`                                                          |
| `otel_statuspage`          | Atlassian Statuspage (component and incident updates)                                      | `tracedStatuspage(operation:, invoke:)`                                                                                       |
| `otel_tailscale`           | Tailscale (zero-trust mesh VPN)                                                            | `tracedTailscale(operation:, invoke:)`                                                                                        |
| `otel_teleport`            | Teleport (zero-trust access for servers, DBs, k8s, apps)                                   | `tracedTeleport(operation:, invoke:)`                                                                                         |
| `otel_terraform_cloud`     | Terraform Cloud / HCP Terraform API                                                        | `tracedTerraformCloud(resource:, action:, invoke:)`                                                                           |
| `otel_traefik`             | Traefik (edge router / API gateway)                                                        | `tracedTraefik(operation:, invoke:)`                                                                                          |
| `otel_tugboat_logic`       | Tugboat Logic / OneTrust Certification Automation (frameworks, controls, evidence...       | `tracedTugboatLogic(operation:, invoke:)`                                                                                     |
| `otel_vanta`               | Vanta compliance automation (controls, frameworks, evidence, tests)                        | `tracedVanta(operation:, invoke:)`                                                                                            |
| `otel_vault`               | HashiCorp Vault secrets/auth/sys API                                                       | `tracedVault(method:, mountPath:, invoke:)`                                                                                   |
| `otel_vercel`              | Vercel (deployments and functions and edge config)                                         | `tracedVercel(operation:, invoke:)`                                                                                           |
| `otel_wasabi`              | Wasabi (S3-compatible cloud storage, buckets, objects, multipart, lifecycle)               | `tracedWasabi(operation:, invoke:)`                                                                                           |

## Data pipelines and automation

| Package            | Instruments                                                                    | Entry point                                                                          |
|--------------------|--------------------------------------------------------------------------------|--------------------------------------------------------------------------------------|
| `otel_airbyte`     | Airbyte (open-source ELT and Airbyte Cloud)                                    | `tracedAirbyte(operation:, invoke:)`                                                 |
| `otel_airflow`     | Apache Airflow (DAGs, tasks, runs, schedules, pools)                           | `tracedAirflow(operation:, invoke:)`                                                 |
| `otel_census`      | Census reverse ETL (syncs, segments, destinations, sync runs)                  | `tracedCensus(operation:, invoke:)`                                                  |
| `otel_dagster`     | Dagster orchestration (assets, jobs, runs, materializations)                   | `tracedDagster(operation:, invoke:)`                                                 |
| `otel_dbt_cloud`   | Dbt Cloud (jobs, runs, models, tests, freshness, project)                      | `tracedDbtCloud(operation:, invoke:)`                                                |
| `otel_fivetran`    | Fivetran (managed ELT)                                                         | `tracedFivetran(operation:, invoke:)`                                                |
| `otel_hightouch`   | Hightouch reverse ETL (syncs, models, destinations, run rows)                  | `tracedHightouch(operation:, invoke:)`                                               |
| `otel_n8n`         | N8n workflow webhooks and REST API                                             | `tracedN8nWebhook(path:, invoke:)`, `tracedN8nApi(resource:, action:, invoke:)`      |
| `otel_pipedream`   | Pipedream workflows and webhook automation (sources, workflows, event credits) | `tracedPipedream(operation:, invoke:)`                                               |
| `otel_prefect`     | Prefect orchestration (flows, deployments, runs, tasks, work pools)            | `tracedPrefect(operation:, invoke:)`                                                 |
| `otel_rudderstack` | RudderStack CDP (sources, destinations, transformations, events)               | `tracedRudderstack(operation:, invoke:)`                                             |
| `otel_zapier`      | Zapier (catch-hook, Zaps, NLA actions)                                         | `tracedZapierCatchHook(hookId:, invoke:)`, `tracedZapierNlaAction(action:, invoke:)` |

## Business and productivity services

| Package                | Instruments                                                                            | Entry point                                                                                   |
|------------------------|----------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| `otel_activecampaign`  | ActiveCampaign (contacts, deals, automations, campaigns, lists, tags)                  | `tracedActivecampaign(operation:, invoke:)`                                                   |
| `otel_adobe_sign`      | Adobe Acrobat Sign (agreements, library documents, mega sign, webhooks, workflows)     | `tracedAdobeSign(operation:, invoke:)`                                                        |
| `otel_airtable`        | Airtable REST API                                                                      | `tracedAirtable(baseId:, tableName:, action:, invoke:)`                                       |
| `otel_amadeus`         | Amadeus for Developers (flights/hotels/cars)                                           | `tracedAmadeus(operation:, invoke:)`                                                          |
| `otel_anvil`           | Anvil (PDF filling, Etch e-sign, Workflows, GraphQL)                                   | `tracedAnvil(operation:, invoke:)`                                                            |
| `otel_apollo_io`       | Apollo.io sales prospecting (search, sequences, contacts, credits)                     | `tracedApolloIo(operation:, invoke:)`                                                         |
| `otel_asana`           | Asana REST API                                                                         | `tracedAsana(resource:, action:, invoke:)`                                                    |
| `otel_ashby`           | Ashby recruiting (candidates, openings, interviews, feedback forms)                    | `tracedAshby(operation:, invoke:)`                                                            |
| `otel_attio`           | Attio (objects, records, lists, attributes, workspaces, threads, comments)             | `tracedAttio(operation:, invoke:)`                                                            |
| `otel_bamboohr`        | BambooHR (employees directory, time off, onboarding, custom reports, payroll exports)  | `tracedBamboohr(operation:, invoke:)`                                                         |
| `otel_bazaarvoice`     | Bazaarvoice (reviews and UGC)                                                          | `tracedBazaarvoice(operation:, invoke:)`                                                      |
| `otel_boldsign`        | BoldSign (documents, templates, brands, contacts, embedded signing, OAuth)             | `tracedBoldsign(operation:, invoke:)`                                                         |
| `otel_box`             | Box content management API                                                             | `tracedBox(resource:, action:, invoke:)`                                                      |
| `otel_calcom`          | Cal.com v2 (bookings, event types, slots, availability, teams, webhooks)               | `tracedCalcom(operation:, invoke:)`                                                           |
| `otel_calendly`        | Calendly v2 (event types, scheduled events, invitees, routing forms, webhooks)         | `tracedCalendly(operation:, invoke:)`                                                         |
| `otel_canny`           | Canny customer feedback (posts, votes, boards, changelogs)                             | `tracedCanny(operation:, invoke:)`                                                            |
| `otel_clay`            | Clay enrichment waterfalls (tables, columns, runs, providers)                          | `tracedClay(operation:, invoke:)`                                                             |
| `otel_clearbit`        | Clearbit (B2B enrichment)                                                              | `tracedClearbit(operation:, invoke:)`                                                         |
| `otel_clickup`         | ClickUp REST API                                                                       | `tracedClickup(resource:, action:, invoke:)`                                                  |
| `otel_close`           | Close CRM (leads, opportunities, contacts, activities, sequences, calls, smart views)  | `tracedClose(operation:, invoke:)`                                                            |
| `otel_confluence`      | Atlassian Confluence Cloud REST API                                                    | `tracedConfluence(resource:, action:, site:, invoke:)`                                        |
| `otel_contentful`      | Contentful (CDA, CMA, Preview, GraphQL, asset delivery)                                | `tracedContentful(api:, operation:, invoke:)`                                                 |
| `otel_copper`          | Copper CRM (people, companies, opportunities, leads, activities, projects, tasks)      | `tracedCopper(operation:, invoke:)`                                                           |
| `otel_cronofy`         | Cronofy (calendar abstraction, availability, scheduling, real-time scheduler...        | `tracedCronofy(operation:, invoke:)`                                                          |
| `otel_crowdin`         | Crowdin localization (projects, files, strings, translations, MT engines)              | `tracedCrowdin(operation:, invoke:)`                                                          |
| `otel_deel`            | Deel (global contractor and EOR payments, contracts, invoices)                         | `tracedDeel(operation:, invoke:)`                                                             |
| `otel_docusign`        | DocuSign eSignature REST v2.1 (envelopes, recipients, templates, bulk send)            | `tracedDocusign(operation:, invoke:)`                                                         |
| `otel_dropbox`         | Dropbox API (files, sharing, users)                                                    | `tracedDropbox(endpoint:, invoke:)`                                                           |
| `otel_dropbox_sign`    | Dropbox Sign (formerly HelloSign): signature requests, templates, team, OAuth          | `tracedDropboxSign(operation:, invoke:)`                                                      |
| `otel_duffel`          | Duffel (flight booking and ancillaries)                                                | `tracedDuffel(operation:, invoke:)`                                                           |
| `otel_epic_fhir`       | Epic FHIR APIs                                                                         | `tracedEpicFhir(operation:, invoke:)`                                                         |
| `otel_featurebase`     | Featurebase (customer feedback and roadmap)                                            | `tracedFeaturebase(operation:, invoke:)`                                                      |
| `otel_fillout`         | Fillout (forms and workflows)                                                          | `tracedFillout(operation:, invoke:)`                                                          |
| `otel_freshdesk`       | Freshdesk customer support API                                                         | `tracedFreshdesk(resource:, action:, domain:, invoke:)`                                       |
| `otel_github`          | GitHub REST and GraphQL API                                                            | `tracedGithubRest(endpoint:, invoke:)`, `tracedGithubGraphql(operationName:, invoke:)`        |
| `otel_gitlab`          | GitLab REST and GraphQL API                                                            | `tracedGitlab(resource:, action:, invoke:)`                                                   |
| `otel_google_calendar` | Google Calendar API (events, freebusy, calendars, ACL, watches)                        | `tracedGoogleCalendar(operation:, invoke:)`                                                   |
| `otel_greenhouse`      | Greenhouse recruiting (candidates, applications, jobs, scorecards, offers)             | `tracedGreenhouse(operation:, invoke:)`                                                       |
| `otel_helpscout`       | Help Scout Mailbox API v2 (conversations, customers, mailboxes, workflows, reports)    | `tracedHelpscout(operation:, invoke:)`                                                        |
| `otel_hubspot`         | HubSpot CRM API (contacts, deals, companies)                                           | `tracedHubspot(objectType:, action:, invoke:)`                                                |
| `otel_hunter_io`       | Hunter.io email finder and verifier (search, find, verify, credits)                    | `tracedHunterIo(operation:, invoke:)`                                                         |
| `otel_hygraph`         | Hygraph (GraphQL-first headless CMS, content stages, locales, mutations)               | `tracedHygraph(operationName:, invoke:)`                                                      |
| `otel_jira`            | Atlassian Jira Cloud REST API                                                          | `tracedJira(resource:, action:, site:, invoke:)`                                              |
| `otel_jotform`         | Jotform (form builder)                                                                 | `tracedJotform(operation:, invoke:)`                                                          |
| `otel_klaviyo`         | Klaviyo events and profile updates                                                     | `OTelKlaviyo`                                                                                 |
| `otel_lever`           | Lever recruiting CRM (opportunities, postings, interviews, requisitions)               | `tracedLever(operation:, invoke:)`                                                            |
| `otel_linear`          | Linear GraphQL API                                                                     | `tracedLinear(operationName:, invoke:)`                                                       |
| `otel_lokalise`        | Lokalise (projects, keys, translations, tasks, screenshots)                            | `tracedLokalise(operation:, invoke:)`                                                         |
| `otel_marketo`         | Adobe Marketo Engage (marketing automation)                                            | `tracedMarketo(operation:, invoke:)`                                                          |
| `otel_maxmind`         | MaxMind GeoIP2 / GeoLite2 (country, city, ASN, anonymous IP, ISP)                      | `tracedMaxmind(database:, invoke:)`                                                           |
| `otel_monday`          | Monday.com (boards, items, updates, GraphQL queries and mutations, complexity budgets) | `tracedMonday(operationName:, invoke:)`                                                       |
| `otel_notion`          | Notion API (databases, pages, blocks)                                                  | `tracedNotion(resource:, action:, invoke:)`                                                   |
| `otel_oracle_netsuite` | Oracle NetSuite (ERP)                                                                  | `tracedOracleNetSuite(operation:, invoke:)`                                                   |
| `otel_outreach`        | Outreach sales engagement (sequences, prospects, mailings, tasks, calls)               | `tracedOutreach(operation:, invoke:)`                                                         |
| `otel_pandadoc`        | PandaDoc (documents, templates, payments, content library, workspaces)                 | `tracedPandadoc(operation:, invoke:)`                                                         |
| `otel_pardot`          | Salesforce Marketing Cloud Account Engagement (formerly Pardot)                        | `tracedPardot(operation:, invoke:)`                                                           |
| `otel_payload`         | Payload CMS (TS-native, REST and GraphQL and local API, collections, drafts, versions) | `tracedPayload(operation:, invoke:)`                                                          |
| `otel_phrase`          | Phrase localization (projects, keys, translations, jobs, branches)                     | `tracedPhrase(operation:, invoke:)`                                                           |
| `otel_pipedrive`       | Pipedrive CRM (deals, persons, organizations, activities, leads, products, pipelines)  | `tracedPipedrive(operation:, invoke:)`                                                        |
| `otel_prismic`         | Prismic (REST API v2, GraphQL, repository refs, releases)                              | `tracedPrismic(operation:, invoke:)`                                                          |
| `otel_productboard`    | Productboard product feedback (notes, features, components, products)                  | `tracedProductboard(operation:, invoke:)`                                                     |
| `otel_quickbooks`      | QuickBooks Online (SMB accounting)                                                     | `tracedQuickBooks(operation:, invoke:)`                                                       |
| `otel_recruitee`       | Recruitee (recruiting / ATS)                                                           | `tracedRecruitee(operation:, invoke:)`                                                        |
| `otel_redox`           | Redox (healthcare interop, FHIR)                                                       | `tracedRedox(operation:, invoke:)`                                                            |
| `otel_retool`          | Retool internal tools (apps, queries, workflows, runs)                                 | `tracedRetool(operation:, invoke:)`                                                           |
| `otel_rippling`        | Rippling (unified HR+IT+Finance: employees, devices, apps, payroll, expenses)          | `tracedRippling(operation:, invoke:)`                                                         |
| `otel_salesforce`      | Salesforce sObject REST and SOQL/Bulk API                                              | `tracedSalesforceSobject(sobject:, action:, invoke:)`, `tracedSalesforceSoql(soql:, invoke:)` |
| `otel_salesloft`       | SalesLoft sales engagement (cadences, people, mailings, calls)                         | `tracedSalesloft(operation:, invoke:)`                                                        |
| `otel_sanity`          | Sanity (GROQ queries, datasets, drafts, mutations, listen, assets)                     | `tracedSanity(operation:, invoke:)`                                                           |
| `otel_savvycal`        | SavvyCal (links, scheduled events, ranked availability, polls, webhooks)               | `tracedSavvycal(operation:, invoke:)`                                                         |
| `otel_servicenow`      | ServiceNow Table API and Now Platform                                                  | `tracedServicenowTable(table:, action:, instance:, invoke:)`                                  |
| `otel_signnow`         | SignNow (documents, invites, signatures, templates, folders, teams)                    | `tracedSignnow(operation:, invoke:)`                                                          |
| `otel_sportradar`      | Sportradar (sports data APIs)                                                          | `tracedSportradar(operation:, invoke:)`                                                       |
| `otel_storyblok`       | Storyblok (CDN delivery, draft/published, links resolution, GraphQL)                   | `tracedStoryblok(operation:, invoke:)`                                                        |
| `otel_strapi`          | Strapi headless CMS (REST and GraphQL, content-types, plugins, media)                  | `tracedStrapi(operation:, invoke:)`                                                           |
| `otel_tally`           | Tally forms (forms, submissions, integrations, payments)                               | `tracedTally(operation:, invoke:)`                                                            |
| `otel_trello`          | Trello (kanban task mgmt)                                                              | `tracedTrello(operation:, invoke:)`                                                           |
| `otel_trustpilot`      | Trustpilot reviews (business units, reviews, invitations, replies)                     | `tracedTrustpilot(operation:, invoke:)`                                                       |
| `otel_typeform`        | Typeform (forms, responses, webhooks, themes)                                          | `tracedTypeform(operation:, invoke:)`                                                         |
| `otel_workable`        | Workable (recruiting / ATS)                                                            | `tracedWorkable(operation:, invoke:)`                                                         |
| `otel_workday`         | Workday (HCM REST and RaaS reports, workers, time off, compensation)                   | `tracedWorkday(operation:, invoke:)`                                                          |
| `otel_xero`            | Xero (SMB accounting)                                                                  | `tracedXero(operation:, invoke:)`                                                             |
| `otel_yext`            | Yext local listings and answers (entities, publishers, listings, search)               | `tracedYext(operation:, invoke:)`                                                             |
| `otel_yotpo`           | Yotpo reviews and UGC (products, reviews, questions, loyalty points)                   | `tracedYotpo(operation:, invoke:)`                                                            |
| `otel_zoho_crm`        | Zoho CRM (records, modules, related lists, mass updates, blueprints, bulk read/write)  | `tracedZohoCrm(operation:, invoke:)`                                                          |
| `otel_zoominfo`        | ZoomInfo (B2B sales and marketing intelligence)                                        | `tracedZoomInfo(operation:, invoke:)`                                                         |
