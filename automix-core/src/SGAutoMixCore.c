#include "SGAutoMixCore.h"

#include <math.h>
#include <stddef.h>

static const double SGAutoMixHalfPi = 1.57079632679489661923;

SGAutoMixConfiguration SGAutoMixConfigurationDefault(void) {
    SGAutoMixConfiguration configuration = {
        .enabled = true,
        .crossfadeSeconds = 6.0,
        .minimumTrackSeconds = 12.0,
    };
    return configuration;
}

static bool SGAutoMixConfigurationIsValid(SGAutoMixConfiguration configuration) {
    return configuration.enabled && isfinite(configuration.crossfadeSeconds) &&
           isfinite(configuration.minimumTrackSeconds) &&
           configuration.crossfadeSeconds > 0.0 &&
           configuration.minimumTrackSeconds > 0.0;
}

bool SGAutoMixBuildPlan(SGAutoMixConfiguration configuration,
                        double currentDurationSeconds,
                        bool nextItemPrepared,
                        uint64_t generation,
                        SGAutoMixPlan *outPlan) {
    if (outPlan == NULL) {
        return false;
    }

    SGAutoMixCancel(outPlan);
    if (!SGAutoMixConfigurationIsValid(configuration) || !nextItemPrepared ||
        !isfinite(currentDurationSeconds) ||
        currentDurationSeconds < configuration.minimumTrackSeconds) {
        return false;
    }

    /* Never use more than one quarter of a track as a crossfade. */
    const double fadeSeconds = fmin(configuration.crossfadeSeconds,
                                    currentDurationSeconds * 0.25);
    if (fadeSeconds <= 0.0 || fadeSeconds >= currentDurationSeconds) {
        return false;
    }

    outPlan->phase = SGAutoMixPhaseArmed;
    outPlan->startSeconds = currentDurationSeconds - fadeSeconds;
    outPlan->endSeconds = currentDurationSeconds;
    outPlan->generation = generation;
    return true;
}

SGAutoMixGains SGAutoMixGainsForPosition(const SGAutoMixPlan *plan,
                                         double positionSeconds) {
    SGAutoMixGains gains = { .outgoing = 1.0f, .incoming = 0.0f };
    if (plan == NULL || plan->phase == SGAutoMixPhaseIdle ||
        !isfinite(positionSeconds) || plan->endSeconds <= plan->startSeconds) {
        return gains;
    }

    if (positionSeconds >= plan->endSeconds) {
        gains.outgoing = 0.0f;
        gains.incoming = 1.0f;
        return gains;
    }
    if (positionSeconds <= plan->startSeconds) {
        return gains;
    }

    const double progress = (positionSeconds - plan->startSeconds) /
                            (plan->endSeconds - plan->startSeconds);
    gains.outgoing = (float)cos(progress * SGAutoMixHalfPi);
    gains.incoming = (float)sin(progress * SGAutoMixHalfPi);
    return gains;
}

void SGAutoMixCancel(SGAutoMixPlan *plan) {
    if (plan == NULL) {
        return;
    }
    plan->phase = SGAutoMixPhaseIdle;
    plan->startSeconds = 0.0;
    plan->endSeconds = 0.0;
    plan->generation = 0;
}
