import SwiftUI

// MARK: - Key Types
enum KeyType: String, CaseIterable {
    case selectKeyType = "Select Key Type"
    case boolean = "boolean"
    case integer = "integer"
    case integerFromList = "integer (from list)"
    case integerArray = "integer array"
    case string = "string"
    case stringFromList = "string (from list)"
    case stringArray = "string array"
    
    var isList: Bool {
        self == .stringFromList || self == .integerFromList
    }
    
    var isArray: Bool {
        self == .stringArray || self == .integerArray
    }
}

// MARK: - Keys View
struct KeysView: View {
    // MARK: - State
    @State private var selectedKeyType: KeyType = .selectKeyType
    @State private var isRequired = false
    @State private var keyName = ""
    @State private var friendlyName = ""
    @State private var keyDescription = ""
    @State private var defaultValue = ""
    @State private var infoText = ""
    @State private var moreInfoText = ""
    @State private var moreInfoUrl = ""
    @State private var headerOrPlaceholder = ""
    @State private var enumTitles = ""
    @State private var enumValues = ""
    
    // MARK: - Alerts
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showUrlAlert = false
    
    // MARK: - Dependencies
    let existingKey: TheKey?
    let keyIndex: Int
    let onSave: (TheKey) -> Void
    let onDismiss: () -> Void
    
    // MARK: - Initializer
    init(existingKey: TheKey? = nil,
         keyIndex: Int = 0,
         onSave: @escaping (TheKey) -> Void,
         onDismiss: @escaping () -> Void) {
        self.existingKey = existingKey
        self.keyIndex = keyIndex
        self.onSave = onSave
        self.onDismiss = onDismiss
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 0) {
                Text(existingKey != nil ? "Edit Key" : "Add New Key")
                    .font(.title2.bold())
                    .frame(maxWidth: 110, alignment: .leading)

                Spacer().frame(width: 4)
                
                Picker("", selection: $selectedKeyType) {
                    ForEach(KeyType.allCases, id: \.self) { keyType in
                        Text(keyType.rawValue).tag(keyType)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 200)
                
                Spacer()
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // General Section
                    section("General") {
                        
                        formRow("Required:") {
                            Toggle("", isOn: $isRequired)
                                .toggleStyle(.checkbox)
                            Spacer()
                        }
                        
                        formRow("Key Name:", field: $keyName)
                    }
                    
                    // Details Section
                    section("Details") {
                        formRow("Friendly Name:", field: $friendlyName)
                        editorRow("Description:", text: $keyDescription)
                        formRow("Default Value:", field: $defaultValue)
                    }
                    
                    // Info Section
                    section("Info") {
                        formRow("Info Text:", field: $infoText, placeholder: "tooltip to display for the key")
                        formRow("Link Text:", field: $moreInfoText, placeholder: "text to display for the link")
                        formRow("URL:", field: $moreInfoUrl, placeholder: "URL to view more info")
                    }
                    
                    // Extras Section
                        switch selectedKeyType {
                        case .string/*, .integer*/: // does not work for integers
                            section("Extras") {
                                formRow("Placeholder:", field: $headerOrPlaceholder, hint: "will be overridden by default value")
                            }
                        case .stringFromList, .integerFromList:
                            section("List (use comma or newline as separator):") {
                                editorRow("Titles:", text: $enumTitles)
                                editorRow("Values:", text: $enumValues)
                            }
                        default:
                            Text("")
                        }
                }
                .padding()
            }
            
            // Buttons
            HStack {
                Button("Cancel") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button(existingKey != nil ? "Update" : "Add") {
                    saveKey()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(keyName.isEmpty || selectedKeyType == .selectKeyType)
            }
        }
        .padding()
        .frame(width: 650, height: 700)
        .onAppear(perform: loadExistingKey)
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Invalid URL", isPresented: $showUrlAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Use Anyway") { performSave() }
        } message: {
            Text("The URL for More Info appears invalid")
        }
    }
    
    // MARK: - Section Wrapper
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            VStack(spacing: 10) {
                content()
            }
            Divider()
        }
    }
    
    // MARK: - Helpers for Rows
    private func formRow(_ label: String, field: Binding<String>, placeholder: String = "", hint: String = "") -> some View {
        formRow(label) {
            TextField("\(placeholder)", text: field)
                .textFieldStyle(.roundedBorder)
                .help(hint)
        }
    }
    
    private func formRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .frame(width: 140, alignment: .leading)
            content()
        }
    }
    
    private func editorRow(_ label: String, text: Binding<String>) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .frame(width: 140, alignment: .leading)
            TextEditor(text: text)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 100)
                .border(Color.secondary.opacity(0.3), width: 1)
        }
    }
    
    // MARK: - Data Handling
    private func loadExistingKey() {
        guard let existingKey = existingKey else { return }
        
        if existingKey.type == "array" {
            selectedKeyType = existingKey.listType == "integer" ? .integerArray : .stringArray
        } else {
            selectedKeyType = KeyType(rawValue: existingKey.type) ?? .selectKeyType
        }
        
        keyName = existingKey.name
        friendlyName = existingKey.friendlyName
        keyDescription = existingKey.desc
        defaultValue = existingKey.defaultValue
        infoText = existingKey.infoText
        moreInfoText = existingKey.moreInfoText
        moreInfoUrl = existingKey.moreInfoUrl
        isRequired = existingKey.required
        headerOrPlaceholder = existingKey.headerOrPlaceholder
        enumTitles = existingKey.listOfOptions
        enumValues = existingKey.listOfValues
    }
    
    private func saveKey() {
        guard !keyName.isEmpty else {
            return showError("A key must be provided")
        }
        guard selectedKeyType != .selectKeyType else {
            return showError("A key type must be selected")
        }
        if !moreInfoUrl.isEmpty && !isValidURL(moreInfoUrl) {
            showUrlAlert = true
            return
        }
        performSave()
    }
    
    private func performSave() {
        let finalFriendlyName = friendlyName.isEmpty ? keyName : friendlyName
        let finalDescription = keyDescription.isEmpty ? keyName : keyDescription
        
        var finalDefaultValue = defaultValue
        var finalKeyType = selectedKeyType.rawValue
        var listType = ""
        
        switch selectedKeyType {
        case .integer:
            if !defaultValue.isEmpty, Int(defaultValue) == nil {
                return showError("Default value must be a valid integer.")
            }
        case .boolean:
            if !defaultValue.isEmpty, !["true", "false"].contains(defaultValue.lowercased()) {
                return showError("Default value must be either true, false, or blank.")
            }
        case .string:
            break
        case .stringFromList, .integerFromList:
//            finalDefaultValue = "\"\(defaultValue)\""
            
            let titleCount = enumTitles.split(separator: "\n").count
            let valueCount = enumValues.split(separator: "\n").count
            guard titleCount == valueCount else {
                return showError("Number of items in options (\(titleCount)) must equal values (\(valueCount)).")
            }
            
            if selectedKeyType == .integerFromList {
//                let values = enumValues.replacingOccurrences(of: "\"", with: "")
//                    .split(separator: "\n")
//                    .map { $0.trimmingCharacters(in: .whitespaces) }
                let values = enumValues.replacingOccurrences(of: "\"", with: "")
                    .replacingOccurrences(of: "\n", with: ",")
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                for value in values where Int(value) == nil {
                    return showError("Found '\(value)' – only integers are allowed.")
                }
            }
        case .stringArray, .integerArray:
            finalKeyType = "array"
            listType = selectedKeyType == .integerArray ? "integer" : "string"
        case .selectKeyType:
            return
        }
        
        let keyId = existingKey?.id ?? UUID().uuidString
        let newKey = TheKey(
            id: keyId,
            index: keyIndex,
            type: finalKeyType,
            name: keyName,
            required: isRequired,
            friendlyName: finalFriendlyName,
            desc: finalDescription,
            defaultValue: finalDefaultValue,
            infoText: infoText,
            moreInfoText: moreInfoText,
            moreInfoUrl: moreInfoUrl,
            listType: listType,
            listHeader: headerOrPlaceholder,
            listOfOptions: enumTitles,
            listOfValues: enumValues
        )
        
        onSave(newKey)
        onDismiss()
    }
    
    private func showError(_ message: String) {
        alertMessage = message
        showAlert = true
    }
    
    private func isValidURL(_ urlString: String) -> Bool {
        let regex = #"^(http|https)://([\w\.-]+)\.([a-z\.]{2,6})([/\w\.-]*)*/?$"#
        return NSPredicate(format: "SELF MATCHES[c] %@", regex)
            .evaluate(with: urlString)
    }
}

// MARK: - Preview
struct KeysView_Previews: PreviewProvider {
    static var previews: some View {
        KeysView(
            onSave: { key in print("Saved key: \(key.name)") },
            onDismiss: { }
        )
    }
}
