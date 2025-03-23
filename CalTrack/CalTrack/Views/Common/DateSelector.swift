//
//  DateSelector.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

struct DateSelector: View {
    @Binding var selectedDate: Date
    var dateRange: ClosedRange<Date>?
    var onDateChanged: ((Date) -> Void)?

    private var calendar = Calendar.current

    var body: some View {
        VStack {
            // Date picker with visual customization
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .accentColor(AppColors.primaryGreen)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .padding()

            // Quick date selection buttons
            quickDateButtons
        }
    }

    private var quickDateButtons: some View {
        HStack(spacing: 15) {
            quickDateButton(title: "Today", date: Date())
            quickDateButton(title: "Yesterday", date: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date())
            quickDateButton(title: "Last Week", date: calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date())
        }
        .padding(.horizontal)
    }

    private func quickDateButton(title: String, date: Date) -> some View {
        Button(action: {
            withAnimation {
                selectedDate = date
                onDateChanged?(date)
            }
        }) {
            Text(title)
                .font(.caption)
                .foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate) ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(calendar.isDate(date, inSameDayAs: selectedDate) ? AppColors.primaryGreen : Color(.systemGray6))
                )
        }
    }
}

#Preview {
    struct PreviewProvider: PreviewProvider {
        static var previews: some View {
            DateSelector(selectedDate: .constant(Date()))
                .previewLayout(.sizeThatFits)
                .padding()
        }
    }
}
