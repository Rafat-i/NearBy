//
//  TimeFormatter.swift
//  NearBy
//
//  Created by Ace of Heart on 2026-02-21.
//

import Foundation

func TimeFormat(time: Double) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .abbreviated
    return formatter.string(from: time) ?? "00:00"
}
