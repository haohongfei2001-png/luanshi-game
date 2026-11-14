import AppKit
import Darwin
import AVFoundation
import Foundation
import ScreenCaptureKit

// Test-host utility. Record just the requested game window; retain native timestamps.
@available(macOS 15.0, *)
final class WriterEvents: NSObject, SCRecordingOutputDelegate {
    var finished = false
    var failure: Error?

    func recordingOutputDidStartRecording(_ output: SCRecordingOutput) {
        print("WINDOW_WRITER_READY")
        fflush(stdout)
    }
    func recordingOutput(_ output: SCRecordingOutput, didFailWithError error: Error) {
        failure = error
        finished = true
    }
    func recordingOutputDidFinishRecording(_ output: SCRecordingOutput) {
        finished = true
    }
}

@main
struct BridgeWindowMovie {
    static func main() async throws {
        guard ProcessInfo.processInfo.environment["GITHUB_ACTIONS"] == "true",
              CommandLine.arguments.count == 3, let pid = Int32(CommandLine.arguments[1]),
              #available(macOS 15.0, *) else { exit(2) }
        let library = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
        guard let window = library.windows.filter({ $0.owningApplication?.processID == pid && $0.windowLayer == 0 }).max(by: { $0.frame.width < $1.frame.width }),
              window.frame.width >= 600 else { exit(3) }
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let config = SCStreamConfiguration()
        let scale = CGFloat(filter.pointPixelScale)
        config.width = 2 * Int((filter.contentRect.width * scale / 2).rounded())
        config.height = 2 * Int((filter.contentRect.height * scale / 2).rounded())
        config.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        config.queueDepth = 4
        config.ignoreShadowsSingleWindow = true
        config.showsCursor = true
        config.capturesAudio = true
        config.excludesCurrentProcessAudio = true
        config.captureMicrophone = false
        config.sampleRate = 48000
        config.channelCount = 2
        let url = URL(fileURLWithPath: CommandLine.arguments[2])
        let settings = SCRecordingOutputConfiguration()
        settings.outputURL = url
        settings.outputFileType = .mp4
        settings.videoCodecType = .h264
        let events = WriterEvents()
        let writer = SCRecordingOutput(configuration: settings, delegate: events)
        let stream = SCStream(filter: filter, configuration: config, delegate: nil)
        try stream.addRecordingOutput(writer)
        try await stream.startCapture()
        try await Task.sleep(nanoseconds: 33_000_000_000)
        try await stream.stopCapture()
        for _ in 0..<150 {
            if events.finished { break }
            try await Task.sleep(nanoseconds: 40_000_000)
        }
        if let err = events.failure { throw err }
        guard events.finished else { exit(4) }
        let asset = AVURLAsset(url: url)
        let duration = (try await asset.load(.duration)).seconds
        let videos = try await asset.loadTracks(withMediaType: .video)
        let audio = try await asset.loadTracks(withMediaType: .audio)
        guard let video = videos.first, duration >= 30 else { exit(5) }
        let pixels = try await video.load(.naturalSize)
        let hz = try await video.load(.nominalFrameRate)
        print("WALL_CLOCK_MOVIE", Int(pixels.width), Int(pixels.height), duration, hz, "audio_tracks", audio.count)
    }
}
