/*
 * Shir o Khorshid - iOS Psiphon Fork
 * Constants implementation.
 */

#import "ShirOKhorshidConstants.h"

NSArray<NSString *> *ShirCensoredCountryCodes(void) {
    return @[@"IR", @"CN", @"RU", @"BY", @"TM", @"KP"];
}

NSString *const ShirSettingsChangedNotification = @"com.shirokhorshid.vpn.settingsChanged";
