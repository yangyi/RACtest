The project is an exercise for experimenting the memory management 

the main reference is [Memory Management in ReactvieCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa/blob/master/Documentation/MemoryManagement.md)

The finite and infinite signal will be explored to find out the real beahvior of RAC.

We will push an `SignalViewController(SVC)` to root viewController, and then pop `SVC`, and expecting the `SVC` be deallocated by iOS.

by checking whether the `RACSignal`/`SVC` was deallocated, the result is known to us.

#### setup the controllers

1. setup `SignalViewController`, `ViewController`, and add an signal button and segue for push navigation
2. add an briding header for import ReactiveCocoa

#### finite signal without capturing self

The code use [1,2,3,4] sequence signal here for an finite signal, but it the rule should also apply network request and other finite signals

The initial code is here:

	class SignalViewController: UIViewController {

	    weak var signal: RACSignal! // use weak var so taht `SignalViewController` will not retain the signal
	    
	    override func awakeFromNib() {
	        signal = ([1,2,3,4] as NSArray).rac_sequence.signal()
	        signal.subscribeNext { (e) in
	            println("number \(e)")
	        }
	    }
	   	    
	    deinit {
	        println("deinit SignalViewController, and signal is \(signal)")
	    }
	}


To test the result, nothing special here

1. run the app with current commit
2. push the signal view controller, and it print the signal 1,2,3,4
3. pop the signal view controller, view controller get deallocated, and echo the message, and found the signal is already deallocated

#### access self in closure

we modify the code from

	signal.subscribeNext { (e) in
	  println("number \(e)")
	}

to 

	signal.subscribeNext { (e) in
	  println("number \(e) from \(self)")
	}

and then push/pop `SignalViewController`, the `SignalViewController` still get deallocated successfully.

We verified that

1. The signal was retained by the subscriber(yes, the implicit subscriber we create using `signal.subscribeNext`). If it is not retained by subscriber, the signal will deallocated immediately after alloc, because `var signal` is a weak variable, which means not retained by `SignalViewController`
2. we guesss both `signal` and subscriber are deallocated after the signal completed, because when we pop `SignalViewController`, and the `signal` is nil, although we access `self` in closure, the we didn't see any retain cycle here. We will try to verify that later

#### init signal when `viewDidDisappear`, and pop `SignalViewController` in `viewDidAppear`

the modified code is here

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.popViewControllerAnimated(false)
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        signal = ([1,2,3,4] as NSArray).rac_sequence.signal()
        signal.subscribeNext { (e) in
            println("number \(e) from \(self)")
        }
    }

we found the output is like this

	number 1 from <RACtest.SignalViewController: 0x7c880db0>
	number 2 from <RACtest.SignalViewController: 0x7c880db0>
	number 3 from <RACtest.SignalViewController: 0x7c880db0>
	number 4 from <RACtest.SignalViewController: 0x7c880db0>
	deinit SignalViewController, and signal is <RACDynamicSignal: 0x7c8833e0> name: 
	
`SignalViewController` was deallocated after signal complete


#### remove self access in closure

	signal.subscribeNext { (e) in
	    println("number \(e)")
	}
	
and the console output is 

	deinit SignalViewConnutmrboelrl e1r
	, and signal is <RACDynamicSignal: 0x79229600> name: 
	number 2
	number 3
	number 4

bingo, the subscriber retain `self`, and the `signal`, so when `SignalViewController` was deallocated, the `signal` is not nil, and `SignalViewController` was deallocated before subscriber complete


So, if the `signal` is an network access, when user pop the view controller????