//
//  Models.swift
//  MyMacLLAMA
//
//  Created by Carlos Mbendera on 25/04/2024.
//  Modified by Zac Reeves on 4/09/2024.
//

import Foundation

// Struct to decode the JSON response
struct Response: Codable {
    let model: String
    let response: String
}

// Define a struct that conforms to Identifiable and Hashable
struct HistoryEntry: Identifiable, Hashable {
    let id = UUID()  // Unique identifier
    let prompt: String
    let response: String
}

// Class for managing application data and network communication
class DataInterface: ObservableObject, Observable {

    // Store the current prompt as a modifiable string
    @Published var prompt: String = ""
    // Store the response to the prompt as a modifiable string
    @Published var response: String = ""
    // Track whether a network request is currently being sent
    @Published var isSending: Bool = false
    // Store previous responses
    @Published var previousResponses: [HistoryEntry] = []

    // Function to handle sending the prompt to a server
    func sendPrompt() {
        print("Started Send Prompt")  // Log the start of sending a prompt
        // Prevent sending if the prompt is empty or a request is already in progress
        guard !prompt.isEmpty, !isSending else { return }
        isSending = true  // Mark that a sending process has started

        // Combine previous responses into a single prompt in an attempt at context, no limit to length though
        let combinedPrompt = previousResponses.map { $0.prompt + "\n" + $0.response }.joined(separator: "\n") + "\n" + prompt

        // Define the server endpoint
        let urlString = "http://127.0.0.1:11434/api/generate"
        // Safely unwrap the URL constructed from the urlString
        guard let url = URL(string: urlString) else { return }

        // Prepare the network request with the URL
        var request = URLRequest(url: url)
        request.httpMethod = "POST"  // Set the HTTP method to POST
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")  // Set the content type to JSON
        let body: [String: Any] = [
            "model": "llama3.1",  // Specify the model to be used
            "prompt": combinedPrompt,  // Pass the combined prompt
            "options": [
                "num_ctx": 16000  // Specify context options
            ]
        ]
        // Encode the request body as JSON
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        // Start the data task with the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { DispatchQueue.main.async { self.isSending = false } }  // Ensure isSending is reset after operation
            if let error = error {
                DispatchQueue.main.async { self.response = "Error: \(error.localizedDescription)" }  // Handle errors by updating the response
                return
            }

            // Ensure data was received
            guard let data = data else {
                DispatchQueue.main.async { self.response = "No data received" }  // Handle the absence of data
                return
            }

            let decoder = JSONDecoder()  // Initialize JSON decoder
            let lines = data.split(separator: 10)  // Split the data into lines
            var responses = [String]()  // Array to hold the decoded responses

            // Iterate over each line of data
            for line in lines {
                if let jsonLine = try? decoder.decode(Response.self, from: Data(line)) {
                    responses.append(jsonLine.response)  // Decode each line and append the response
                }
            }

            DispatchQueue.main.async {
                // Update the previous responses array
                self.response = responses.joined(separator: "")  // Combine all responses into one string
                let newEntry = HistoryEntry(prompt: self.prompt, response: self.response) // Create newEntry to add to history
                self.previousResponses.append(newEntry) // Add the new combined response to history
                print(self.response)  // Print the full response
            }
        }.resume()  // Resume the task if it was suspended
    }
}
