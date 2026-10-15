// Tuist/Config.swift
import ProjectDescription

let config = Config(
    compatibleXcodeVersions: .list([.upToNextMajor("26.0"), .upToNextMajor("27.0")]),
    swiftVersion: "6.0"
)
