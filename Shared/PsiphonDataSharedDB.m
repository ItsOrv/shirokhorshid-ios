/*
 * Copyright (c) 2017, Psiphon Inc.
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "PsiphonDataSharedDB.h"
#import "Logging.h"
#import "NSDate+PSIDateExtension.h"
#import "SharedConstants.h"
#import "FileUtils.h"
#import "Archiver.h"
#import <PsiphonTunnel/PsiphonTunnel.h>

#pragma mark - NSUserDefaults Keys

UserDefaultsKey const EgressRegionsStringArrayKey = @"egress_regions";

UserDefaultsKey const ClientRegionStringKey = @"client_region";

UserDefaultsKey const TunnelStartTimeStringKey = @"tunnel_start_time";

UserDefaultsKey const TunnelSponsorIDStringKey = @"current_sponsor_id";

UserDefaultsKey const ServerTimestampStringKey = @"server_timestamp";

UserDefaultsKey const ExtensionVPNSessionNumberIntKey = @"extension_vpn_session_number";

UserDefaultsKey const ExtensionApplicationParametersDataKey = @"server_application_parameters_data";

UserDefaultsKey const ConstainerPurchaseRequiredVPNSessionHandledIntKey =
@"container_purchase_required_handled_vpn_session_num";

UserDefaultsKey const ExtensionIsZombieBoolKey = @"extension_zombie";

UserDefaultsKey const ExtensionStopReasonIntegerKey = @"extension_stop_reason";

UserDefaultsKey const ContainerSharedDebugFlagsKey = @"SHARED_DEBUG_FLAGS";

UserDefaultsKey const ContainerForegroundStateBoolKey = @"container_foreground_state_bool_key";

UserDefaultsKey const ContainerTunnelIntentStatusIntKey = @"container_tunnel_intent_status_key";

UserDefaultsKey const ExtensionDisallowedTrafficAlertWriteSeqIntKey =
@"extension_disallowed_traffic_alert_write_seq_int";

UserDefaultsKey const ExtensionApplicationParametersChangeTimestamp =
@"extension_application_parameters_timestamp";

UserDefaultsKey const ContainerDisallowedTrafficAlertReadAtLeastUpToSeqIntKey =
@"container_disallowed_traffic_alert_read_at_least_up_to_seq_int";

UserDefaultsKey const TunnelEgressRegionKey = @"Tunnel-EgressRegion";

UserDefaultsKey const TunnelDisableTimeoutsKey = @"Tunnel-Disable-Timeouts";

UserDefaultsKey const TunnelUpstreamProxyURLKey = @"Tunnel-UpstreamProxyURL";

UserDefaultsKey const TunnelCustomHeadersKey = @"Tunnel-CustomHeaders";

// Shir o Khorshid settings keys
UserDefaultsKey const ShirProtocolSelectionKey = @"shir_protocol_selection";
UserDefaultsKey const ShirBeastModeKey = @"shir_beast_mode";
UserDefaultsKey const ShirCdnFrontingCustomIpListKey = @"shir_cdn_fronting_custom_ip_list";
UserDefaultsKey const ShirCdnFrontingCustomSniKey = @"shir_cdn_fronting_custom_sni";
UserDefaultsKey const ShirConduitModeKey = @"shir_conduit_mode";
UserDefaultsKey const ShirConduitTimeoutSecondsKey = @"shir_conduit_timeout_seconds";
UserDefaultsKey const ShirRejectCensoredCountryProxiesKey = @"shir_reject_censored_country_proxies";
UserDefaultsKey const ShirShareProxyOnNetworkKey = @"shir_share_proxy_on_network";
UserDefaultsKey const ShirDisguiseIdentityKey = @"shir_disguise_identity";
UserDefaultsKey const ShirStealthNotificationsKey = @"shir_stealth_notifications";


/**
 * Key for boolean value that when TRUE indicates that the extension crashed before stop was called.
 * This value is only valid if the extension is not currently running.
 *
 * @note This does not indicate whether the extension crashed after the stop was called.
 * @attention This flag is set after the extension is started/stopped.
 */
UserDefaultsKey const SharedDataExtensionCrashedBeforeStopBoolKey = @"PsiphonDataSharedDB.ExtensionCrashedBeforeStopBoolKey";

#if DEBUG || DEV_RELEASE

UserDefaultsKey const DebugMemoryProfileBoolKey = @"PsiphonDataSharedDB.DebugMemoryProfilerBoolKey";
UserDefaultsKey const DebugPsiphonConnectionStateStringKey = @"PsiphonDataSharedDB.DebugPsiphonConnectionStateStringKey";

#endif

#pragma mark - Unused legacy keys
UserDefaultsKey const ContainerAuthorizationSetKey_Legacy = @"authorizations_container_key";

UserDefaultsKey const ContainerSubscriptionAuthorizationsDictKey_Legacy=
    @"subscription_authorizations_dict";

UserDefaultsKey const ExtensionRejectedSubscriptionAuthorizationIDsArrayKey_Legacy =
    @"extension_rejected_subscription_authorization_ids";

UserDefaultsKey const ExtensionRejectedSubscriptionAuthorizationIDsWriteSeqIntKey_Legacy =
@"extension_rejected_subscription_authorization_ids_write_seq_int";

UserDefaultsKey const ContainerRejectedSubscriptionAuthorizationIDsReadAtLeastUpToSeqIntKey_Legacy =
    @"container_read_rejected_subscription_authorization_ids_read_at_least_up_to_seq_int";

UserDefaultsKey const ContainerAppReceiptLatestSubscriptionExpiryDate_Legacy =
@"Container-Latest-Subscription-Expiry-Date";


#pragma mark -

@implementation Homepage
@end

@implementation PsiphonDataSharedDB {

    // NSUserDefaults objects are thread-safe.
    NSUserDefaults *sharedDefaults;

    NSString *appGroupIdentifier;
}

/*!
 * @brief Don't share an instance across threads.
 * @param identifier
 */
- (id)initForAppGroupIdentifier:(NSString*)identifier {
    self = [super init];
    if (self) {
        appGroupIdentifier = identifier;
        sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:identifier];
    }
    return self;
}

#pragma mark - Logging

// See comment in header
+ (NSURL *)dataRootDirectory {
    return [[[NSFileManager defaultManager]
             containerURLForSecurityApplicationGroupIdentifier:PsiphonAppGroupIdentifier]
            URLByAppendingPathComponent:@"com.psiphon3.ios.PsiphonTunnel"];
}

// See comment in header
- (NSString *)oldHomepageNoticesPath {
    return [[[[NSFileManager defaultManager]
            containerURLForSecurityApplicationGroupIdentifier:appGroupIdentifier] path]
            stringByAppendingPathComponent:@"homepage_notices"];
}

// See comment in header
- (NSString *)oldRotatingLogNoticesPath {
    return [[[[NSFileManager defaultManager]
            containerURLForSecurityApplicationGroupIdentifier:appGroupIdentifier] path]
            stringByAppendingPathComponent:@"rotating_notices"];
}

// See comment in header
- (NSString *)homepageNoticesPath {
    return [PsiphonTunnel homepageFilePath:[PsiphonDataSharedDB dataRootDirectory]].path;
}

// See comment in header
- (NSString *)rotatingLogNoticesPath {
    return [PsiphonTunnel noticesFilePath:[PsiphonDataSharedDB dataRootDirectory]].path;
}

// See comment in header
- (NSString *)rotatingOlderLogNoticesPath {
    return [PsiphonTunnel olderNoticesFilePath:[PsiphonDataSharedDB dataRootDirectory]].path;
}

#pragma mark - Tunnel core configs

- (NSString *_Nonnull)getEgressRegion {
    NSString *_Nullable egressRegion = [sharedDefaults stringForKey:TunnelEgressRegionKey];
    if (egressRegion == nil) {
        return kPsiphonRegionBestPerformance;
    }
    return egressRegion;
}

- (void)setEgressRegion:(NSString *_Nullable)regionCode {
    [sharedDefaults setObject:regionCode forKey:TunnelEgressRegionKey];
}

- (void)setDisableTimeouts:(BOOL)disableTimeouts {
    [sharedDefaults setBool:disableTimeouts forKey:TunnelDisableTimeoutsKey];
}

- (void)setUpstreamProxyURL:(NSString *_Nullable)url {
    [sharedDefaults setObject:url forKey:TunnelUpstreamProxyURLKey];
}

- (void)setCustomHttpHeaders:(NSDictionary *_Nullable)customHeaders {
    [sharedDefaults setObject:customHeaders forKey:TunnelCustomHeadersKey];
}

- (NSDictionary *)getTunnelCoreUserConfigs {

    NSMutableDictionary *userConfigs = [[NSMutableDictionary alloc] init];

    NSString *egressRegion = [sharedDefaults stringForKey:TunnelEgressRegionKey];
    if (egressRegion) {
        userConfigs[@"EgressRegion"] = egressRegion;
    }

    if ([sharedDefaults boolForKey:TunnelDisableTimeoutsKey]) {
        userConfigs[@"NetworkLatencyMultiplierLambda"] = @(0.1);
    }

    NSString *upstreamProxyUrl = [sharedDefaults stringForKey:TunnelUpstreamProxyURLKey];
    if (upstreamProxyUrl && [upstreamProxyUrl length] > 0) {
        userConfigs[@"UpstreamProxyUrl"] = upstreamProxyUrl;
    }

    id upstreamProxyCustomHeaders = [sharedDefaults objectForKey:TunnelCustomHeadersKey];
    if ([upstreamProxyCustomHeaders isKindOfClass:[NSDictionary class]]) {
        NSDictionary *customHeaders = (NSDictionary*)upstreamProxyCustomHeaders;
        if ([customHeaders count] > 0) {
            userConfigs[@"CustomHeaders"] = customHeaders;
        }
    }

    // --- Shir o Khorshid: Protocol selection, beast mode, CDN fronting, conduit ---

    NSString *protocolSelection = [self getProtocolSelection];

    // Beast mode: aggressive establishment
    if ([self getBeastMode]) {
        userConfigs[@"AggressiveEstablishment"] = @YES;
    }

    // DNS resolver alternate servers
    userConfigs[@"DNSResolverAlternateServers"] = @[@"1.1.1.1", @"1.0.0.1", @"8.8.8.8", @"8.8.4.4"];

    // Protocol-specific configuration
    if ([protocolSelection isEqualToString:@"conduit"]) {
        userConfigs[@"LimitTunnelProtocols"] = @[
            @"INPROXY-WEBRTC-OSSH",
            @"INPROXY-WEBRTC-UNFRONTED-MEEK-HTTPS-OSSH",
            @"INPROXY-WEBRTC-UNFRONTED-MEEK-SESSION-TICKET-OSSH",
            @"INPROXY-WEBRTC-FRONTED-MEEK-OSSH",
            @"INPROXY-WEBRTC-FRONTED-MEEK-HTTP-OSSH",
            @"INPROXY-WEBRTC-QUIC-OSSH"
        ];

        // Reject proxies from censored countries
        if ([self getRejectCensoredCountryProxies]) {
            userConfigs[@"InproxyRejectProxyCountryCodes"] = @[@"IR", @"CN", @"RU", @"BY", @"TM", @"KP"];
        }

    } else if ([protocolSelection isEqualToString:@"cdn_fronting"]) {
        userConfigs[@"LimitTunnelProtocols"] = @[@"FRONTED-MEEK-CDN-OSSH"];
        userConfigs[@"DisableTactics"] = @YES;

    } else if ([protocolSelection isEqualToString:@"direct"]) {
        userConfigs[@"LimitTunnelProtocols"] = @[
            @"SSH", @"OSSH", @"TLS-OSSH", @"QUIC-OSSH",
            @"SHADOWSOCKS-OSSH", @"FRONTED-MEEK-CDN-OSSH"
        ];
        userConfigs[@"DisableTactics"] = @YES;
    }
    // "auto" mode: don't set LimitTunnelProtocols

    // CDN Fronting overrides (for auto, direct, cdn_fronting modes)
    BOOL enableCdnFronting = [protocolSelection isEqualToString:@"auto"] ||
                             [protocolSelection isEqualToString:@"direct"] ||
                             [protocolSelection isEqualToString:@"cdn_fronting"];
    if (enableCdnFronting) {
        NSArray *overrides = [self buildCdnFrontingDialOverrides];
        if (overrides.count > 0) {
            userConfigs[@"FrontedMeekDialOverrides"] = overrides;
            userConfigs[@"FrontedMeekDialOverridesProbability"] = @(1.0);
        }
    }

    // LAN proxy sharing
    if ([self getShareProxyOnNetwork]) {
        userConfigs[@"ListenInterface"] = @"any";
    }

    return userConfigs;
}

#pragma mark - CDN Fronting Helpers

static const NSInteger kMaxCustomCdnFrontingIPs = 32;

+ (BOOL)isValidIPv4Address:(NSString *)ipAddress {
    NSArray *parts = [ipAddress componentsSeparatedByString:@"."];
    if (parts.count != 4) return NO;
    for (NSString *part in parts) {
        if (part.length == 0 || part.length > 3) return NO;
        NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
        if (![[NSCharacterSet characterSetWithCharactersInString:part] isSubsetOfSet:digits]) return NO;
        NSInteger value = [part integerValue];
        if (value < 0 || value > 255) return NO;
    }
    return YES;
}

+ (BOOL)isValidHostname:(NSString *)hostname {
    if (!hostname || hostname.length == 0 || hostname.length > 253) return NO;
    if ([self isValidIPv4Address:hostname]) return NO;
    NSString *normalized = hostname;
    if ([normalized hasSuffix:@"."]) {
        normalized = [normalized substringToIndex:normalized.length - 1];
    }
    if (normalized.length == 0) return NO;
    NSArray *labels = [normalized componentsSeparatedByString:@"."];
    for (NSString *label in labels) {
        if (label.length == 0 || label.length > 63) return NO;
        if ([label hasPrefix:@"-"] || [label hasSuffix:@"-"]) return NO;
        NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:
            @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-"];
        if (![[NSCharacterSet characterSetWithCharactersInString:label] isSubsetOfSet:allowed]) return NO;
    }
    return YES;
}

+ (NSArray<NSString *> *)parseCdnFrontingCustomIpList:(NSString *)customIpList {
    NSMutableArray *ipAddresses = [NSMutableArray array];
    if (!customIpList || customIpList.length == 0) return ipAddresses;

    NSMutableSet *seen = [NSMutableSet set];
    NSArray *entries = [customIpList componentsSeparatedByCharactersInSet:
        [NSCharacterSet characterSetWithCharactersInString:@" ,;\n\r\t"]];
    for (NSString *entry in entries) {
        NSString *ip = [entry stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (ip.length == 0 || ![self isValidIPv4Address:ip]) continue;
        if (![seen containsObject:ip]) {
            [seen addObject:ip];
            [ipAddresses addObject:ip];
            if ((NSInteger)ipAddresses.count >= kMaxCustomCdnFrontingIPs) break;
        }
    }
    return ipAddresses;
}

+ (NSString *)normalizeCdnFrontingCustomSni:(NSString *)customSni {
    if (!customSni || customSni.length == 0) return @"";
    NSString *sni = [customSni stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (![self isValidHostname:sni]) return @"";
    return sni;
}

- (NSDictionary *)makeCdnFrontingOverrideWithID:(NSString *)overrideID
                   matchFrontingProviderIDRegexes:(NSArray *_Nullable)providerRegexes
                          matchDialAddressRegexes:(NSArray *_Nullable)addressRegexes
                                     dialAddress:(NSString *)dialAddress
                                   sniServerName:(NSString *)sniServerName
                                verifyServerNames:(NSArray *)verifyServerNames
                                   alpnProtocols:(NSArray *)alpnProtocols {
    NSMutableDictionary *override = [NSMutableDictionary dictionary];
    override[@"OverrideID"] = overrideID;
    if (providerRegexes) override[@"MatchFrontingProviderIDRegexes"] = providerRegexes;
    if (addressRegexes) override[@"MatchDialAddressRegexes"] = addressRegexes;
    override[@"DialAddresses"] = @[dialAddress];
    override[@"SNIServerName"] = sniServerName;
    override[@"VerifyServerNames"] = verifyServerNames;
    override[@"ALPNProtocols"] = alpnProtocols;
    override[@"TLSProfile"] = @"Chrome-83";
    return [override copy];
}

- (NSArray *)makeEdgeVerifyServerNamesForIP:(NSString *)ipAddress sni:(NSString *)sniServerName {
    NSMutableArray *names = [NSMutableArray array];
    NSMutableSet *added = [NSMutableSet set];

    void (^addUnique)(NSString *) = ^(NSString *name) {
        if (name.length > 0 && ![added containsObject:name]) {
            [added addObject:name];
            [names addObject:name];
        }
    };

    addUnique(sniServerName);
    addUnique(ipAddress);
    addUnique(@"a248.e.akamai.net");
    addUnique(@"a.akamaized.net");
    addUnique(@"a.akamaized-staging.net");
    addUnique(@"a.akamaihd.net");
    addUnique(@"a.akamaihd-staging.net");
    addUnique(@"www.akamai.com");

    return [names copy];
}

- (NSDictionary *)makeEdgeCdnFrontingOverrideWithID:(NSString *)overrideID
                                          ipAddress:(NSString *)ipAddress
                                          customSni:(NSString *)customSni {
    NSString *sniServerName = (customSni.length > 0) ? customSni : ipAddress;
    return [self makeCdnFrontingOverrideWithID:overrideID
                  matchFrontingProviderIDRegexes:nil
                         matchDialAddressRegexes:@[@".*"]
                                    dialAddress:ipAddress
                                  sniServerName:sniServerName
                               verifyServerNames:[self makeEdgeVerifyServerNamesForIP:ipAddress sni:sniServerName]
                                  alpnProtocols:@[@"http/1.1"]];
}

- (NSArray *)buildCdnFrontingDialOverrides {
    NSMutableArray *overrides = [NSMutableArray array];
    NSMutableSet *edgeDialAddresses = [NSMutableSet set];

    NSString *customIpList = [self getCdnFrontingCustomIpList];
    NSString *customSni = [[self class] normalizeCdnFrontingCustomSni:[self getCdnFrontingCustomSni]];

    // Fastly provider override
    NSArray *fastlyVerifyServerNames = @[@"www.python.org", @"pypi.org", @"fastly.com",
        @"www.fastly.com", @"developer.fastly.com", @"githubassets.com",
        @"github.com", @"github.io", @"githubusercontent.com"];
    NSArray *fastlyALPNProtocols = @[@"h2", @"http/1.1"];

    [overrides addObject:[self makeCdnFrontingOverrideWithID:@"fastly-provider"
                              matchFrontingProviderIDRegexes:@[@"(?i)fastly"]
                                     matchDialAddressRegexes:nil
                                                dialAddress:@"pypi.org"
                                              sniServerName:@"pypi.org"
                                           verifyServerNames:fastlyVerifyServerNames
                                              alpnProtocols:fastlyALPNProtocols]];

    [overrides addObject:[self makeCdnFrontingOverrideWithID:@"fastly-address"
                              matchFrontingProviderIDRegexes:nil
                                     matchDialAddressRegexes:@[@"(?i)(fastly|pypi|python|github)"]
                                                dialAddress:@"pypi.org"
                                              sniServerName:@"pypi.org"
                                           verifyServerNames:fastlyVerifyServerNames
                                              alpnProtocols:fastlyALPNProtocols]];

    // Custom user IPs
    NSArray *customIPs = [[self class] parseCdnFrontingCustomIpList:customIpList];
    NSInteger customIndex = 1;
    for (NSString *ip in customIPs) {
        if (![edgeDialAddresses containsObject:ip]) {
            [edgeDialAddresses addObject:ip];
            [overrides addObject:[self makeEdgeCdnFrontingOverrideWithID:
                [NSString stringWithFormat:@"edge-custom-%ld", (long)customIndex]
                                                              ipAddress:ip
                                                              customSni:customSni]];
            customIndex++;
        }
    }

    // Hardcoded Akamai edge IPs
    NSArray *edgeEntries = @[
        @[@"edge-a-1", @"23.215.0.206"],
        @[@"edge-a-2", @"23.215.0.203"],
        @[@"edge-b-1", @"23.212.250.91"],
        @[@"edge-b-2", @"23.212.250.78"],
        @[@"edge-c-1", @"23.12.147.13"],
        @[@"edge-c-2", @"23.12.147.29"],
        @[@"edge-d-1", @"23.73.207.8"],
        @[@"edge-d-2", @"23.73.207.15"],
        @[@"edge-original", @"92.123.102.43"]
    ];
    for (NSArray *entry in edgeEntries) {
        NSString *edgeId = entry[0];
        NSString *edgeIp = entry[1];
        if (![edgeDialAddresses containsObject:edgeIp]) {
            [edgeDialAddresses addObject:edgeIp];
            [overrides addObject:[self makeEdgeCdnFrontingOverrideWithID:edgeId
                                                              ipAddress:edgeIp
                                                              customSni:customSni]];
        }
    }

    return [overrides copy];
}

#pragma mark - Shir o Khorshid Settings

- (NSString *)getProtocolSelection {
    NSString *value = [sharedDefaults stringForKey:ShirProtocolSelectionKey];
    return value ?: @"auto";
}

- (void)setProtocolSelection:(NSString *)mode {
    [sharedDefaults setObject:mode forKey:ShirProtocolSelectionKey];
}

- (BOOL)getBeastMode {
    if ([sharedDefaults objectForKey:ShirBeastModeKey] == nil) {
        return YES; // default enabled
    }
    return [sharedDefaults boolForKey:ShirBeastModeKey];
}

- (void)setBeastMode:(BOOL)enabled {
    [sharedDefaults setBool:enabled forKey:ShirBeastModeKey];
}

- (NSString *)getCdnFrontingCustomIpList {
    return [sharedDefaults stringForKey:ShirCdnFrontingCustomIpListKey] ?: @"";
}

- (void)setCdnFrontingCustomIpList:(NSString *)ipList {
    [sharedDefaults setObject:ipList forKey:ShirCdnFrontingCustomIpListKey];
}

- (NSString *)getCdnFrontingCustomSni {
    return [sharedDefaults stringForKey:ShirCdnFrontingCustomSniKey] ?: @"";
}

- (void)setCdnFrontingCustomSni:(NSString *)sni {
    [sharedDefaults setObject:sni forKey:ShirCdnFrontingCustomSniKey];
}

- (NSString *)getConduitMode {
    NSString *value = [sharedDefaults stringForKey:ShirConduitModeKey];
    return value ?: @"auto";
}

- (void)setConduitMode:(NSString *)mode {
    [sharedDefaults setObject:mode forKey:ShirConduitModeKey];
}

- (NSInteger)getConduitTimeoutSeconds {
    NSInteger value = [sharedDefaults integerForKey:ShirConduitTimeoutSecondsKey];
    return value > 0 ? value : 180; // default 3 minutes
}

- (void)setConduitTimeoutSeconds:(NSInteger)seconds {
    [sharedDefaults setInteger:seconds forKey:ShirConduitTimeoutSecondsKey];
}

- (BOOL)getRejectCensoredCountryProxies {
    if ([sharedDefaults objectForKey:ShirRejectCensoredCountryProxiesKey] == nil) {
        return YES; // default enabled
    }
    return [sharedDefaults boolForKey:ShirRejectCensoredCountryProxiesKey];
}

- (void)setRejectCensoredCountryProxies:(BOOL)reject {
    [sharedDefaults setBool:reject forKey:ShirRejectCensoredCountryProxiesKey];
}

- (BOOL)getShareProxyOnNetwork {
    return [sharedDefaults boolForKey:ShirShareProxyOnNetworkKey];
}

- (void)setShareProxyOnNetwork:(BOOL)share {
    [sharedDefaults setBool:share forKey:ShirShareProxyOnNetworkKey];
}

- (NSString *)getDisguiseIdentity {
    NSString *value = [sharedDefaults stringForKey:ShirDisguiseIdentityKey];
    return value ?: @"default";
}

- (void)setDisguiseIdentity:(NSString *)identity {
    [sharedDefaults setObject:identity forKey:ShirDisguiseIdentityKey];
}

- (BOOL)getStealthNotifications {
    return [sharedDefaults boolForKey:ShirStealthNotificationsKey];
}

- (void)setStealthNotifications:(BOOL)enabled {
    [sharedDefaults setBool:enabled forKey:ShirStealthNotificationsKey];
}

#pragma mark - Container Data (Data originating in the container)

- (BOOL)getAppForegroundState {
    return [sharedDefaults boolForKey:ContainerForegroundStateBoolKey];
}

- (BOOL)setAppForegroundState:(BOOL)foregrounded {
    [sharedDefaults setBool:foregrounded forKey:ContainerForegroundStateBoolKey];
    return [sharedDefaults synchronize];
}

- (NSInteger)getContainerTunnelIntentStatus {
    return [sharedDefaults integerForKey:ContainerTunnelIntentStatusIntKey];
}

#if !(TARGET_IS_EXTENSION)
- (void)setContainerTunnelIntentStatus:(NSInteger)statusCode {
    [sharedDefaults setInteger:statusCode forKey:ContainerTunnelIntentStatusIntKey];
}
#endif

- (NSDate *_Nullable)getContainerTunnelStartTime {
    NSString *_Nullable rfc3339Date = [sharedDefaults stringForKey:TunnelStartTimeStringKey];
    if (!rfc3339Date) {
        return nil;
    }

    return [NSDate fromRFC3339String:rfc3339Date];
}

- (void)setContainerTunnelStartTime:(NSDate *)startTime {
    NSString *rfc3339Date = [startTime RFC3339String];
    [sharedDefaults setObject:rfc3339Date forKey:TunnelStartTimeStringKey];
}

#if !(TARGET_IS_EXTENSION)
- (void)setContainerDisallowedTrafficAlertReadAtLeastUpToSequenceNum:(NSInteger)seq {
    [sharedDefaults setInteger:seq forKey:ContainerDisallowedTrafficAlertReadAtLeastUpToSeqIntKey];
}

- (NSInteger)getContainerDisallowedTrafficAlertReadAtLeastUpToSequenceNum {
    return [sharedDefaults integerForKey:ContainerDisallowedTrafficAlertReadAtLeastUpToSeqIntKey];
}

- (void)setContainerPurchaseRequiredHandledEventVPNSessionNumber:(NSInteger)sessionNum {
    [sharedDefaults setInteger:sessionNum forKey:ConstainerPurchaseRequiredVPNSessionHandledIntKey];
}

- (NSInteger)getContainerPurchaseRequiredHandledEventLatestVPNSessionNumber {
    return [sharedDefaults integerForKey:ConstainerPurchaseRequiredVPNSessionHandledIntKey];
}

#endif

#pragma mark - Extension Data (Data originating in the extension)

- (NSInteger)incrementVPNSessionNumber {
    NSInteger newValue = [self getVPNSessionNumber] + 1;
    [sharedDefaults setInteger:newValue
                        forKey:ExtensionVPNSessionNumberIntKey];
    return newValue;
}

- (NSInteger)getVPNSessionNumber {
    return [sharedDefaults integerForKey:ExtensionVPNSessionNumberIntKey];
}

- (PNEApplicationParameters *_Nonnull)getApplicationParameters {
    NSData *_Nullable data = [sharedDefaults dataForKey:ExtensionApplicationParametersDataKey];
    if (data == nil) {
        return [[PNEApplicationParameters alloc] init];
    }
    
    NSError *err = nil;
    PNEApplicationParameters *params = [Archiver unarchiveObjectOfClass:[PNEApplicationParameters class]
                                                               fromData:data
                                                                  error:&err];
    
    if (err != nil) {
        [PsiFeedbackLogger error:err message:@"Failed to unarchive PNEApplicationParameters"];
        return [[PNEApplicationParameters alloc] init];
    } else {
        return params;
    }
}

- (NSError *_Nullable)setApplicationParameters:(PNEApplicationParameters *_Nonnull)params {
    NSError *err = nil;
    NSData *data = [Archiver archiveObject:params error:&err];
    if (data != nil) {
        [sharedDefaults setObject:data forKey:ExtensionApplicationParametersDataKey];
    }
    return err;
}

// TODO: is timestamp needed? Maybe we can use this to detect staleness later
- (BOOL)setEmittedEgressRegions:(NSArray<NSString *> *)regions {
    [sharedDefaults setObject:regions forKey:EgressRegionsStringArrayKey];
    return [sharedDefaults synchronize];
}

- (BOOL)insertNewClientRegion:(NSString*)region {
    [sharedDefaults setObject:region forKey:ClientRegionStringKey];
    return [sharedDefaults synchronize];
}

- (BOOL)setCurrentSponsorId:(NSString *_Nullable)sponsorId {
    [sharedDefaults setObject:sponsorId forKey:TunnelSponsorIDStringKey];
    return [sharedDefaults synchronize];
}

- (void)updateServerTimestamp:(NSString*) timestamp {
    [sharedDefaults setObject:timestamp forKey:ServerTimestampStringKey];
    [sharedDefaults synchronize];
}

- (void)setExtensionIsZombie:(BOOL)isZombie {
    [sharedDefaults setBool:isZombie forKey:ExtensionIsZombieBoolKey];
}

- (BOOL)getExtensionIsZombie {
    return [sharedDefaults boolForKey:ExtensionIsZombieBoolKey];
}

- (void)setExtensionStopReason:(NSInteger)reason {
    [sharedDefaults setInteger:reason forKey:ExtensionStopReasonIntegerKey];
}

- (NSInteger)getExtensionStopReason {
    return [sharedDefaults integerForKey:ExtensionStopReasonIntegerKey];
}

- (void)incrementDisallowedTrafficAlertWriteSequenceNum {
    NSInteger lastSeq = [self getDisallowedTrafficAlertWriteSequenceNum];
    [sharedDefaults setInteger:(lastSeq + 1)
                        forKey:ExtensionDisallowedTrafficAlertWriteSeqIntKey];
}

- (NSInteger)getDisallowedTrafficAlertWriteSequenceNum {
    return [sharedDefaults integerForKey:ExtensionDisallowedTrafficAlertWriteSeqIntKey];
}

- (void)setApplicationParametersChangeTimestamp:(NSDate *)date {
    NSString *rfc3339Date = [date RFC3339String];
    [sharedDefaults setObject:rfc3339Date forKey:ExtensionApplicationParametersChangeTimestamp];
}

- (NSDate * _Nullable)getApplicationParametersChangeTimestamp {
    NSString * _Nullable rfc3339Date = [sharedDefaults stringForKey:ExtensionApplicationParametersChangeTimestamp];
    if (!rfc3339Date) {
        return nil;
    }
    return [NSDate fromRFC3339String:rfc3339Date];
}

- (NSArray<Homepage *> *_Nullable)getHomepages {
    NSMutableArray<Homepage *> *homepages = nil;
    NSError *err;

    NSString *data = [FileUtils tryReadingFile:[self homepageNoticesPath]];

    if (!data) {
        [PsiFeedbackLogger error:@"Failed reading homepage notices file. Error:%@", err];
        return nil;
    }

    homepages = [NSMutableArray array];
    NSArray *homepageNotices = [data componentsSeparatedByString:@"\n"];

    for (NSString *line in homepageNotices) {

        if (!line || [line length] == 0) {
            continue;
        }

        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[line dataUsingEncoding:NSUTF8StringEncoding]
                                                             options:0 error:&err];

        if (err) {
            [PsiFeedbackLogger error:@"Failed parsing homepage notices file. Error:%@", err];
        }

        if (dict) {
            Homepage *h = [[Homepage alloc] init];
            h.url = [NSURL URLWithString:dict[@"data"][@"url"]];
            h.timestamp = [NSDate fromRFC3339String:dict[@"timestamp"]];
            [homepages addObject:h];
        }
    }

    return homepages;
}

- (NSArray<NSString *> *)emittedEgressRegions {
    return [sharedDefaults objectForKey:EgressRegionsStringArrayKey];
}

- (NSString *)emittedClientRegion {
    return [sharedDefaults objectForKey:ClientRegionStringKey];
}

- (NSString *_Nullable)getCurrentSponsorId {
    return [sharedDefaults stringForKey:TunnelSponsorIDStringKey];
}

- (NSString*)getServerTimestamp {
    return [sharedDefaults stringForKey:ServerTimestampStringKey];
}

#pragma mark - Jetsam counter

- (NSString*)extensionJetsamMetricsFilePath {
    return [[[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:appGroupIdentifier] path] stringByAppendingPathComponent:@"extension.jetsams"];
}

- (NSString*)extensionJetsamMetricsRotatedFilePath {
    return [[[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:appGroupIdentifier] path] stringByAppendingPathComponent:@"extension.jetsams.1"];
}

#if TARGET_IS_CONTAINER

- (NSString*)containerJetsamMetricsRegistryFilePath {
    return [[[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:appGroupIdentifier] path] stringByAppendingPathComponent:@"container.jetsam.registry"];
}

#endif

#if TARGET_IS_EXTENSION

- (void)setExtensionJetsammedBeforeStopFlag:(BOOL)crashed {
    [sharedDefaults setBool:crashed forKey:SharedDataExtensionCrashedBeforeStopBoolKey];
}

- (BOOL)getExtensionJetsammedBeforeStopFlag {
    return [sharedDefaults boolForKey:SharedDataExtensionCrashedBeforeStopBoolKey];
}

#endif

#pragma mark - Debug Preferences

#if DEBUG || DEV_RELEASE

- (SharedDebugFlags *_Nonnull)getSharedDebugFlags {
    NSData *_Nullable data = [sharedDefaults dataForKey:ContainerSharedDebugFlagsKey];
    if (data == nil) {
        return [[SharedDebugFlags alloc] init];
    } else {
        NSError *err = nil;
        
        SharedDebugFlags *flags = [Archiver unarchiveObjectOfClass:[SharedDebugFlags class]
                                                          fromData:data
                                                             error:&err];
        if (err != nil) {
            return [[SharedDebugFlags alloc] init];
        } else {
            return flags;
        }
    }
}

- (void)setSharedDebugFlags:(SharedDebugFlags *_Nonnull)debugFlags {
    NSError *err = nil;
    NSData *data = [Archiver archiveObject:debugFlags error:&err];
    if (data != nil) {
        [sharedDefaults setObject:data forKey:ContainerSharedDebugFlagsKey];
    }
}

- (void)setDebugMemoryProfiler:(BOOL)enabled {
    [sharedDefaults setBool:enabled forKey:DebugMemoryProfileBoolKey];
}

- (BOOL)getDebugMemoryProfiler {
    return [sharedDefaults boolForKey:DebugMemoryProfileBoolKey];
}

- (NSURL *)goProfileDirectory {
    return [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:appGroupIdentifier]
            URLByAppendingPathComponent:@"go_profile" isDirectory:TRUE];
}

- (void)setDebugPsiphonConnectionState:(NSString *)state {
    [sharedDefaults setObject:state forKey:DebugPsiphonConnectionStateStringKey];
}

- (NSString *_Nonnull)getDebugPsiphonConnectionState {
    NSString *state = [sharedDefaults stringForKey:DebugPsiphonConnectionStateStringKey];
    if (state == nil) {
        state = @"None";
    }
    return state;
}

#endif

@end
