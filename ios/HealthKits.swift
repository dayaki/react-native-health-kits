import Foundation
import HealthKit

@objc(HealthKits)
class HealthKits: RCTEventEmitter {
    
    private let healthStore = HKHealthStore()
    private var activeQueries: [String: HKQuery] = [:]
    private var hasListeners = false
    
    override init() {
        super.init()
    }
    
    @objc override static func requiresMainQueueSetup() -> Bool {
        return false
    }
    
    override func supportedEvents() -> [String]! {
        return [
            "HealthKits_steps_update",
            "HealthKits_heartRate_update",
            "HealthKits_weight_update",
            "HealthKits_sleep_update",
            "HealthKits_workout_update"
        ]
    }
    
    override func startObserving() {
        hasListeners = true
    }
    
    override func stopObserving() {
        hasListeners = false
    }
    
    // MARK: - isAvailable
    
    @objc(isAvailable:reject:)
    func isAvailable(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        resolve(HKHealthStore.isHealthDataAvailable())
    }
    
    // MARK: - requestPermissions
    
    @objc(requestPermissions:resolve:reject:)
    func requestPermissions(_ permissionsJson: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard HKHealthStore.isHealthDataAvailable() else {
            reject("NOT_AVAILABLE", "HealthKit is not available on this device", nil)
            return
        }
        
        guard let data = permissionsJson.data(using: .utf8),
              let permissions = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
            reject("INVALID_PARAMETERS", "Invalid permissions format", nil)
            return
        }
        
        var readTypes = Set<HKObjectType>()
        var writeTypes = Set<HKSampleType>()
        
        for permission in permissions {
            guard let typeString = permission["type"],
                  let access = permission["access"] else { continue }
            
            if let hkType = getHKObjectType(for: typeString) {
                if access == "read" {
                    readTypes.insert(hkType)
                } else if access == "write", let sampleType = hkType as? HKSampleType {
                    writeTypes.insert(sampleType)
                }
            }
        }
        
        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
            if let error = error {
                reject("PERMISSION_DENIED", error.localizedDescription, error)
            } else {
                resolve(success)
            }
        }
    }
    
    // MARK: - getPermissionStatus
    
    @objc(getPermissionStatus:accessType:resolve:reject:)
    func getPermissionStatus(_ dataType: String, accessType: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard let hkType = getHKObjectType(for: dataType) else {
            reject("UNSUPPORTED_DATA_TYPE", "Unsupported data type: \(dataType)", nil)
            return
        }
        
        if accessType == "write", let sampleType = hkType as? HKSampleType {
            let status = healthStore.authorizationStatus(for: sampleType)
            switch status {
            case .sharingAuthorized:
                resolve("authorized")
            case .sharingDenied:
                resolve("denied")
            case .notDetermined:
                resolve("notDetermined")
            @unknown default:
                resolve("notDetermined")
            }
        } else {
            // For read permissions, HealthKit doesn't reveal if denied for privacy
            // We can only check if we've requested authorization
            resolve("notDetermined")
        }
    }
    
    // MARK: - readData
    
    @objc(readData:resolve:reject:)
    func readData(_ optionsJson: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard let data = optionsJson.data(using: .utf8),
              let options = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let typeString = options["type"] as? String,
              let startDateString = options["startDate"] as? String,
              let endDateString = options["endDate"] as? String else {
            reject("INVALID_PARAMETERS", "Invalid options format", nil)
            return
        }
        
        guard let startDate = ISO8601DateFormatter().date(from: startDateString),
              let endDate = ISO8601DateFormatter().date(from: endDateString) else {
            reject("INVALID_PARAMETERS", "Invalid date format", nil)
            return
        }
        
        let limit = options["limit"] as? Int ?? HKObjectQueryNoLimit
        let aggregate = options["aggregate"] as? Bool ?? false
        
        if typeString == "sleep" {
            readSleepData(startDate: startDate, endDate: endDate, limit: limit, resolve: resolve, reject: reject)
        } else if typeString == "workout" {
            readWorkoutData(startDate: startDate, endDate: endDate, limit: limit, resolve: resolve, reject: reject)
        } else if aggregate {
            guard isCumulativeType(typeString) else {
                reject("UNSUPPORTED_DATA_TYPE", "Aggregation is only supported for cumulative types (steps, distance, activeCalories, totalCalories, floorsClimbed, hydration). '\(typeString)' is not a cumulative type; read raw records and aggregate in app code, or omit `aggregate`.", nil)
                return
            }
            let interval = options["aggregateInterval"] as? String ?? "day"
            readAggregatedData(type: typeString, startDate: startDate, endDate: endDate, interval: interval, resolve: resolve, reject: reject)
        } else {
            readQuantityData(type: typeString, startDate: startDate, endDate: endDate, limit: limit, resolve: resolve, reject: reject)
        }
    }
    
    // MARK: - writeData
    
    @objc(writeData:resolve:reject:)
    func writeData(_ dataJson: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard let data = dataJson.data(using: .utf8),
              let writeData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let typeString = writeData["type"] as? String,
              let dateString = writeData["date"] as? String else {
            reject("INVALID_PARAMETERS", "Invalid data format", nil)
            return
        }
        
        guard let date = ISO8601DateFormatter().date(from: dateString) else {
            reject("INVALID_PARAMETERS", "Invalid date format", nil)
            return
        }
        
        if typeString == "workout" {
            writeWorkoutData(data: writeData, startDate: date, resolve: resolve, reject: reject)
        } else if typeString == "sleep" {
            writeSleepData(data: writeData, startDate: date, resolve: resolve, reject: reject)
        } else {
            writeQuantityData(type: typeString, data: writeData, date: date, resolve: resolve, reject: reject)
        }
    }
    
    // MARK: - subscribeToUpdates
    
    @objc(subscribeToUpdates:resolve:reject:)
    func subscribeToUpdates(_ dataType: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard let sampleType = getHKSampleType(for: dataType) else {
            reject("UNSUPPORTED_DATA_TYPE", "Unsupported data type: \(dataType)", nil)
            return
        }
        
        let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                print("Observer query error: \(error.localizedDescription)")
                completionHandler()
                return
            }
            
            self?.fetchLatestData(for: dataType, sampleType: sampleType)
            completionHandler()
        }
        
        activeQueries[dataType] = query
        healthStore.execute(query)
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate) { success, error in
            if let error = error {
                print("Background delivery error: \(error.localizedDescription)")
            }
        }
        
        resolve(dataType)
    }
    
    // MARK: - unsubscribeFromUpdates
    
    @objc(unsubscribeFromUpdates:resolve:reject:)
    func unsubscribeFromUpdates(_ subscriptionId: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        if let query = activeQueries[subscriptionId] {
            healthStore.stop(query)
            activeQueries.removeValue(forKey: subscriptionId)
        }
        resolve(nil)
    }
    
    // MARK: - openHealthConnectSettings (no-op on iOS)
    
    @objc(openHealthConnectSettings:reject:)
    func openHealthConnectSettings(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        // No-op on iOS - Health settings are managed in Settings app
        resolve(nil)
    }
    
    // MARK: - Private Helper Methods
    
    private func getHKObjectType(for typeString: String) -> HKObjectType? {
        switch typeString {
        case "steps":
            return HKQuantityType.quantityType(forIdentifier: .stepCount)
        case "distance":
            return HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
        case "activeCalories":
            return HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        case "totalCalories":
            return HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)
        case "floorsClimbed":
            return HKQuantityType.quantityType(forIdentifier: .flightsClimbed)
        case "heartRate":
            return HKQuantityType.quantityType(forIdentifier: .heartRate)
        case "restingHeartRate":
            return HKQuantityType.quantityType(forIdentifier: .restingHeartRate)
        case "heartRateVariability":
            return HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
        case "bloodPressureSystolic":
            return HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)
        case "bloodPressureDiastolic":
            return HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)
        case "bloodGlucose":
            return HKQuantityType.quantityType(forIdentifier: .bloodGlucose)
        case "oxygenSaturation":
            return HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)
        case "bodyTemperature":
            return HKQuantityType.quantityType(forIdentifier: .bodyTemperature)
        case "respiratoryRate":
            return HKQuantityType.quantityType(forIdentifier: .respiratoryRate)
        case "weight":
            return HKQuantityType.quantityType(forIdentifier: .bodyMass)
        case "height":
            return HKQuantityType.quantityType(forIdentifier: .height)
        case "bodyFatPercentage":
            return HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)
        case "bmi":
            return HKQuantityType.quantityType(forIdentifier: .bodyMassIndex)
        case "leanBodyMass":
            return HKQuantityType.quantityType(forIdentifier: .leanBodyMass)
        case "sleep":
            return HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)
        case "workout":
            return HKWorkoutType.workoutType()
        case "hydration":
            return HKQuantityType.quantityType(forIdentifier: .dietaryWater)
        default:
            return nil
        }
    }
    
    private func getHKSampleType(for typeString: String) -> HKSampleType? {
        return getHKObjectType(for: typeString) as? HKSampleType
    }

    /// Aggregation (cumulative sum per interval) only has a well-defined meaning
    /// for cumulative quantity types. Instantaneous types (heart rate, weight,
    /// blood glucose, etc.) must be read as raw records instead.
    private func isCumulativeType(_ typeString: String) -> Bool {
        switch typeString {
        case "steps", "distance", "activeCalories", "totalCalories", "floorsClimbed", "hydration":
            return true
        default:
            return false
        }
    }
    
    private func getHKUnit(for typeString: String) -> HKUnit {
        switch typeString {
        case "steps", "floorsClimbed":
            return .count()
        case "distance", "height":
            return .meter()
        case "activeCalories", "totalCalories":
            return .kilocalorie()
        case "heartRate", "restingHeartRate":
            return HKUnit.count().unitDivided(by: .minute())
        case "heartRateVariability":
            return .secondUnit(with: .milli)
        case "bloodPressureSystolic", "bloodPressureDiastolic":
            return .millimeterOfMercury()
        case "bloodGlucose":
            return HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
        case "oxygenSaturation", "bodyFatPercentage":
            return .percent()
        case "bodyTemperature":
            return .degreeCelsius()
        case "respiratoryRate":
            return HKUnit.count().unitDivided(by: .minute())
        case "weight", "leanBodyMass":
            return .gramUnit(with: .kilo)
        case "bmi":
            return .count()
        case "hydration":
            return .liter()
        default:
            return .count()
        }
    }
    
    private func readQuantityData(type: String, startDate: Date, endDate: Date, limit: Int, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard let quantityType = getHKSampleType(for: type) as? HKQuantityType else {
            reject("UNSUPPORTED_DATA_TYPE", "Unsupported data type: \(type)", nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: limit, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            if let error = error {
                reject("READ_FAILED", error.localizedDescription, error)
                return
            }
            
            guard let self = self, let samples = samples as? [HKQuantitySample] else {
                resolve("[]")
                return
            }
            
            let unit = self.getHKUnit(for: type)
            let unitString = self.getUnitString(for: type)
            let formatter = ISO8601DateFormatter()
            
            let results: [[String: Any]] = samples.map { sample in
                return [
                    "id": sample.uuid.uuidString,
                    "type": type,
                    "value": sample.quantity.doubleValue(for: unit),
                    "unit": unitString,
                    "startDate": formatter.string(from: sample.startDate),
                    "endDate": formatter.string(from: sample.endDate),
                    "sourceName": sample.sourceRevision.source.name,
                    "sourceId": sample.sourceRevision.source.bundleIdentifier
                ]
            }
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: results),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                resolve(jsonString)
            } else {
                resolve("[]")
            }
        }
        
        healthStore.execute(query)
    }
    
    private func readAggregatedData(type: String, startDate: Date, endDate: Date, interval: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard let quantityType = getHKSampleType(for: type) as? HKQuantityType else {
            reject("UNSUPPORTED_DATA_TYPE", "Unsupported data type: \(type)", nil)
            return
        }
        
        var dateComponents = DateComponents()
        switch interval {
        case "hour":
            dateComponents.hour = 1
        case "week":
            dateComponents.day = 7
        case "month":
            dateComponents.month = 1
        default:
            dateComponents.day = 1
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType,
            quantitySamplePredicate: predicate,
            options: [.cumulativeSum],
            anchorDate: startDate,
            intervalComponents: dateComponents
        )
        
        query.initialResultsHandler = { [weak self] query, results, error in
            if let error = error {
                reject("READ_FAILED", error.localizedDescription, error)
                return
            }
            
            guard let self = self, let results = results else {
                resolve("[]")
                return
            }
            
            let unit = self.getHKUnit(for: type)
            let unitString = self.getUnitString(for: type)
            let formatter = ISO8601DateFormatter()
            
            var aggregatedResults: [[String: Any]] = []
            
            results.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                if let sum = statistics.sumQuantity() {
                    aggregatedResults.append([
                        "id": UUID().uuidString,
                        "type": type,
                        "value": sum.doubleValue(for: unit),
                        "unit": unitString,
                        "startDate": formatter.string(from: statistics.startDate),
                        "endDate": formatter.string(from: statistics.endDate),
                        "sourceName": "Aggregated",
                        "sourceId": "aggregated"
                    ])
                }
            }
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: aggregatedResults),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                resolve(jsonString)
            } else {
                resolve("[]")
            }
        }
        
        healthStore.execute(query)
    }
    
    private func readSleepData(startDate: Date, endDate: Date, limit: Int, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            reject("UNSUPPORTED_DATA_TYPE", "Sleep analysis not available", nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: limit, sortDescriptors: [sortDescriptor]) { query, samples, error in
            if let error = error {
                reject("READ_FAILED", error.localizedDescription, error)
                return
            }
            
            guard let samples = samples as? [HKCategorySample] else {
                resolve("[]")
                return
            }
            
            let formatter = ISO8601DateFormatter()
            
            // Group samples by source and time proximity to create sleep sessions
            var sleepSessions: [[String: Any]] = []
            var currentSession: [HKCategorySample] = []
            var lastEndDate: Date?
            
            let sortedSamples = samples.sorted { $0.startDate < $1.startDate }
            
            for sample in sortedSamples {
                if let lastEnd = lastEndDate, sample.startDate.timeIntervalSince(lastEnd) > 3600 {
                    // More than 1 hour gap, start new session
                    if !currentSession.isEmpty {
                        sleepSessions.append(self.createSleepSession(from: currentSession, formatter: formatter))
                    }
                    currentSession = [sample]
                } else {
                    currentSession.append(sample)
                }
                lastEndDate = sample.endDate
            }
            
            if !currentSession.isEmpty {
                sleepSessions.append(self.createSleepSession(from: currentSession, formatter: formatter))
            }
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: sleepSessions),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                resolve(jsonString)
            } else {
                resolve("[]")
            }
        }
        
        healthStore.execute(query)
    }
    
    private func createSleepSession(from samples: [HKCategorySample], formatter: ISO8601DateFormatter) -> [String: Any] {
        guard let firstSample = samples.first, let lastSample = samples.last else {
            return [:]
        }
        
        let startDate = samples.map { $0.startDate }.min() ?? firstSample.startDate
        let endDate = samples.map { $0.endDate }.max() ?? lastSample.endDate
        let duration = endDate.timeIntervalSince(startDate) / 60 // in minutes
        
        let stages: [[String: Any]] = samples.map { sample in
            let stage = mapSleepStage(value: sample.value)
            return [
                "stage": stage,
                "startDate": formatter.string(from: sample.startDate),
                "endDate": formatter.string(from: sample.endDate),
                "duration": sample.endDate.timeIntervalSince(sample.startDate) / 60
            ]
        }
        
        return [
            "id": firstSample.uuid.uuidString,
            "type": "sleep",
            "startDate": formatter.string(from: startDate),
            "endDate": formatter.string(from: endDate),
            "duration": duration,
            "stages": stages,
            "sourceName": firstSample.sourceRevision.source.name,
            "sourceId": firstSample.sourceRevision.source.bundleIdentifier
        ]
    }
    
    private func mapSleepStage(value: Int) -> String {
        switch value {
        case 0: return "inBed"
        case 1: return "asleep"
        case 2: return "awake"
        case 3: return "light"
        case 4: return "deep"
        case 5: return "rem"
        default: return "unknown"
        }
    }
    
    private func readWorkoutData(startDate: Date, endDate: Date, limit: Int, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        let workoutType = HKWorkoutType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: limit, sortDescriptors: [sortDescriptor]) { query, samples, error in
            if let error = error {
                reject("READ_FAILED", error.localizedDescription, error)
                return
            }
            
            guard let workouts = samples as? [HKWorkout] else {
                resolve("[]")
                return
            }
            
            let formatter = ISO8601DateFormatter()
            
            let results: [[String: Any]] = workouts.map { workout in
                var result: [String: Any] = [
                    "id": workout.uuid.uuidString,
                    "type": "workout",
                    "workoutType": self.mapWorkoutType(activityType: workout.workoutActivityType),
                    "startDate": formatter.string(from: workout.startDate),
                    "endDate": formatter.string(from: workout.endDate),
                    "duration": workout.duration / 60, // in minutes
                    "sourceName": workout.sourceRevision.source.name,
                    "sourceId": workout.sourceRevision.source.bundleIdentifier
                ]
                
                if let energy = workout.totalEnergyBurned {
                    result["totalEnergyBurned"] = energy.doubleValue(for: .kilocalorie())
                }
                
                if let distance = workout.totalDistance {
                    result["totalDistance"] = distance.doubleValue(for: .meter())
                }
                
                return result
            }
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: results),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                resolve(jsonString)
            } else {
                resolve("[]")
            }
        }
        
        healthStore.execute(query)
    }
    
    private func mapWorkoutType(activityType: HKWorkoutActivityType) -> String {
        switch activityType {
        case .walking: return "walking"
        case .running: return "running"
        case .cycling: return "cycling"
        case .swimming: return "swimming"
        case .hiking: return "hiking"
        case .yoga: return "yoga"
        case .functionalStrengthTraining: return "functionalStrengthTraining"
        case .traditionalStrengthTraining: return "traditionalStrengthTraining"
        case .dance: return "dance"
        case .elliptical: return "elliptical"
        case .rowing: return "rowing"
        case .stairClimbing: return "stairClimbing"
        case .highIntensityIntervalTraining: return "highIntensityIntervalTraining"
        case .jumpRope: return "jumpRope"
        case .pilates: return "pilates"
        case .soccer: return "soccer"
        case .basketball: return "basketball"
        case .tennis: return "tennis"
        case .badminton: return "badminton"
        case .martialArts: return "martialArts"
        case .golf: return "golf"
        case .baseball: return "baseball"
        case .softball: return "softball"
        case .volleyball: return "volleyball"
        case .tableTennis: return "tableTennis"
        case .skating: return "skating"
        case .crossCountrySkiing: return "crossCountrySkiing"
        case .downhillSkiing: return "downhillSkiing"
        case .snowboarding: return "snowboarding"
        case .surfingSports: return "surfing"
        case .waterPolo: return "waterPolo"
        default: return "other"
        }
    }
    
    private func writeQuantityData(type: String, data: [String: Any], date: Date, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard let quantityType = getHKSampleType(for: type) as? HKQuantityType,
              let value = data["value"] as? Double else {
            reject("INVALID_PARAMETERS", "Invalid data for quantity type", nil)
            return
        }
        
        let unit = getHKUnit(for: type)
        let quantity = HKQuantity(unit: unit, doubleValue: value)
        
        var endDate = date
        if let endDateString = data["endDate"] as? String,
           let parsedEndDate = ISO8601DateFormatter().date(from: endDateString) {
            endDate = parsedEndDate
        }
        
        let sample = HKQuantitySample(type: quantityType, quantity: quantity, start: date, end: endDate)
        
        healthStore.save(sample) { success, error in
            if let error = error {
                reject("WRITE_FAILED", error.localizedDescription, error)
            } else {
                resolve(success)
            }
        }
    }
    
    private func writeWorkoutData(data: [String: Any], startDate: Date, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard let workoutTypeString = data["workoutType"] as? String,
              let endDateString = data["endDate"] as? String,
              let endDate = ISO8601DateFormatter().date(from: endDateString) else {
            reject("INVALID_PARAMETERS", "Invalid workout data", nil)
            return
        }
        
        let activityType = mapStringToWorkoutType(workoutTypeString)
        
        var totalEnergyBurned: HKQuantity?
        if let energy = data["totalEnergyBurned"] as? Double {
            totalEnergyBurned = HKQuantity(unit: .kilocalorie(), doubleValue: energy)
        }
        
        var totalDistance: HKQuantity?
        if let distance = data["totalDistance"] as? Double {
            totalDistance = HKQuantity(unit: .meter(), doubleValue: distance)
        }
        
        let workout = HKWorkout(
            activityType: activityType,
            start: startDate,
            end: endDate,
            duration: endDate.timeIntervalSince(startDate),
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            metadata: nil
        )
        
        healthStore.save(workout) { success, error in
            if let error = error {
                reject("WRITE_FAILED", error.localizedDescription, error)
            } else {
                resolve(success)
            }
        }
    }
    
    private func writeSleepData(data: [String: Any], startDate: Date, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis),
              let endDateString = data["endDate"] as? String,
              let endDate = ISO8601DateFormatter().date(from: endDateString) else {
            reject("INVALID_PARAMETERS", "Invalid sleep data", nil)
            return
        }
        
        // Default to asleep if no stages provided
        let sample = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            start: startDate,
            end: endDate
        )
        
        healthStore.save(sample) { success, error in
            if let error = error {
                reject("WRITE_FAILED", error.localizedDescription, error)
            } else {
                resolve(success)
            }
        }
    }
    
    private func mapStringToWorkoutType(_ typeString: String) -> HKWorkoutActivityType {
        switch typeString {
        case "walking": return .walking
        case "running": return .running
        case "cycling": return .cycling
        case "swimming": return .swimming
        case "hiking": return .hiking
        case "yoga": return .yoga
        case "strengthTraining", "functionalStrengthTraining": return .functionalStrengthTraining
        case "traditionalStrengthTraining": return .traditionalStrengthTraining
        case "dance": return .dance
        case "elliptical": return .elliptical
        case "rowing": return .rowing
        case "stairClimbing": return .stairClimbing
        case "highIntensityIntervalTraining": return .highIntensityIntervalTraining
        case "jumpRope": return .jumpRope
        case "pilates": return .pilates
        case "soccer": return .soccer
        case "basketball": return .basketball
        case "tennis": return .tennis
        case "badminton": return .badminton
        case "martialArts": return .martialArts
        case "golf": return .golf
        case "baseball": return .baseball
        case "softball": return .softball
        case "volleyball": return .volleyball
        case "tableTennis": return .tableTennis
        case "skating": return .skating
        case "crossCountrySkiing": return .crossCountrySkiing
        case "downhillSkiing": return .downhillSkiing
        case "snowboarding": return .snowboarding
        case "surfing": return .surfingSports
        case "waterPolo": return .waterPolo
        default: return .other
        }
    }
    
    private func getUnitString(for type: String) -> String {
        switch type {
        case "steps", "floorsClimbed", "bmi":
            return "count"
        case "distance", "height":
            return "meters"
        case "activeCalories", "totalCalories":
            return "kcal"
        case "heartRate", "restingHeartRate", "respiratoryRate":
            return "bpm"
        case "heartRateVariability":
            return "seconds"
        case "bloodPressureSystolic", "bloodPressureDiastolic":
            return "mmHg"
        case "bloodGlucose":
            return "mgdL"
        case "oxygenSaturation", "bodyFatPercentage":
            return "percent"
        case "bodyTemperature":
            return "celsius"
        case "weight", "leanBodyMass":
            return "kg"
        case "hydration":
            return "liters"
        default:
            return "count"
        }
    }
    
    private func fetchLatestData(for dataType: String, sampleType: HKSampleType) {
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-3600), end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: 10, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            guard let self = self, self.hasListeners, let samples = samples else { return }
            
            let formatter = ISO8601DateFormatter()
            var results: [[String: Any]] = []
            
            if let quantitySamples = samples as? [HKQuantitySample] {
                let unit = self.getHKUnit(for: dataType)
                let unitString = self.getUnitString(for: dataType)
                
                results = quantitySamples.map { sample in
                    return [
                        "id": sample.uuid.uuidString,
                        "type": dataType,
                        "value": sample.quantity.doubleValue(for: unit),
                        "unit": unitString,
                        "startDate": formatter.string(from: sample.startDate),
                        "endDate": formatter.string(from: sample.endDate),
                        "sourceName": sample.sourceRevision.source.name,
                        "sourceId": sample.sourceRevision.source.bundleIdentifier
                    ]
                }
            }
            
            if !results.isEmpty,
               let jsonData = try? JSONSerialization.data(withJSONObject: results),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                self.sendEvent(withName: "HealthKits_\(dataType)_update", body: ["data": jsonString])
            }
        }
        
        healthStore.execute(query)
    }
}
