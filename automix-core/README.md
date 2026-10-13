# SGAutoMixCore

`SGAutoMixCore` is an original, standalone C transition planner for an audio
application. It creates conservative equal-power crossfade plans, supplies the
two gain envelopes, and makes cancellation explicit when a playback session or
queue changes.

It is intentionally **not** wired into Spotify or a private dylib. A real
adapter must supply a legal, verified playback API that can:

1. identify the currently rendering item and its duration;
2. prefetch and decode the next item as a separate renderable stream;
3. apply `SGAutoMixGains` to both streams on the same audio clock; and
4. cancel the plan on seek, queue change, playback error, or session reset.

Until an adapter can meet all four requirements, the library must not advertise
AutoMix as active. It does not patch authentication, entitlement checks, or
private playback code.

## Build and test

```sh
cc -std=c11 -Wall -Wextra -Werror -Iinclude src/SGAutoMixCore.c \
  tests/test_automix_core.c -lm -o automix-core-tests
./automix-core-tests
```

The repository CI runs this exact test on every push affecting this directory.
