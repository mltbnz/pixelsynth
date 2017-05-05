//
//  SynthesizerTest.swift
//  pixelsynth
//
//  Created by Malte Bünz on 19.04.17.
//  Copyright © 2017 Malte Bünz. All rights reserved.
//

import XCTest
import AudioKit
@testable import pixelsynth

class SynthesizerTest: XCTestCase {
    
    var synth: Synthesizer?
    
    override func setUp() {
        super.setUp()
        synth = Synthesizer()
    }
    
    override func tearDown() {
        synth = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSynthesizerNotNil() {
        XCTAssertNotNil(synth)
    }
}
