import SwiftUI
import PhotosUI

enum CreatePostStep: Int, CaseIterable {
    case photos = 0
    case subject = 1
    case date = 2
    case review = 3

    var title: String {
        switch self {
        case .photos: return "Select Photos"
        case .subject: return "Which Subject?"
        case .date: return "Which Date?"
        case .review: return "Review & Share"
        }
    }
}

struct CreatePostView: View {
    let group: ClassGroup
    @ObservedObject var postService: PostService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep: CreatePostStep = .photos
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var loadedImages: [UIImage] = []
    @State private var selectedSubject: Subject?
    @State private var selectedDate = Date()
    @State private var description = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress dots
                progressIndicator
                    .padding(.top, 12)

                // Step content
                Group {
                    switch currentStep {
                    case .photos:
                        photosStep
                    case .subject:
                        subjectStep
                    case .date:
                        dateStep
                    case .review:
                        reviewStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Navigation buttons
                bottomButtons
            }
            .navigationTitle(currentStep.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Upload Failed", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("Try Again") { shareNotes() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Something went wrong. Please try again.")
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(CreatePostStep.allCases, id: \.rawValue) { step in
                Circle()
                    .fill(step.rawValue <= currentStep.rawValue ? Color.teal : Color(.systemGray4))
                    .frame(width: 10, height: 10)
            }
        }
    }

    // MARK: - Step 1: Photos

    private var photosStep: some View {
        VStack(spacing: 20) {
            if loadedImages.isEmpty {
                VStack(spacing: 16) {
                    Spacer()

                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 56))
                        .foregroundStyle(.teal.opacity(0.5))

                    Text("Add photos of class notes")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Button {
                        showCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 32)

                    PhotosPicker(selection: $selectedPhotos,
                                 maxSelectionCount: 10,
                                 matching: .images) {
                        Label("Choose from Gallery", systemImage: "photo.stack")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.bordered)
                    .tint(.teal)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 32)

                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        // Photo grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 8) {
                            ForEach(Array(loadedImages.enumerated()), id: \.offset) { index, image in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 130)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))

                                    Button {
                                        loadedImages.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.white)
                                            .shadow(radius: 2)
                                    }
                                    .padding(4)
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Add more photos
                        HStack(spacing: 16) {
                            Button {
                                showCamera = true
                            } label: {
                                Label("Camera", systemImage: "camera")
                                    .font(.subheadline)
                            }
                            .tint(.teal)

                            PhotosPicker(selection: $selectedPhotos,
                                         maxSelectionCount: 10,
                                         matching: .images) {
                                Label("Gallery", systemImage: "photo.stack")
                                    .font(.subheadline)
                            }
                            .tint(.teal)
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                if let image {
                    loadedImages.append(image)
                }
            }
        }
        .onChange(of: selectedPhotos) { items in
            loadImages(from: items)
        }
    }

    // MARK: - Step 2: Subject

    private var subjectStep: some View {
        VStack(spacing: 24) {
            Spacer()

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(Subject.allCases) { subject in
                    Button {
                        selectedSubject = subject
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: subject.icon)
                                .font(.title2)
                            Text(subject.rawValue)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(selectedSubject == subject
                                    ? subject.color.opacity(0.15)
                                    : Color(.systemGray6))
                        .foregroundStyle(selectedSubject == subject ? subject.color : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedSubject == subject ? subject.color : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Step 3: Date

    private var dateStep: some View {
        VStack(spacing: 24) {
            Spacer()

            // Quick select buttons
            HStack(spacing: 12) {
                quickDateButton("Today", date: Date())
                quickDateButton("Yesterday", date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
            }
            .padding(.horizontal, 24)

            DatePicker("Class date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(.teal)
                .padding(.horizontal, 16)

            Spacer()
        }
    }

    private func quickDateButton(_ label: String, date: Date) -> some View {
        Button {
            selectedDate = date
        } label: {
            Text(label)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Calendar.current.isDate(selectedDate, inSameDayAs: date)
                            ? Color.teal.opacity(0.15) : Color(.systemGray6))
                .foregroundStyle(Calendar.current.isDate(selectedDate, inSameDayAs: date)
                                 ? .teal : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Calendar.current.isDate(selectedDate, inSameDayAs: date)
                                ? Color.teal : Color.clear, lineWidth: 1.5)
                )
        }
    }

    // MARK: - Step 4: Review

    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Summary
                VStack(alignment: .leading, spacing: 12) {
                    if let subject = selectedSubject {
                        HStack(spacing: 8) {
                            Text(subject.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(subject.color.opacity(0.15))
                                .foregroundStyle(subject.color)
                                .clipShape(Capsule())

                            Text(selectedDate.displayString)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Photo preview
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(loadedImages.enumerated()), id: \.offset) { _, image in
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 130)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }

                    Text("\(loadedImages.count) photo\(loadedImages.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Optional description
                VStack(alignment: .leading, spacing: 6) {
                    Text("Add a note (optional)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("e.g. Chapters 5 & 6", text: $description)
                        .padding(14)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(24)
        }
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        HStack(spacing: 12) {
            if currentStep != .photos {
                Button {
                    withAnimation {
                        if let prev = CreatePostStep(rawValue: currentStep.rawValue - 1) {
                            currentStep = prev
                        }
                    }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.bordered)
                .tint(.teal)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            if currentStep == .review {
                Button {
                    shareNotes()
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        Label("Share", systemImage: "paperplane.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(isLoading)
            } else {
                Button {
                    withAnimation {
                        if let next = CreatePostStep(rawValue: currentStep.rawValue + 1) {
                            currentStep = next
                        }
                    }
                } label: {
                    Label("Next", systemImage: "chevron.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(!canProceed)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    private var canProceed: Bool {
        switch currentStep {
        case .photos: return !loadedImages.isEmpty
        case .subject: return selectedSubject != nil
        case .date: return true
        case .review: return true
        }
    }

    // MARK: - Actions

    private func loadImages(from items: [PhotosPickerItem]) {
        loadedImages = []
        for item in items {
            item.loadTransferable(type: Data.self) { result in
                if case .success(let data) = result, let data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        loadedImages.append(image)
                    }
                }
            }
        }
    }

    private func shareNotes() {
        guard let subject = selectedSubject else { return }
        isLoading = true

        postService.createPost(
            groupId: group.id,
            authorId: authService.currentUserId,
            authorName: authService.currentUserName,
            subject: subject,
            date: selectedDate,
            description: description,
            images: loadedImages
        ) { result in
            isLoading = false
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage?) -> Void

        init(onCapture: @escaping (UIImage?) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            onCapture(image)
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCapture(nil)
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    CreatePostView(
        group: ClassGroup(name: "Class 5B", school: "St. Mary's", createdBy: "1"),
        postService: PostService()
    )
    .environmentObject(AuthService())
}
