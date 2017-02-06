//
//  Rule.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public enum RuleKind: String {
    case lint
    case idiomatic
    case style
    case metrics
    case performance
}

public protocol Rule {
    init() // Rules need to be able to be initialized with default values
    init(configuration: Any) throws
    static var description: RuleDescription { get }
    static var kind: RuleKind { get }
    func validate(file: File) -> [StyleViolation]
    func isEqualTo(_ rule: Rule) -> Bool
    var configurationDescription: String { get }
}

extension Rule {
    public func isEqualTo(_ rule: Rule) -> Bool {
        return type(of: self).description == type(of: rule).description
    }

    internal var cacheDescription: String {
        return (self as? CacheDescriptionProvider)?.cacheDescription ?? configurationDescription
    }
}

public protocol OptInRule: Rule {}

public protocol ConfigurationProviderRule: Rule {
    associatedtype ConfigurationType: RuleConfiguration
    var configuration: ConfigurationType { get set }
}

public protocol CorrectableRule: Rule {
    func correct(file: File) -> [Correction]
}

public protocol SourceKitFreeRule: Rule {}

// MARK: - ConfigurationProviderRule conformance to Configurable

public extension ConfigurationProviderRule {
    public init(configuration: Any) throws {
        self.init()
        try self.configuration.apply(configuration: configuration)
    }

    public func isEqualTo(_ rule: Rule) -> Bool {
        if let rule = rule as? Self {
            return configuration.isEqualTo(rule.configuration)
        }
        return false
    }

    public var configurationDescription: String {
        return configuration.consoleDescription
    }
}

// MARK: - == Implementations

public func == (lhs: [Rule], rhs: [Rule]) -> Bool {
    if lhs.count == rhs.count {
        return zip(lhs, rhs).map { $0.isEqualTo($1) }.reduce(true) { $0 && $1 }
    }

    return false
}
