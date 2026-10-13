#ifndef SG_AUTOMIX_CORE_H
#define SG_AUTOMIX_CORE_H

#include <stdbool.h>
#include <stdint.h>

/*
 * A small, platform-neutral transition planner.  It does not fetch, decode,
 * prebuffer, or render audio: the host application owns those operations.
 */
typedef enum {
    SGAutoMixPhaseIdle = 0,
    SGAutoMixPhaseArmed,
    SGAutoMixPhaseFading
} SGAutoMixPhase;

typedef struct {
    bool enabled;
    double crossfadeSeconds;
    double minimumTrackSeconds;
} SGAutoMixConfiguration;

typedef struct {
    SGAutoMixPhase phase;
    double startSeconds;
    double endSeconds;
    uint64_t generation;
} SGAutoMixPlan;

typedef struct {
    float outgoing;
    float incoming;
} SGAutoMixGains;

/* A conservative six-second equal-power crossfade configuration. */
SGAutoMixConfiguration SGAutoMixConfigurationDefault(void);

/*
 * Creates a plan only when a next item has already been prepared by the host.
 * generation is a host-provided monotonic token; invalidate/cancel the plan
 * whenever the queue, current item, or playback session changes.
 */
bool SGAutoMixBuildPlan(SGAutoMixConfiguration configuration,
                        double currentDurationSeconds,
                        bool nextItemPrepared,
                        uint64_t generation,
                        SGAutoMixPlan *outPlan);

/* Returns equal-power gains for a valid plan at the supplied playhead time. */
SGAutoMixGains SGAutoMixGainsForPosition(const SGAutoMixPlan *plan,
                                         double positionSeconds);

/* Invalidates a plan after seek, pause/error recovery, or queue changes. */
void SGAutoMixCancel(SGAutoMixPlan *plan);

#endif
