import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferencesService: PreferencesService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                // Lookahead Hours
                HStack {
                    Text("Lookahead Window:")
                        .frame(width: 140, alignment: .leading)
                    
                    Picker("", selection: $preferencesService.lookaheadHours) {
                        Text("12 hours").tag(12)
                        Text("24 hours").tag(24)
                        Text("48 hours").tag(48)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }
                
                Text("How far ahead to show meetings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 140)
                
                // Refresh Interval
                HStack {
                    Text("Refresh Interval:")
                        .frame(width: 140, alignment: .leading)
                    
                    Picker("", selection: $preferencesService.refreshIntervalSeconds) {
                        Text("30 seconds").tag(30)
                        Text("1 minute").tag(60)
                        Text("5 minutes").tag(300)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }
                
                Text("How often to check for meeting updates")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 140)
                
                // Alert Timing
                HStack {
                    Text("Alert Timing:")
                        .frame(width: 140, alignment: .leading)
                    
                    Picker("", selection: $preferencesService.alertMinutesBefore) {
                        Text("At start").tag(0)
                        Text("1 minute before").tag(1)
                        Text("5 minutes before").tag(5)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }
                
                Text("When to show full screen alerts")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 140)
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 400)
    }
}
