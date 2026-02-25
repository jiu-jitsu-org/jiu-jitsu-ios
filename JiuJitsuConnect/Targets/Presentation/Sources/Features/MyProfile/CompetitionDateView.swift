import SwiftUI

struct CompetitionDateView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedYear = 2025
    @State private var selectedMonth = 1
    
    let years = Array(2020...2025)
    let months = Array(1...12)
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.blue)
                        .font(.system(size: 20))
                }
                
                Spacer()
                
                Text("대회 정보 추가")
                    .font(.system(size: 17, weight: .semibold))
                
                Spacer()
                
                // Invisible button for spacing
                Image(systemName: "chevron.left")
                    .font(.system(size: 20))
                    .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Spacer()
            
            // Main Content
            VStack(spacing: 40) {
                // Question
                Text("언제 출전했나요?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)
                
                // Date Picker
                HStack(spacing: 12) {
                    // Year Picker
                    Menu {
                        ForEach(years.reversed(), id: \.self) { year in
                            Button {
                                selectedYear = year
                            } label: {
                                Text("\(year)")
                            }
                        }
                    } label: {
                        HStack {
                            Text("\(selectedYear)")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text("년")
                                .font(.system(size: 20))
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Month Picker
                    Menu {
                        ForEach(months, id: \.self) { month in
                            Button {
                                selectedMonth = month
                            } label: {
                                Text("\(month)")
                            }
                        }
                    } label: {
                        HStack {
                            Text("\(selectedMonth)")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text("월")
                                .font(.system(size: 20))
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                
                // Previous years hint
                Text("2024")
                    .font(.system(size: 17))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Bottom Button
            Button {
                // Handle next action
            } label: {
                Text("다음")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    CompetitionDateView()
}
