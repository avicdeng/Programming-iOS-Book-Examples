

import UIKit
import AVFoundation
import MediaPlayer

protocol PlayerDelegate : class {
    func soundFinished(_ sender: Any)
}

class Player : NSObject, AVAudioPlayerDelegate {
    var player : AVAudioPlayer!
    var forever = false
    weak var delegate : PlayerDelegate?
    var observer : NSObjectProtocol!
    
    override init() {
        super.init()
        // interruption notification
        // note (irrelevant for bk 2, but useful for bk 1) how to prevent retain cycle
        self.observer = NotificationCenter.default.addObserver(forName:
            .AVAudioSessionInterruption, object: nil, queue: nil) {
                [weak self] n in
                guard let why =
                    n.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
                    else {return}
                guard let type = AVAudioSessionInterruptionType(rawValue: why)
                    else {return}
                if type == .began {
                    print("interruption began:\n\(n.userInfo!)")
                } else {
                    print("interruption ended:\n\(n.userInfo!)")
                    guard let opt = n.userInfo![AVAudioSessionInterruptionOptionKey] as? UInt else {return}
                    let opts = AVAudioSessionInterruptionOptions(rawValue: opt)
                    if opts.contains(.shouldResume) {
                        print("should resume")
                        self?.player.prepareToPlay()
                        let ok = self?.player.play()
                        print("bp tried to resume play: did I? \(ok)")
                    } else {
                        print("not should resume")
                    }
                }
        }
    }
    
    func playFile(atPath path:String) {
        self.player?.delegate = nil
        self.player?.stop()
        let fileURL = URL(fileURLWithPath: path)
        print("bp making a new Player")
        guard let p = try? AVAudioPlayer(contentsOf: fileURL) else {return} // nicer
        self.player = p
        // error-checking omitted
        
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        
        // try this, to prove that mixable _background_ sound is not interrupted by nonmixable foreground sound
        // I find this kind of weird; you aren't allowed to interrupt any sound you want to interrupt?
        // try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, withOptions: .MixWithOthers)

        try? AVAudioSession.sharedInstance().setActive(true)
        
        
        self.player.prepareToPlay()
        self.player.delegate = self
        let ok = player.play()
        print("bp trying to play \(path): \(ok)")
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { // *
        let sess = AVAudioSession.sharedInstance()
        try? sess.setActive(false, with: .notifyOthersOnDeactivation)
        try? sess.setCategory(AVAudioSessionCategoryAmbient)
        try? sess.setActive(true)
        delegate?.soundFinished(self)
    }
    
    // to hear about interruptions, in iOS 8, use the session notifications
    
    func stop () {
        self.player?.pause()
    }
    
    deinit {
        print("bp player dealloc")
        if self.observer != nil {
            NotificationCenter.default.removeObserver(self.observer)
        }
        self.player?.delegate = nil
    }
    
    
}
