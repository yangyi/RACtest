//
//  SignalViewController.swift
//  RACtest
//
//  Created by leaping on 10/9/14.
//
//

import UIKit

class SignalViewController: UIViewController {

    weak var signal: RACSignal! // use weak var so taht `SignalViewController` will not retain the signal
    
    override func awakeFromNib() {
        signal = ([1,2,3,4] as NSArray).rac_sequence.signal()
        signal.subscribeNext { (e) in
            println("number \(e) from \(self)")
        }
    }
    
    deinit {
        println("deinit SignalViewController, and signal is \(signal)")
    }


}
