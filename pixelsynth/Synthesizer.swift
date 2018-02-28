//
//  Synthesizer.swift
//  pixelsynth
//
//  Created by Malte Bünz on 19.04.17.
//  Copyright © 2017 Malte Bünz. All rights reserved.
//

import Foundation
import AudioKit

struct Synthesizer {
    
    let morph: AKMorphingOscillator! = {
        let morpho = AKMorphingOscillator(waveformArray: [AKTable(.sine),
                                                     AKTable(.triangle),
                                                     AKTable(.sawtooth),
                                                     AKTable(.square)])
        morpho.amplitude = 0.1
        morpho.frequency = 400
        morpho.index = 0.8
        return morpho
    }()
    let mixer: AKMixer! = AKMixer()
    
    init() {
        AudioKit.output = mixer
        mixer.connect(morph)
        morph.start()
        do {
            try AudioKit.start()
        } catch {
            print("")
        }
    }
    
    public func toggleMorph() {
        if self.morph.isStopped {
            morph.play()
        } else {
            self.morph.stop()
        }
    }
    
}
