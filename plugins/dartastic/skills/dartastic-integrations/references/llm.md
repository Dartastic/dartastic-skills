# LLM calls

Instrument every call to a model, wherever it is made (the app, a
server, a function), with one `CLIENT` span per call and a duration
metric, using the OpenTelemetry GenAI conventions.

## Use the package when there is one

The catalog has packages for most model APIs: `otel_openai`,
`otel_anthropic`, `otel_google_ai`, `otel_vertex_ai`, `otel_aws_bedrock`,
`otel_azure_openai`, `otel_mistral`, `otel_groq`, `otel_cohere`,
`otel_langchain` and more (the "AI, LLMs, speech and documents" section
of `catalog.md`). Most offer a drop-in on the client, such as
`client.chat.completions.createTraced(request)` in place of `create`, or a
`traced...(request:, invoke:)` helper. They create the span with its
GenAI attributes. They don't record the duration metric, so add the
histogram from "A wrapper for any provider" below around them.

When pub cannot find the package yet, or the app calls a model some other
way, write the wrapper below.

The GenAI conventions now live in their own OpenTelemetry repository, so
the SDK's `GenAi` enum is deprecated. Until the SDK carries their new
home, declare the keys once in the app, with the convention's exact
names, and use them everywhere:

```dart
/// OpenTelemetry GenAI convention keys (semantic-conventions-genai).
enum GenAiKey implements OTelSemantic {
  providerName('gen_ai.provider.name'),
  operationName('gen_ai.operation.name'),
  requestModel('gen_ai.request.model'),
  requestMaxTokens('gen_ai.request.max_tokens'),
  requestTemperature('gen_ai.request.temperature'),
  responseModel('gen_ai.response.model'),
  responseId('gen_ai.response.id'),
  responseFinishReasons('gen_ai.response.finish_reasons'),
  usageInputTokens('gen_ai.usage.input_tokens'),
  usageOutputTokens('gen_ai.usage.output_tokens'),
  toolName('gen_ai.tool.name'),
  inputMessages('gen_ai.input.messages'),
  outputMessages('gen_ai.output.messages');

  const GenAiKey(this.key);
  @override
  final String key;
}
```

## What to record

| What                 | Key                                                        | Notes                                                                                                |
|----------------------|------------------------------------------------------------|------------------------------------------------------------------------------------------------------|
| Provider             | `GenAiKey.providerName`                                    | `openai`, `anthropic`, `gcp.gemini`, `gcp.vertex_ai`, `aws.bedrock`, `azure.ai.openai`, `mistral_ai` |
| Operation            | `GenAiKey.operationName`                                   | `chat`, `generate_content`, `embeddings`, `execute_tool`, `invoke_agent`                             |
| Requested model      | `GenAiKey.requestModel`                                    | As sent: `gpt-4.1`, `claude-opus-5-5`                                                                |
| Model that answered  | `GenAiKey.responseModel`                                   | From the response                                                                                    |
| Response id          | `GenAiKey.responseId`                                      | When the provider returns one                                                                        |
| Finish reasons       | `GenAiKey.responseFinishReasons`                           | A list: `['stop']`                                                                                   |
| Tokens in and out    | `GenAiKey.usageInputTokens`, `GenAiKey.usageOutputTokens`  | From the response's usage                                                                            |
| Settings that matter | `GenAiKey.requestMaxTokens`, `GenAiKey.requestTemperature` | Only when set                                                                                        |
| Error                | `ErrorAttributes.errorType`                                | The provider's error code or the exception type                                                      |

The span name is `<operation> <model>`: `chat gpt-4.1`.

**Prompts and responses are not recorded by default.** They often hold
personal data, and they are large. Record them only if the developer asks
for it and the data allows, using `GenAiKey.inputMessages` and
`GenAiKey.outputMessages`, and say so in the app's privacy notes.

## A wrapper for any provider

Put this beside the app's AI client, and route every call through it:

```dart
final _tracer = DOTel.tracer('ai');
final _duration = DOTel.meter('ai')
    .createHistogramFor<double>(RegistryMetric.genAiClientOperationDuration);

/// The usage a provider's response reports.
typedef GenAiUsage = ({String? responseModel, String? responseId,
    List<String> finishReasons, int? inputTokens, int? outputTokens});

Future<T> tracedChat<T>({
  required String provider, // a convention value: 'openai', 'gcp.vertex_ai', ...
  required String model,
  required Future<T> Function() call,
  required GenAiUsage Function(T response) usage,
}) async {
  final base = DOTel.attributesFromSemanticMap({
    GenAiKey.providerName: provider,
    GenAiKey.operationName: 'chat',
    GenAiKey.requestModel: model,
  });
  final watch = Stopwatch()..start();
  final span = _tracer.startSpan('chat $model', kind: SpanKind.client, attributes: base);
  var attrs = base;
  try {
    final response = await DOTel.withSpanAsync(span, call);
    final u = usage(response);
    span.addAttributes(DOTel.attributesFromSemanticMap({
      GenAiKey.responseModel: ?u.responseModel,
      GenAiKey.responseId: ?u.responseId,
      if (u.finishReasons.isNotEmpty) GenAiKey.responseFinishReasons: u.finishReasons,
      GenAiKey.usageInputTokens: ?u.inputTokens,
      GenAiKey.usageOutputTokens: ?u.outputTokens,
    }));
    return response;
  } catch (e, s) {
    attrs = attrs.copyWithStringAttribute(
        ErrorAttributes.errorType.key, e.runtimeType.toString());
    span.recordException(e, stackTrace: s);
    span.setStatus(SpanStatusCode.Error, e.runtimeType.toString());
    rethrow;
  } finally {
    span.end();
    _duration.record(watch.elapsedMicroseconds / 1e6, attrs);
  }
}
```

Use it with the provider's SDK, here Firebase AI (`firebase_ai`) on
Vertex AI:

```dart
final reply = await tracedChat(
  provider: 'gcp.vertex_ai',
  model: 'gemini-2.5-flash',
  call: () => model.generateContent([Content.text(prompt)]),
  usage: (r) => (
    responseModel: null,
    responseId: null,
    finishReasons: [for (final c in r.candidates) ?c.finishReason?.name],
    inputTokens: r.usageMetadata?.promptTokenCount,
    outputTokens: r.usageMetadata?.candidatesTokenCount,
  ),
);
```

Map each SDK's response fields into the record the same way. Read the
SDK's response type rather than guessing the field names.

Notes:

- Metric attributes stay low-cardinality: provider, operation, model and
  error type only. Never put a prompt, a user id or a response id on the
  metric.
- **Streaming**: start the span when the request is sent, end it when the
  stream ends (or fails, or is canceled), and set the token counts from
  the final chunk's usage.
- **Tools and agents**: a tool the model asks the app to run is its own
  span, `execute_tool <tool name>`, with `GenAiKey.toolName`, as a child
  of the chat span or of the agent step that requested it.
- **Server-side calls**: when the app calls the developer's own backend,
  which calls the model, instrument the model call on the backend; the
  app's HTTP span and the backend's chat span join in one trace.
- **Cost**: count tokens, not money. Prices change; tokens with the model
  name let cost be computed later.
