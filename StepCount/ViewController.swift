//
//  ViewController.swift
//  StepCount
//
//  Created by Luyuan Nathan on 6/30/19.
//  Copyright © 2019 Luyuan Nathan. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    
    @IBOutlet weak var dateSelectorButton: UIButton!
    @IBOutlet weak var stepCountLabel: UILabel!
    let datePicker = UIDatePicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDatePicker()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        requestAuthorization { (success, error) in
            if success {
                self.updateLabel()
            }
            if let error = error {
                print("there's an authorization error: \(error)")
            }
        }
    }
    
    func setupDatePicker() {
        datePicker.backgroundColor = UIColor.white
        datePicker.autoresizingMask = .flexibleWidth
        datePicker.frame = CGRect(x: 0.0, y: UIScreen.main.bounds.size.height - 300, width: UIScreen.main.bounds.size.width, height: 300)
        
        datePicker.datePickerMode = .date
        datePicker.maximumDate = Date()
        datePicker.addTarget(self, action: #selector(updateButton(sender:)), for: .valueChanged)
    }
    
    @objc func updateButton(sender: UIDatePicker) {
        updateLabel(for: sender.date)
    }
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Swift.Void) {
        let healthKitTypesToRead: Set<HKObjectType> = [HKQuantityType.quantityType(forIdentifier: .stepCount)!]
        HKHealthStore().requestAuthorization(toShare: [], read: healthKitTypesToRead) { (success, error) in
            completion(success, error)
        }
    }
    
    func updateLabel(for date: Date = Date()) {
        getSteps(for: date) { (stepCount) in
            DispatchQueue.main.async {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .none
                self.dateSelectorButton.setTitle(dateFormatter.string(from: date), for: .normal)
                
                self.stepCountLabel.text = "\(Int(stepCount))"
            }
        }
    }
    
    func getSteps(for date: Date, completion: @escaping (Double) -> Void) {
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("there's a query error: \(error)")
                completion(0.0)
                return
            }
            completion(sum.doubleValue(for: HKUnit.count()))
        }
        HKHealthStore().execute(query)
    }

    @IBAction func dateSelectorTapped(_ sender: Any) {
        if datePicker.superview == nil {
            view.addSubview(datePicker)
        } else {
            datePicker.removeFromSuperview()
        }
    }
}

