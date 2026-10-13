#include "SGAutoMixCore.h"

#include <assert.h>
#include <math.h>
#include <stdio.h>

static bool nearlyEqual(float first, float second) {
    return fabsf(first - second) < 0.0001f;
}

int main(void) {
    SGAutoMixConfiguration configuration = SGAutoMixConfigurationDefault();
    assert(configuration.enabled);
    assert(nearlyEqual((float)configuration.crossfadeSeconds, 6.0f));

    SGAutoMixPlan plan;
    assert(!SGAutoMixBuildPlan(configuration, 240.0, false, 7, &plan));
    assert(plan.phase == SGAutoMixPhaseIdle);
    assert(!SGAutoMixBuildPlan(configuration, 10.0, true, 7, &plan));

    assert(SGAutoMixBuildPlan(configuration, 240.0, true, 42, &plan));
    assert(plan.phase == SGAutoMixPhaseArmed);
    assert(nearlyEqual((float)plan.startSeconds, 234.0f));
    assert(nearlyEqual((float)plan.endSeconds, 240.0f));
    assert(plan.generation == 42);

    SGAutoMixGains start = SGAutoMixGainsForPosition(&plan, 234.0);
    SGAutoMixGains midpoint = SGAutoMixGainsForPosition(&plan, 237.0);
    SGAutoMixGains end = SGAutoMixGainsForPosition(&plan, 240.0);
    assert(nearlyEqual(start.outgoing, 1.0f) && nearlyEqual(start.incoming, 0.0f));
    assert(nearlyEqual(midpoint.outgoing, 0.70710678f));
    assert(nearlyEqual(midpoint.incoming, 0.70710678f));
    assert(nearlyEqual(end.outgoing, 0.0f) && nearlyEqual(end.incoming, 1.0f));

    SGAutoMixCancel(&plan);
    assert(plan.phase == SGAutoMixPhaseIdle);
    puts("SGAutoMixCore tests passed");
    return 0;
}
