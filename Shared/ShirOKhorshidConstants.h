/*
 * Shir o Khorshid - iOS Psiphon Fork
 * Constants and build-time configuration.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Conduit compartment ID for private relay pairing.
// Set via build configuration (xcconfig) or override here.
#ifndef SHIR_CONDUIT_COMPARTMENT_ID
#define SHIR_CONDUIT_COMPARTMENT_ID @""
#endif

// Censored country codes for proxy rejection
extern NSArray<NSString *> *ShirCensoredCountryCodes(void);

// Darwin notification for settings changes
extern NSString *const ShirSettingsChangedNotification;

NS_ASSUME_NONNULL_END
