import Foundation
import SwiftData

/// Runs cloud sync in the background and reflects the result in the UI.
/// Failures never block the fisher: records stay on the phone and upload later.
@MainActor
enum SyncController {
    static func connectAndSync(user: UserAccount, password: String, appState: AppState, context: ModelContext) async {
        guard AppConfig.isCloudEnabled else { return }
        // Never reuse a cloud session left by another account on this phone.
        SupabaseClient.shared.signOut()
        do {
            try await SyncService.connect(user: user, password: password)
            await sync(appState: appState, context: context)
            try await SyncService.pull(ownerID: user.id, context: context)
            await FairPriceService.refresh()
            appState.currentUserVerified = await SyncService.isVerified()
            await OfferController.refresh(appState: appState)
        } catch {
            appState.isOffline = isConnectivityError(error)
        }
    }

    static func sync(appState: AppState, context: ModelContext) async {
        guard AppConfig.isCloudEnabled, SupabaseClient.shared.isSignedIn else { return }
        do {
            try await SyncService.pushPending(context: context)
            appState.isOffline = false
            appState.lastSyncError = nil
        } catch {
            appState.isOffline = isConnectivityError(error)
            appState.lastSyncError = error.localizedDescription
        }
    }

    private static func isConnectivityError(_ error: Error) -> Bool {
        (error as? URLError) != nil
    }
}
