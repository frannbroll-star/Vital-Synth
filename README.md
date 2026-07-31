# Vital Synth (iOS)

iOS port of [Vital](https://github.com/mtytel/vital) — standalone app + AUv3 plugin.

## Targets

- **Vital Synth** — standalone iOS synth
- **VitalAU** — AUv3 instrument

## Build

Open `Vital Synth.xcodeproj` in Xcode and build the **Vital Synth** scheme for a device or simulator.

The C++ engine is linked via `lib/libVitalEngine.a` (built from `cpp/` + the `vial/` Vital sources).

## License

Vital’s engine is licensed under the **GNU GPL v3** — see [LICENSE](LICENSE).
