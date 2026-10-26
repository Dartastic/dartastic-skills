---
name: dartastic-webviews
description: Capture telemetry from web pages shown inside a Flutter app's WebView with Dartastic's DartasticWebviewBridge, so page errors, page network calls and page load timing land in the same session as the app - for webview_flutter and flutter_inappwebview. Use this whenever a Flutter app embeds a WebView, WebViewWidget, InAppWebView, a hosted checkout, a help center, an OAuth page or any hybrid screen, and someone asks why those screens are a blind spot, how to see errors inside the WebView, or how to connect a page's requests to the backend.
---

# WebViews with Dartastic

Without the bridge, a WebView is a hole in the session: the user is on
the checkout page, it fails, and the telemetry shows nothing. The bridge
injects a small script into allowed pages. That script reports the page's
errors, its fetch and XHR calls, and its load timing back to the app over
the WebView's message channel. The app validates every event and sends it
with the app's own telemetry, stamped `dartastic.telemetry.source=webview`.
The page never holds a token or sees an endpoint.

## Configure the bridge

```dart
final bridge = DartasticWebviewBridge(
  allowedHosts: ['checkout.example.com', 'example.com'],
  serviceName: 'web-checkout',
  transport: DartasticWebviewTransport.javaScriptChannel, // webview_flutter
);
```

- `allowedHosts` are bare lowercase hosts. A page matches its exact host
  or a subdomain. No schemes, ports, paths or wildcards (they throw), and
  an empty list keeps the bridge off. **List only hosts the developer
  controls or trusts**: whatever an allowed page sends travels as the
  app's telemetry.
- `serviceName` names the web component (`web-checkout`), so its spans are
  told apart from the app's.
- Create the bridge after `DOTel.initialize`. It is part of the Pro SDK
  and stays inert without a license.

## webview_flutter (4.9.0 or later)

```dart
controller
  // Required on Android: the default JavaScript mode is disabled, and
  // without it there is no channel and no bridge.
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..addJavaScriptChannel(
    bridge.channelName,
    onMessageReceived: (m) => bridge.handleMessage(m.message),
  )
  ..setNavigationDelegate(NavigationDelegate(
    onPageStarted: (url) {
      final shim = bridge.shimForUrl(url);
      if (shim != null) controller.runJavaScript(shim);
    },
  ));

// When the WebView screen is disposed:
bridge.notifyPageEnded();
```

Injection on `onPageStarted` is early but not first: the page's own
inline scripts can run before it, so the first milliseconds of errors can
be missed. If those matter, use flutter_inappwebview, which injects at
document start.

## flutter_inappwebview (6.1.5 or later)

```dart
InAppWebView(
  initialUrlRequest: URLRequest(url: WebUri('https://checkout.example.com/')),
  // Installed once; captures from document start and holds events until
  // the page is armed in onLoadStart.
  initialUserScripts: UnmodifiableListView([
    if (bridge.shimSource case final source?)
      UserScript(
        source: source,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        forMainFrameOnly: true,
      ),
  ]),
  onWebViewCreated: (controller) {
    controller.addJavaScriptHandler(
      handlerName: bridge.channelName,
      callback: (args) =>
          bridge.handleMessage(args.isEmpty ? '' : args.first as String),
    );
  },
  // Exactly once per document, here and nowhere else.
  onLoadStart: (controller, url) async {
    if (url == null) return;
    final source = bridge.shimForUrl(url.toString());
    if (source != null) await controller.evaluateJavascript(source: source);
  },
)
```

With this package, use
`transport: DartasticWebviewTransport.inAppWebViewHandler`.

## What arrives

| Captured                                                    | Where                |
|-------------------------------------------------------------|----------------------|
| Window errors and unhandled promise rejections              | Every platform       |
| fetch and XHR as client spans (no bodies, no query strings) | Every platform       |
| Time to first byte, first contentful paint                  | Every platform       |
| LCP, CLS, INP, long tasks                                   | Android WebView only |

Page stacks are the page's own minified JavaScript and are not
symbolized. Responses of 400 or more mark the span as an error.

## The page's own signals

Pages that the developer owns can add their own, through
`window.dartastic`:

```js
// log(severity, body, attributes): severity is debug, info, warn or error
window.dartastic?.log('info', 'coupon applied', {'checkout.coupon': 'SPRING'});

// error(message, type, stack, attributes)
try { loadPaymentForm(); } catch (e) {
  window.dartastic?.error(e.message, e.name, e.stack, {'checkout.step': 'card'});
}

// span(name, startMs, endMs, attributes): times from Date.now()
const start = Date.now();
await renderQuote();
window.dartastic?.span('checkout.render_quote', start, Date.now());
```

The page's attribute keys must stay in the page's own namespace. Events
that claim app keys (`session.*`, `service.*`, `app.*`, `device.*`,
`os.*`, `user.*`, `exception.*`, `dartastic.*`) are rejected whole.

## Joining the page's requests to the backend

Each page load gets a trace of its own; it is not a child of the app's
current span. The bridge does not add trace headers to the page's own
requests. To join a page's backend call to the page's trace, the page
reads `window.dartastic.traceparent` when it makes the call (not once at
load, because it becomes available moments after document start) and
sends it:

```js
const tp = window.dartastic?.traceparent;
await fetch('/api/pay', {
  method: 'POST',
  headers: {'content-type': 'application/json', ...(tp ? {traceparent: tp} : {})},
  body: JSON.stringify(order),
});
```

The backend then continues the trace like any other (see
`dartastic-distributed-tracing`), and must allow the `traceparent` header
in CORS if the call is cross-origin.

## Check it

Open the WebView screen, trigger an error on the page, then with
`dartastic-verify-telemetry` search the session's logs for
`dartastic.telemetry.source = webview` and confirm the page error and its
requests arrived in the same session as the app's screens.
