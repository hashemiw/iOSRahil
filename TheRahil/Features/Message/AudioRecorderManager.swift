//
//  AudioRecorderManager.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/4/17.
//

// AudioRecorderManager.swift

// AudioRecorderManager.swift

import AVFoundation
import Combine

class AudioRecorderManager: NSObject, ObservableObject {
    @Published var recordingURL: URL?
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?

    override init() {
        super.init()
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    func startRecording() {
        let fileName = "voice_\(Date().timeIntervalSince1970).m4a"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        print("🎤 Recording to: \(url.path)")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            
            let success = audioRecorder?.record() ?? false
            print("🎤 Record started: \(success)")

            if !success {
                print("⚠️ Recorder failed to start")
                return
            }

            recordingURL = url
            isRecording = true

            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.recordingDuration += 1
            }
        } catch {
            print("🎤 Failed to start recording: \(error)")
        }
    }

    func stopRecording() {
        guard let recorder = audioRecorder else {
            print("⚠️ No active recorder to stop")
            return
        }

        let duration = recorder.currentTime
        print("🎤 Stopped at: \(duration) seconds")
        
        recorder.stop()
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }

        timer?.invalidate()
        timer = nil
        isRecording = false
    }

    func cancelRecording() {
        audioRecorder?.stop()
        timer?.invalidate()
        timer = nil
        
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        recordingURL = nil
        isRecording = false
        recordingDuration = 0
    }
}


import AVFoundation

class AudioPlayerManager: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentMessageID: UInt?

    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?

    func play(url: URL, messageID: UInt) {
        if isPlaying && currentMessageID == messageID {
            stop()
            return
        }

        stop()

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()

            isPlaying = true
            currentMessageID = messageID
        } catch {
            print("Failed to play audio: \(error)")
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentMessageID = nil
        progressTimer?.invalidate()
        progressTimer = nil
    }

    var currentTime: TimeInterval {
        audioPlayer?.currentTime ?? 0
    }

    var duration: TimeInterval {
        audioPlayer?.duration ?? 0
    }
}

extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.stop()
        }
    }
}
