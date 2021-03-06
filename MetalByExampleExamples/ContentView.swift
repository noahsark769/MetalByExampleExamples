//
//  ContentView.swift
//  MetalByExampleExamples
//
//  Created by Noah Gilmore on 10/26/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

import MetalKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: ChapterTwo()) { Text("Chapter Two") }
                NavigationLink(destination: ChapterThree()) { Text("Chapter Three") }
                NavigationLink(destination: ChapterFour()) { Text("Chapter Four") }
            }.listStyle(SidebarListStyle())
        }.frame(minWidth: 1000, minHeight: 700)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
