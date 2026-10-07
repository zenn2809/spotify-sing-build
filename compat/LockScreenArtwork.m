// iOS 18 SDK-compatible implementation of optional iOS 26 animated artwork.
// The symbols are resolved at runtime so older SDKs can build this target.
#import <MediaPlayer/MediaPlayer.h>
#import <objc/message.h>
#import "LockScreenArtwork.h"

NSString *const SGArtworkSourceSpotify = @"spotify";
NSString *const SGArtworkSourceApple = @"applemusic";

NSArray<NSString *> *SGArtworkOrder(void) {
    id stored = [NSUserDefaults.standardUserDefaults arrayForKey:SGKeyLockScreenArtworkSources];
    NSArray *keys = [stored isKindOfClass:NSArray.class] ? stored : @[SGArtworkSourceSpotify, SGArtworkSourceApple];
    NSMutableArray<NSString *> *order = [NSMutableArray array];
    for (id key in keys) {
        BOOL known = [key isEqual:SGArtworkSourceSpotify] || [key isEqual:SGArtworkSourceApple];
        if (known && ![order containsObject:key]) [order addObject:key];
    }
    return order;
}

void SGArtworkSetOrder(NSArray<NSString *> *order) {
    [NSUserDefaults.standardUserDefaults setObject:order ?: @[] forKey:SGKeyLockScreenArtworkSources];
}

BOOL SGAnimatedArtworkAvailable(void) {
    if (@available(iOS 26.0, *)) return NSClassFromString(@"MPMediaItemAnimatedArtwork") != nil;
    return NO;
}

NSArray<NSString *> *SGAnimatedArtworkKeys(void) {
    if (!SGAnimatedArtworkAvailable()) return nil;
    SEL selector = NSSelectorFromString(@"supportedAnimatedArtworkKeys");
    Class center = [MPNowPlayingInfoCenter class];
    if (![center respondsToSelector:selector]) return nil;
    return ((id (*)(id, SEL))objc_msgSend)(center, selector);
}

NSString *SGAnimatedArtworkKey(CGFloat *aspect) {
    NSArray<NSString *> *supported = SGAnimatedArtworkKeys();
    NSString *tall = @"MPNowPlayingInfoProperty3x4AnimatedArtwork";
    NSString *square = @"MPNowPlayingInfoProperty1x1AnimatedArtwork";
    if ([supported containsObject:tall]) {
        if (aspect) *aspect = 3.0 / 4.0;
        return tall;
    }
    if ([supported containsObject:square]) {
        if (aspect) *aspect = 1;
        return square;
    }
    return nil;
}

NSDictionary *SGArtworkInInfo(NSDictionary *info, id artwork, NSString *key) {
    if (!info.count || !artwork || !key.length) return info;
    if (info[key] == artwork) return info;
    NSMutableDictionary *shown = [info mutableCopy];
    shown[key] = artwork;
    return shown;
}
