//
//  BackgroundLocationManager.swift
//  Fit term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import Foundation
import CoreLocation

@Observable
final class BackgroundLocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    private(set) var isRunning = false
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    var isAuthorized: Bool {
        authorizationStatus == .authorizedAlways
    }

    var needsPermission: Bool {
        authorizationStatus == .notDetermined
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.distanceFilter = CLLocationDistance.greatestFiniteMagnitude
        locationManager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = locationManager.authorizationStatus
    }

    func requestPermission() {
        locationManager.requestAlwaysAuthorization()
    }

    func start() {
        guard isAuthorized, !isRunning else { return }
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.startUpdatingLocation()
        isRunning = true
    }

    func stop() {
        guard isRunning else { return }
        locationManager.stopUpdatingLocation()
        isRunning = false
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 何もしない — アプリを生かしておくためだけに受信
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // エラーは無視（位置情報自体は使わないので）
    }
}
