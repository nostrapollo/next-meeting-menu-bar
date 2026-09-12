# Optional PineTime relay

This personal integration requires a local watch API at `http://127.0.0.1:8787`,
an ntfy Android subscription forwarded by Gadgetbridge, and custom InfiniTime
firmware that understands `[MEET]startEpoch,endEpoch,title` and `[MEET]clear`.
Stock InfiniTime will only show these as notifications.

The relay is disabled by default. After the API and custom firmware are ready:

```sh
defaults write com.nextmeeting.app pineTimeRelayEnabled -bool true
```

Restart NextMeeting after changing this preference. Disable with the same command
using `false`. Disabling stops future sends; the last event on the watch expires at
its end time. Send `{"clear":true}` to the API before disabling to clear immediately.

The relay sends the next upcoming event, falling back to an ongoing event, and
clears when none remain. The API receives `startEpoch`, `endEpoch`, and `title`
in JSON, or `{"clear":true}`. It normalizes the title to at most 31 printable ASCII
bytes. Updates remain normal notifications and may buzz. Calendar edits follow
the selected calendar refresh interval. The watch counts down locally.

Requests are serialized and unchanged payloads are suppressed after HTTP success.
Failures retry after 30 seconds. A successful HTTP response means the API accepted
the request, not that the watch received it. There is no watch acknowledgement;
missed forwarding can leave the watch stale until a subsequent change or restart.

The Mac and local API must remain awake to send new events. After a successful
transfer, the watch can count down without the Mac. Keep the Pixel near the watch;
Gadgetbridge can suppress forwarding while the phone screen is on.

Enabling this feature sends meeting titles and times through the configured ntfy
service. Keep the topic secret and store it in the local API configuration, never
in this repository. Do not expose the local API port to the internet.

Validation: `./test.sh` covers meeting selection and payload stability. An actual
Pixel/Gadgetbridge/custom-firmware round trip is still required before relying on it.
