import SwiftUI

struct CategoryListView: View {
    @Binding var selectedCategories: Set<HealthDataCategory>

    private var allSelected: Bool {
        selectedCategories.count == HealthDataCategory.allCases.count
    }

    var body: some View {
        List {
            ForEach(HealthDataCategory.groupedCategories, id: \.group) { group, categories in
                Section {
                    ForEach(categories) { category in
                        categoryRow(category)
                    }
                } header: {
                    Label(group.displayName, systemImage: group.iconName)
                        .textCase(nil)
                }
            }
        }
        .navigationTitle("categories_title" as LocalizedStringKey)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    toggleAll()
                } label: {
                    Text(allSelected
                         ? "categories_deselect_all" as LocalizedStringKey
                         : "categories_select_all" as LocalizedStringKey)
                }
            }
        }
    }

    // MARK: - Row

    private func categoryRow(_ category: HealthDataCategory) -> some View {
        let isOn = Binding<Bool>(
            get: { selectedCategories.contains(category) },
            set: { newValue in
                if newValue {
                    selectedCategories.insert(category)
                } else {
                    selectedCategories.remove(category)
                }
            }
        )

        return Toggle(isOn: isOn) {
            Label(category.displayName, systemImage: category.iconName)
        }
    }

    // MARK: - Actions

    private func toggleAll() {
        if allSelected {
            selectedCategories.removeAll()
        } else {
            selectedCategories = Set(HealthDataCategory.allCases)
        }
    }
}

#Preview {
    NavigationStack {
        CategoryListView(selectedCategories: .constant(Set([.steps, .heartRate])))
    }
}
