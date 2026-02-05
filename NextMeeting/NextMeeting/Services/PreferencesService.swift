import SwiftUI

@MainActor
class PreferencesService: ObservableObject {
    private enum Keys {
        static let lookaheadHours = "lookaheadHours"
        static let refreshIntervalSeconds = "refreshIntervalSeconds"
        static let alertMinutesBefore = "alertMinutesBefore"
        static let excludedCalendarIDs = "excludedCalendarIDs"
    }
    
    @Published var lookaheadHours: Int {
        didSet {
            UserDefaults.standard.set(lookaheadHours, forKey: Keys.lookaheadHours)
        }
    }
    
    @Published var refreshIntervalSeconds: Int {
        didSet {
            UserDefaults.standard.set(refreshIntervalSeconds, forKey: Keys.refreshIntervalSeconds)
        }
    }
    
    @Published var alertMinutesBefore: Int {
        didSet {
            UserDefaults.standard.set(alertMinutesBefore, forKey: Keys.alertMinutesBefore)
        }
    }

    @Published var excludedCalendarIDs: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(excludedCalendarIDs), forKey: Keys.excludedCalendarIDs)
        }
    }
    
    init() {
        // Load from UserDefaults with default values
        let savedLookahead = UserDefaults.standard.integer(forKey: Keys.lookaheadHours)
        self.lookaheadHours = savedLookahead > 0 ? savedLookahead : 24
        
        let savedRefresh = UserDefaults.standard.integer(forKey: Keys.refreshIntervalSeconds)
        self.refreshIntervalSeconds = savedRefresh > 0 ? savedRefresh : 30
        
        // alertMinutesBefore can be 0, so we need to check if the key exists
        if UserDefaults.standard.object(forKey: Keys.alertMinutesBefore) != nil {
            self.alertMinutesBefore = UserDefaults.standard.integer(forKey: Keys.alertMinutesBefore)
        } else {
            self.alertMinutesBefore = 0
        }

        let savedExcluded = UserDefaults.standard.stringArray(forKey: Keys.excludedCalendarIDs) ?? []
        self.excludedCalendarIDs = Set(savedExcluded)
    }
}
