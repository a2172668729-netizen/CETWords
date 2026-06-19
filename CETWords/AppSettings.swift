import Foundation

@MainActor
final class AppSettings: ObservableObject {
    @Published var dailyNewWordTarget: Int {
        didSet {
            dailyNewWordTarget = min(max(dailyNewWordTarget, 5), 100)
            UserDefaults.standard.set(dailyNewWordTarget, forKey: Keys.dailyNewWordTarget)
        }
    }

    @Published var selectedCollectionID: Int {
        didSet {
            let clamped = min(max(selectedCollectionID, 1), 20)
            if selectedCollectionID != clamped {
                selectedCollectionID = clamped
                return
            }
            UserDefaults.standard.set(selectedCollectionID, forKey: Keys.selectedCollectionID)
        }
    }

    @Published var prioritizeReview: Bool {
        didSet {
            UserDefaults.standard.set(prioritizeReview, forKey: Keys.prioritizeReview)
        }
    }

    @Published var showMeaningAfterFlip: Bool {
        didSet {
            UserDefaults.standard.set(showMeaningAfterFlip, forKey: Keys.showMeaningAfterFlip)
        }
    }

    init() {
        let storedTarget = UserDefaults.standard.integer(forKey: Keys.dailyNewWordTarget)
        self.dailyNewWordTarget = storedTarget == 0 ? 30 : min(max(storedTarget, 5), 100)

        let storedCollectionID = UserDefaults.standard.integer(forKey: Keys.selectedCollectionID)
        self.selectedCollectionID = storedCollectionID == 0 ? 1 : min(max(storedCollectionID, 1), 20)

        if UserDefaults.standard.object(forKey: Keys.prioritizeReview) == nil {
            self.prioritizeReview = true
        } else {
            self.prioritizeReview = UserDefaults.standard.bool(forKey: Keys.prioritizeReview)
        }

        if UserDefaults.standard.object(forKey: Keys.showMeaningAfterFlip) == nil {
            self.showMeaningAfterFlip = true
        } else {
            self.showMeaningAfterFlip = UserDefaults.standard.bool(forKey: Keys.showMeaningAfterFlip)
        }
    }

    func apply(dailyNewWordTarget: Int, selectedCollectionID: Int, prioritizeReview: Bool, showMeaningAfterFlip: Bool) {
        self.dailyNewWordTarget = min(max(dailyNewWordTarget, 5), 100)
        self.selectedCollectionID = min(max(selectedCollectionID, 1), 20)
        self.prioritizeReview = prioritizeReview
        self.showMeaningAfterFlip = showMeaningAfterFlip
    }

    private enum Keys {
        static let dailyNewWordTarget = "settings.dailyNewWordTarget"
        static let selectedCollectionID = "settings.selectedCollectionID"
        static let prioritizeReview = "settings.prioritizeReview"
        static let showMeaningAfterFlip = "settings.showMeaningAfterFlip"
    }
}
