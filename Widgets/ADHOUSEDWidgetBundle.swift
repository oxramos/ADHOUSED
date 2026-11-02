import WidgetKit
import SwiftUI
import ADHOUSEDCore
#if canImport(AlarmKit)
import AlarmKit
#endif

@main
struct ADHOUSEDWidgetBundle: WidgetBundle {
    var body: some Widget {
        ADHOUSEDFocusWidget()
        ChoreNagLiveActivityWidget()
        SprintTimerLiveActivityWidget()
        if #available(iOS 26.1, *) {
            ChoreCutoffAlarmLiveActivityWidget()
        }
    }
}
