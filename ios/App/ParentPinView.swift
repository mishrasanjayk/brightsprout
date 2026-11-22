import SwiftUI

/// Asks for the parent PIN before Parent mode opens. The first time, the parent creates one.
struct ParentPinView: View {
    @ObservedObject var bridge: NativeBridge

    private enum Step { case enterCurrent, createNew, confirmNew }

    @State private var step: Step = .enterCurrent
    @State private var pin = ""
    @State private var firstPin = ""
    @State private var message = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("👪").font(.system(size: 64))
                Text(title).font(.title2.bold()).multilineTextAlignment(.center)
                Text(hint).foregroundStyle(.secondary).multilineTextAlignment(.center)

                SecureField("PIN", text: $pin)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .multilineTextAlignment(.center)
                    .font(.title.monospacedDigit())
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
                    .frame(maxWidth: 220)
                    .focused($focused)
                    .onChange(of: pin) { value in
                        let digits = String(value.filter(\.isNumber).prefix(4))
                        if digits != value { pin = digits }
                        if digits.count == 4 { submit() }
                    }

                if !message.isEmpty {
                    Text(message).foregroundStyle(.red).font(.callout)
                }
                Spacer()
            }
            .padding(24)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { bridge.pinFinished(ok: false) }
                }
            }
            .onAppear {
                step = (ParentPin.isSet ? .enterCurrent : .createNew)
                focused = true
            }
        }
    }

    private var title: String {
        switch step {
        case .enterCurrent: return bridge.pinIsChange ? "Enter your current parent PIN" : "Parents only"
        case .createNew: return "Create a parent PIN"
        case .confirmNew: return "Type the PIN again"
        }
    }

    private var hint: String {
        switch step {
        case .enterCurrent: return "Enter your 4-digit PIN to open Parent mode."
        case .createNew: return "Pick 4 digits your kids don't know. You'll need it to open Parent mode and give more screen time."
        case .confirmNew: return "Just to be sure."
        }
    }

    private func submit() {
        let entered = pin
        pin = ""
        message = ""
        switch step {
        case .enterCurrent:
            guard ParentPin.check(entered) else { message = "That PIN isn't right."; return }
            if bridge.pinIsChange { step = .createNew } else { bridge.pinFinished(ok: true) }
        case .createNew:
            firstPin = entered
            step = .confirmNew
        case .confirmNew:
            guard entered == firstPin else { message = "The PINs didn't match. Try again."; step = .createNew; return }
            ParentPin.save(entered)
            bridge.pinFinished(ok: true)
        }
    }
}
