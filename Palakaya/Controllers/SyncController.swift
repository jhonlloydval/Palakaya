import Foundation
import SwiftData

/// Runs cloud sync in the background and reflects the result in the UI.
/// Failures never block the fisher: records stay on the phone and upload later.
@MainActor
enum SyncController {
    static func connectAndSync(user: UserAccount, password: String, appState: AppState, context: ModelContext) async {
        guard AppConfig.isCloudEnabled else { return }
        do {
            try await SyncService.connect(user: user, password: password)
            await sync(appState: appState, context: context)
            try await SyncService.pull(ownerID: user.id, context: context)
        } catch {
            appState.isOffline = isConnectivityError(error)
        }
    }

    static func sync(appState: AppState, context: ModelContext) async {
        guard AppConfig.isCloudEnabled, SupabaseClient.shared.isSignedIn else { return }
        do {
            try await SyncService.pushPending(context: context)
            appState.isOffline = false
        } catch {
            appState.isOffline = isConnectivityError(error)
        }
    }

    private static func isConnectivityError(_ error: Error) -> Bool {
        (error as? URLError) != nil
    }
}
