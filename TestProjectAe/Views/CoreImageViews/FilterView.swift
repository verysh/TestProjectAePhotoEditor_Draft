//
//  FilterView.swift
//  TestProjectAe


import SwiftUI

import SwiftUI

struct FilterView: View {
    
    let filter: FilterOption
    
    var body: some View {
        VStack {
            Text(filter.name)
            .font(.headline)
            .foregroundColor(.white)
            .background(Color.clear)
        }
    }
}
