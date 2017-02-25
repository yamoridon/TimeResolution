//
//  ViewController.swift
//  TimeResolution
//
//  Created by Kazuki Ohara on 2017/02/25.
//  Copyright © 2017年 Kazuki Ohara. All rights reserved.
//

import UIKit
import Darwin

class ViewController: UIViewController {

    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func buttonTapped(_ sender: UIButton) {
        activityIndicator.startAnimating()
        button.isEnabled = false
        textView.text = "measuring..."

        DispatchQueue.global(qos: .userInteractive).async {
            typealias VC = ViewController

            let texts = [
                "Date: \(VC.measureDateResolution() * 1000_000) us",
                "time(): \(VC.measureTimeResolution() * 1000_000) us",
                "gettimeofday(): \(VC.measureGetTimeOfDayResolution() * 1000_000) us",
                "clock_gettime(): \(VC.measureClockGetTimeResolution() * 1000_000) us",
                "clock_gettime_nsec_np(): \(VC.measureClockGetTimeNsecNpResolution() * 1000_000) us",
                "mach_absolute_time(): \(VC.measureMachAbsoluteTimeResolution() * 1000_000) us"
            ]

            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.textView.text = texts.joined(separator: "\n")
                self.button.isEnabled = true
                texts.forEach { NSLog($0) }
            }
        }
    }

    static func measureDateResolution() -> Double {
        var count = 0
        var sum = TimeInterval(0)

        var next = Date()
        var last = Date()
        while count < 100_000 {
            next = Date()
            if next != last {
                count += 1
                sum += next.timeIntervalSince(last)
            }
            last = next
        }

        return Double(sum) / Double(count)
    }

    static func measureTimeResolution() -> Double {
        var count = 0
        var sum = time_t()

        var next = time_t()
        var last = time(nil)
        while count < 10 {
            next = time(nil)
            if next != last {
                count += 1
                sum += next - last
            }
            last = next
        }

        return Double(sum) / Double(count)
    }

    static func measureGetTimeOfDayResolution() -> Double {
        var count = 0
        var sum = 0

        var next = timeval()
        var last = timeval()
        gettimeofday(&last, nil)
        while count < 100_000 {
            gettimeofday(&next, nil)
            if next.tv_sec != last.tv_sec || next.tv_usec != last.tv_usec {
                count += 1
                let lastUsec = last.tv_sec * 1000_000 + Int(last.tv_usec)
                let nextUsec = next.tv_sec * 1000_000 + Int(next.tv_usec)
                sum += nextUsec - lastUsec
            }
            last = next
        }

        return Double(sum) / (Double(count) * Double(1000_000))
    }

    static func measureClockGetTimeResolution() -> Double {
        var count = 0
        var sum = 0

        var next = timespec()
        var last = timespec()
        clock_gettime(_CLOCK_REALTIME, &last)
        let startSec = last.tv_sec
        while count < 100_000 {
            clock_gettime(_CLOCK_REALTIME, &next)
            if next.tv_sec != last.tv_sec || next.tv_nsec != last.tv_nsec {
                count += 1
                // subtract startSec to avoid overflow
                let lastNsec = (last.tv_sec - startSec) * 1000_000_000 + last.tv_nsec
                let nextNsec = (next.tv_sec - startSec) * 1000_000_000 + next.tv_nsec
                sum += nextNsec - lastNsec
            }
            last = next
        }

        return Double(sum) / (Double(count) * Double(1000_000_000))
    }

    static func measureClockGetTimeNsecNpResolution() -> Double {
        var count = 0
        var sum = UInt64(0)

        var next = UInt64(0)
        var last = clock_gettime_nsec_np(_CLOCK_REALTIME)
        while count < 100_000 {
            next = clock_gettime_nsec_np(_CLOCK_REALTIME)
            if next != last {
                count += 1
                sum += next - last
            }
            last = next
        }

        return Double(sum) / (Double(count) * Double(1000_000_000))
    }

    static func measureMachAbsoluteTimeResolution() -> Double {
        var count = 0
        var sum = UInt64(0)

        var next = UInt64(0)
        var last = mach_absolute_time()
        while count < 100_000 {
            next = mach_absolute_time()
            if next != last {
                count += 1
                sum += next - last
            }
            last = next
        }

        var timeBase = mach_timebase_info()
        mach_timebase_info(&timeBase)
        let numer = Double(timeBase.numer)
        let demon = Double(timeBase.denom)

        return (Double(sum) * numer / demon) / (Double(count) * Double(1000_000_000))
    }

}
