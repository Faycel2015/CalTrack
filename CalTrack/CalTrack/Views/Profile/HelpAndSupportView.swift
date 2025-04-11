//
//  HelpAndSupportView.swift
//  CalTrack
//
//  Created by FayTek on 4/11/25.
//

import SwiftUI

import SwiftUI

struct HelpAndSupportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Frequently Asked Questions
                Section(header: Text("FAQs")) {
                    NavigationLink("Getting Started", destination: FAQDetailView(title: "Getting Started"))
                    NavigationLink("Tracking Meals", destination: FAQDetailView(title: "Tracking Meals"))
                    NavigationLink("Nutrition Goals", destination: FAQDetailView(title: "Nutrition Goals"))
                }
                
                // Contact & Support
                Section(header: Text("Support")) {
                    ContactMethodView(
                        icon: "envelope",
                        title: "Email Support",
                        subtitle: "support@caltrack.app"
                    )
                    
                    ContactMethodView(
                        icon: "message",
                        title: "Live Chat",
                        subtitle: "Chat with our support team"
                    )
                    
                    ContactMethodView(
                        icon: "phone",
                        title: "Phone Support",
                        subtitle: "+1 (800) CALTRACK"
                    )
                }
                
                // Community & Resources
                Section(header: Text("Resources")) {
                    Link("Online Help Center", destination: URL(string: "https://caltrack.app/help")!)
                    Link("Community Forum", destination: URL(string: "https://forum.caltrack.app")!)
                    Link("YouTube Tutorials", destination: URL(string: "https://youtube.com/caltrack")!)
                }
                
                // Troubleshooting
                Section(header: Text("Troubleshooting")) {
                    NavigationLink("Reset App Data", destination: ResetDataView())
                    NavigationLink("Report a Bug", destination: BugReportView())
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Help & Support")
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
        }
    }
}

struct FAQDetailView: View {
    let title: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text(faqContent)
                    .padding()
            }
        }
        .navigationTitle(title)
    }
    
    private var faqContent: String {
        switch title {
        case "Getting Started":
            return "Welcome to CalTrack! To get started:\n1. Complete your profile\n2. Set your nutrition goals\n3. Start tracking your meals and progress"
        case "Tracking Meals":
            return "Track meals easily by:\n1. Using barcode scanner\n2. Manually entering food items\n3. Selecting from recent and favorite foods"
        case "Nutrition Goals":
            return "Set personalized nutrition goals based on:\n1. Your weight\n2. Activity level\n3. Specific health objectives"
        default:
            return "More information coming soon!"
        }
    }
}

struct ContactMethodView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct ResetDataView: View {
    var body: some View {
        Text("Reset Data View Placeholder")
    }
}

struct BugReportView: View {
    var body: some View {
        Text("Bug Report View Placeholder")
    }
}

#Preview {
    HelpAndSupportView()
}
