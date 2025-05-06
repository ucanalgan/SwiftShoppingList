import UIKit
import Speech
import AVFoundation

enum VoiceCommandType {
    case addItem(String)
    case deleteItem(String)
    case checkItem(String)
    case uncheckItem(String)
    case clearList
    case showChecked
    case hideChecked
    case unknown
}

protocol VoiceCommandDelegate: AnyObject {
    func voiceCommandDetected(_ command: VoiceCommandType)
    func voiceRecognitionStatusChanged(isActive: Bool)
    func voiceRecognitionError(_ error: Error)
}

class VoiceCommandManager: NSObject {
    static let shared = VoiceCommandManager()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    weak var delegate: VoiceCommandDelegate?
    private(set) var isListening = false
    
    // Private constructor for singleton
    private override init() {
        super.init()
    }
    
    // Request authorization
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    completion(true)
                default:
                    completion(false)
                }
            }
        }
    }
    
    // Start listening for voice commands
    func startListening() {
        if isListening {
            stopListening()
        }
        
        requestAuthorization { [weak self] authorized in
            guard let self = self, authorized else {
                if let error = NSError(domain: "VoiceRecognitionErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Speech recognition not authorized"]) as Error? {
                    self?.delegate?.voiceRecognitionError(error)
                }
                return
            }
            
            do {
                try self.startRecognition()
                self.isListening = true
                self.delegate?.voiceRecognitionStatusChanged(isActive: true)
            } catch {
                self.delegate?.voiceRecognitionError(error)
            }
        }
    }
    
    // Stop listening
    func stopListening() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        isListening = false
        delegate?.voiceRecognitionStatusChanged(isActive: false)
    }
    
    // Toggle listening state
    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    // Start the recognition process
    private func startRecognition() throws {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .default)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Setup recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "VoiceRecognitionErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Setup audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.stopListening()
                self.delegate?.voiceRecognitionError(error)
                return
            }
            
            if let result = result {
                // Process the recognized text
                self.processVoiceCommand(result.bestTranscription.formattedString)
            }
        }
    }
    
    // Process the recognized text to extract commands
    private func processVoiceCommand(_ text: String) {
        let lowercasedText = text.lowercased()
        
        // Check for "add" command
        if lowercasedText.contains("add") {
            let components = lowercasedText.components(separatedBy: "add ")
            if components.count > 1 {
                let itemName = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                delegate?.voiceCommandDetected(.addItem(itemName))
                return
            }
        }
        
        // Check for "delete" or "remove" command
        if lowercasedText.contains("delete") || lowercasedText.contains("remove") {
            let components1 = lowercasedText.components(separatedBy: "delete ")
            let components2 = lowercasedText.components(separatedBy: "remove ")
            
            if components1.count > 1 {
                let itemName = components1[1].trimmingCharacters(in: .whitespacesAndNewlines)
                delegate?.voiceCommandDetected(.deleteItem(itemName))
                return
            } else if components2.count > 1 {
                let itemName = components2[1].trimmingCharacters(in: .whitespacesAndNewlines)
                delegate?.voiceCommandDetected(.deleteItem(itemName))
                return
            }
        }
        
        // Check for "check" command
        if lowercasedText.contains("check") && !lowercasedText.contains("uncheck") {
            let components = lowercasedText.components(separatedBy: "check ")
            if components.count > 1 {
                let itemName = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                delegate?.voiceCommandDetected(.checkItem(itemName))
                return
            }
        }
        
        // Check for "uncheck" command
        if lowercasedText.contains("uncheck") {
            let components = lowercasedText.components(separatedBy: "uncheck ")
            if components.count > 1 {
                let itemName = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                delegate?.voiceCommandDetected(.uncheckItem(itemName))
                return
            }
        }
        
        // Check for "clear list" command
        if lowercasedText.contains("clear list") || lowercasedText.contains("clear all") {
            delegate?.voiceCommandDetected(.clearList)
            return
        }
        
        // Check for "show checked" command
        if lowercasedText.contains("show checked") || lowercasedText.contains("show completed") {
            delegate?.voiceCommandDetected(.showChecked)
            return
        }
        
        // Check for "hide checked" command
        if lowercasedText.contains("hide checked") || lowercasedText.contains("hide completed") {
            delegate?.voiceCommandDetected(.hideChecked)
            return
        }
    }
} 