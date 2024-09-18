//
//  ContentView.swift
//  MyMacLLAMA
//
//  Created by Carlos Mbendera on 25/04/2024
//  Modified by Zac Reeves on 3/09/2024
//

import SwiftUI

struct ContentView: View {
    
    // Using the EnvironmentObject property wrapper to share data between this view and others
    @EnvironmentObject var appModel: DataInterface
    @State private var isExpanded: Bool = false
    @State private var isLoading: Bool = false
    @State private var showHistory: Bool = false
    
    var body: some View {
        VStack {
            // TextField for the user input
            TextField("Prompt", text: $appModel.prompt)
                .textFieldStyle(.roundedBorder)
                .frame(width: isExpanded ? 900 : 300)
                .onSubmit {
                    isLoading = true
                    appModel.sendPrompt() // Send the prompt to Ollama and get a response
                }
            
            Divider()
            
            // Use an if statement to conditionally display a view depending on if appModel.isSending
            if appModel.isSending{
                ProgressView() // Display a progress bar while waiting for a response
                    .padding()
                    .frame(width: isExpanded ? 900 : 300, height: isExpanded ? 700 : 50) // Ensure correct size during loading
            } else {
                // Conditionally display the history view
                if showHistory {
                    VStack {
                        Text("History")
                            .font(.headline)
                            .padding(5)
                        
                        Divider()
                        
                        ScrollView {
                            VStack(alignment: .leading) {
                                ForEach(appModel.previousResponses.reversed()) { entry in
                                    VStack(alignment: .leading) {
                                        Text("Prompt: \(entry.prompt)")
                                            .font(.headline)
                                            .padding(.bottom, 2)
                                        Text("Response: \(entry.response)")
                                            .padding(.bottom, 10)
                                    }
                                    .textSelection(.enabled)
                                }
                            }
                        }
                    }
                    .frame(width: isExpanded ? 900 : 300, height: isExpanded ? 700 : 300)
                    .transition(.slide)
                } else {
                    ScrollView {
                        Text(appModel.response) // Display the response text from appModel if not currently sending
                            .textSelection(.enabled)
                    }
                    .frame(width: isExpanded ? 900 : (appModel.response.isEmpty ? 0 : 300), height: isExpanded ? 700 : (appModel.response.isEmpty ? 0 : 300))
                    .onAppear {
                        isLoading = false
                    }
                }
            }
           
            HStack{
                // Button to send the current prompt. Triggers sendPrompt function when clicked
                Button("Send"){
                    appModel.sendPrompt()
                    appModel.prompt = ""
                }
                .keyboardShortcut(.return)
                
                // Button to clear the current prompt and response
                Button("Clear"){
                    // If history is open when clear is pressed, clear History
                    if showHistory {
                        appModel.previousResponses = []
                        showHistory.toggle()
                    }
                    appModel.prompt = "" // Clear the prompt string
                    appModel.response = "" // Clear the response string
                }
                .keyboardShortcut(.delete, modifiers: .command)
                
                // Button to show or hide the history view
                Button("History") {
                    if appModel.previousResponses.count > 0 {
                        showHistory.toggle()
                    }
                }
                .keyboardShortcut("h", modifiers: .command)
                
                // Button to expand menu bar app
                Button("Expand"){
                    isExpanded.toggle()
                }
                .keyboardShortcut("e", modifiers: .command)
                
                Divider()
                    .frame(height: 10)
                
                // Button to quit the menu bar app
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }
        .padding()
        .onReceive(appModel.$isSending) { _ in
            if appModel.isSending {
                showHistory = false
            }
        }
    }
}

#Preview {
    ContentView()
}
