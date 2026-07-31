//
//  VitalAUViewController.swift
//  VitalAU
//
//  AUv3 view controller — hosts the SwiftUI editor view.
//

import UIKit
import SwiftUI
import AudioToolbox
import CoreAudioKit

@objc(VitalAUViewController)
public class VitalAUViewController: AUViewController, AUAudioUnitFactory {

    public var audioUnit: AUAudioUnit? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.connectUI()
            }
        }
    }

    private var viewModel: VitalAUViewModel?

    // MARK: - AUAudioUnitFactory

    public func createAudioUnit(with desc: AudioComponentDescription) throws -> AUAudioUnit {
        let au = try VitalAUAudioUnit(componentDescription: desc)
        self.audioUnit = au
        return au
    }

    // MARK: - View lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 38/255, green: 42/255, blue: 45/255, alpha: 1)
        connectUI()
    }

    private func connectUI() {
        guard let au = audioUnit as? VitalAUAudioUnit, viewModel == nil else { return }
        let vm = VitalAUViewModel(au: au)
        viewModel = vm

        let swiftUIView = VitalAUView(viewModel: vm)
        let hostingCtrl = UIHostingController(rootView: swiftUIView)
        addChild(hostingCtrl)
        hostingCtrl.view.frame = view.bounds
        hostingCtrl.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingCtrl.view)
        hostingCtrl.didMove(toParent: self)
    }
}
