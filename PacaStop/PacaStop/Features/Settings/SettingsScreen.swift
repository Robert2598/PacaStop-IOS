//
//  SettingsScreen.swift
//  PacaStop
//
//  The protective controls + account (§5.6). Blocking (Screen Time), ONJN self-exclusion,
//  preferences (live language switch), relapse, sign-out, delete account.
//

import SwiftUI
import FamilyControls
import SafariServices

struct SettingsScreen: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(LocalizationStore.self) private var loc

    @State private var appSelection = FamilyActivitySelection()
    @State private var showAppPicker = false
    @State private var showONJNSafari = false
    @State private var showONJNConfirm = false
    @State private var showRelapseConfirm = false
    @State private var showSignOutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var showDeleteError = false
    @State private var isDeleting = false
    @State private var isRestoring = false
    @State private var showRestoreResult = false
    @State private var restoreSucceeded = false

    private var s: any Localization { loc.s }
    private var model: AppModel { env.appModel }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ScreenHeader(title: s.settingsTitle, showBack: true) {
                    env.router.mainTab = .home
                }
                protectionGroup
                onjnGroup
                preferencesGroup
                subscriptionGroup
                accountGroup
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.lg)
        }
        .screenBackground()
        .onAppear {
            appSelection = ScreenTimeSelectionCoder.decode(model.profile.blockedSelectionData) ?? FamilyActivitySelection()
            env.blocking.refreshAuthorizationStatus()
        }
        .familyActivityPicker(isPresented: $showAppPicker, selection: $appSelection)
        .onChange(of: appSelection) { _, newValue in
            model.setBlockedSelection(data: ScreenTimeSelectionCoder.encode(newValue))
        }
        .sheet(isPresented: $showONJNSafari, onDismiss: { showONJNConfirm = true }) {
            SafariView(url: AppConfiguration.onjnSelfExclusionURL).ignoresSafeArea()
        }
        .alert(s.onjnConfirmTitle, isPresented: $showONJNConfirm) {
            Button(s.onjnConfirmAction) { model.enrollONJN() }
            Button(s.cancelLabel, role: .cancel) {}
        } message: { Text(s.onjnConfirmMessage) }
        .alert(s.relapseConfirmTitle, isPresented: $showRelapseConfirm) {
            Button(s.relapseConfirmAction, role: .destructive) { model.relapse() }
            Button(s.cancelLabel, role: .cancel) {}
        } message: { Text(s.relapseConfirmMessage) }
        .alert(s.signOutConfirmTitle, isPresented: $showSignOutConfirm) {
            Button(s.signOutConfirmAction, role: .destructive) {
                Task {
                    await env.auth.signOut()   // deterministic: state → signedOut before we continue
                    env.analytics.reset()
                    env.onSignedOut()
                    env.appModel.endSession()  // reversible: keeps the journey for a re-login
                }
            }
            Button(s.cancelLabel, role: .cancel) {}
        }
        .alert(s.deleteAccountConfirmTitle, isPresented: $showDeleteConfirm) {
            Button(s.deleteAccountConfirmAction, role: .destructive) { deleteAccount() }
            Button(s.cancelLabel, role: .cancel) {}
        } message: { Text(s.deleteAccountConfirmMessage) }
        .alert(s.deleteAccountError, isPresented: $showDeleteError) {
            Button(s.closeLabel, role: .cancel) {}
        }
        .alert(restoreSucceeded ? s.settingsRestoreSuccess : s.paywallNothingToRestore,
               isPresented: $showRestoreResult) {
            Button(s.closeLabel, role: .cancel) {}
        }
    }

    // MARK: - Protection

    private var protectionGroup: some View {
        LabeledGroup(label: s.settingsProtectionGroup) {
            VStack(spacing: Spacing.sm) {
                // Highlighted master card
                VStack(spacing: Spacing.md) {
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Palette.onLime)
                            .frame(width: 42, height: 42)
                            .background(Palette.lime, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(s.blockTitle).font(Typo.headline).foregroundStyle(Palette.textPrimary)
                            Text(s.blockDesc).font(Typo.bodySm).foregroundStyle(Palette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Divider().overlay(Palette.hairline)
                    Toggle(isOn: masterBinding) {
                        Text(s.blockActive).font(Typo.bodyLg).foregroundStyle(Palette.textPrimary)
                    }
                    .tint(Palette.lime)
                }
                .padding(Spacing.lg)
                .pacaCard(Palette.limeSoftFill, border: Palette.limeSoftBorder)

                // Choose apps
                Button {
                    chooseApps()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.blockChooseApps).font(Typo.bodyLg).foregroundStyle(Palette.textPrimary)
                            Text(authHint).font(Typo.caption).foregroundStyle(Palette.textTertiary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Palette.textTertiary)
                    }
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity)
                    .pacaCard(Palette.surface)
                }
                .buttonStyle(PressableScale())

                // Known betting sites (ONJN list) — applied via the system web-content filter.
                Toggle(isOn: knownSitesBinding) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(s.blockKnownSitesTitle).font(Typo.bodyLg).foregroundStyle(Palette.textPrimary)
                        Text(s.blockKnownSitesSub(CasinoBlocklist.count))
                            .font(Typo.caption).foregroundStyle(Palette.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(Palette.lime)
                .padding(Spacing.md)
                .frame(maxWidth: .infinity)
                .pacaCard(Palette.surface)
            }
        }
    }

    private var knownSitesBinding: Binding<Bool> {
        Binding(
            get: { model.profile.blockKnownBettingSites },
            set: { model.setBlockKnownSites($0) }
        )
    }

    // MARK: - ONJN

    private var onjnGroup: some View {
        LabeledGroup(label: s.settingsStrongestStepGroup) {
            SectionCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(s.onjnTitle).font(Typo.headline).foregroundStyle(Palette.textPrimary)
                    Text(s.onjnDesc).font(Typo.bodySm).foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if model.profile.onjnEnrolled {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(Palette.lime)
                            Text(s.onjnEnrolled).font(Typo.bodyMd).foregroundStyle(Palette.lime)
                        }
                        .padding(Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Palette.limeSoftFill, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                    } else {
                        PacaButton(title: s.onjnEnroll, kind: .redOutline) {
                            env.analytics.track(.onjnPageOpened)
                            showONJNSafari = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Preferences

    private var preferencesGroup: some View {
        LabeledGroup(label: s.settingsPreferencesGroup) {
            Button {
                switchLanguage()
            } label: {
                HStack {
                    Text(s.languageLabel).font(Typo.bodyMd).foregroundStyle(Palette.textPrimary)
                    Spacer()
                    Text(loc.language.displayName).font(Typo.bodyMd).foregroundStyle(Palette.textSecondary)
                    Image(systemName: "arrow.left.arrow.right").font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.textTertiary)
                }
                .padding(.vertical, Spacing.sm)
                .padding(.horizontal, Spacing.md)
                .frame(maxWidth: .infinity)
                .pacaCard(Palette.surface)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Subscription (Restore — App Store Guideline 3.1.1, always reachable)

    private var subscriptionGroup: some View {
        LabeledGroup(label: s.settingsSubscriptionGroup) {
            Button {
                restorePurchases()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(s.settingsRestoreLabel).font(Typo.bodyLg).foregroundStyle(Palette.textPrimary)
                        Text(s.settingsRestoreSub).font(Typo.caption).foregroundStyle(Palette.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: Spacing.sm)
                    if isRestoring { ProgressView().tint(Palette.lime) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.md)
                .pacaCard(Palette.surface)
            }
            .buttonStyle(PressableScale())
            .disabled(isRestoring)
        }
    }

    private func restorePurchases() {
        guard !isRestoring else { return }
        isRestoring = true
        Task {
            let ok = await env.purchases.restore()
            env.analytics.track(.purchaseRestored)
            restoreSucceeded = ok
            showRestoreResult = true
            isRestoring = false
        }
    }

    // MARK: - Account

    private var accountGroup: some View {
        LabeledGroup(label: s.settingsAccountGroup) {
            VStack(spacing: Spacing.sm) {
                Button {
                    showRelapseConfirm = true
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(s.relapseLabel).font(Typo.bodyLg).foregroundStyle(Palette.amber)
                        Text(s.relapseSub).font(Typo.caption).foregroundStyle(Palette.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
                    .pacaCard(Palette.surface)
                }
                .buttonStyle(PressableScale())

                Button {
                    showSignOutConfirm = true
                } label: {
                    Text(s.signOutLabel)
                        .font(Typo.bodyLg)
                        .foregroundStyle(Palette.softRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.md)
                        .pacaCard(Palette.surface)
                }
                .buttonStyle(PressableScale())
                .disabled(isDeleting)

                // Account deletion (App Store Guideline 5.1.1(v)).
                Button {
                    showDeleteConfirm = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.deleteAccountLabel).font(Typo.bodyLg).foregroundStyle(Palette.red)
                            Text(s.deleteAccountSub).font(Typo.caption).foregroundStyle(Palette.textTertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: Spacing.sm)
                        if isDeleting { ProgressView().tint(Palette.red) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
                    .pacaCard(Palette.surface, border: Palette.redSoftBorder)
                }
                .buttonStyle(PressableScale())
                .disabled(isDeleting)
            }
        }
    }

    /// Permanently deletes the account: removes the remote user, then wipes all on-device
    /// data and returns to Login. If the remote deletion fails, nothing is wiped so the user
    /// can retry.
    private func deleteAccount() {
        guard !isDeleting else { return }
        isDeleting = true
        Task {
            let ok = await env.auth.deleteAccount()
            if ok {
                env.analytics.reset()
                env.onSignedOut()
                env.appModel.wipeAllLocalData()   // permanent: account deletion wipes everything
            } else {
                showDeleteError = true
            }
            isDeleting = false
        }
    }

    // MARK: - Bindings & actions

    private var masterBinding: Binding<Bool> {
        Binding(
            get: { model.profile.blockingMasterEnabled },
            set: { enabled in
                model.setBlockingMaster(enabled)
                if enabled, !env.blocking.authorizationStatus.isApproved {
                    Task { await env.blocking.requestAuthorization(); model.applyBlocking() }
                }
            }
        )
    }

    private var authHint: String {
        switch env.blocking.authorizationStatus {
        case .approved: s.blockAppsCount(model.blockedSelectionCount)
        default: s.blockAuthNeeded
        }
    }

    private func chooseApps() {
        Task {
            if !env.blocking.authorizationStatus.isApproved {
                _ = await env.blocking.requestAuthorization()
            }
            if env.blocking.authorizationStatus.isApproved {
                showAppPicker = true
            }
        }
    }

    private func switchLanguage() {
        loc.toggleLanguage()
        env.analytics.track(.languageChanged(loc.language))
        env.analytics.setLanguage(loc.language)
    }
}

/// An in-app Safari view for the official ONJN page.
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

#Preview {
    PreviewEnvironment { SettingsScreen() }
}
