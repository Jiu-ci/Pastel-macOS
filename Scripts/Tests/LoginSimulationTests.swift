import Foundation

@main
struct LoginSimulationTests {
    @MainActor
    static func main() async throws {
        precondition(StoreOperationPhase.latest(in: "@@IPA:phase=preparing\n@@IPA:phase=authenticating\n") == .authenticating)

        let verification = AccountStore()
        verification.loginSimulation = .verification
        verification.beginLoginSimulationIfNeeded()
        try await Task.sleep(for: .milliseconds(900))
        precondition(verification.needsCode && !verification.isValidating)
        verification.submitCode("12345")
        precondition(!verification.isValidating)
        verification.submitCode("000000")
        try await Task.sleep(for: .milliseconds(900))
        precondition(verification.needsCode && !verification.validationMessage.isEmpty)
        verification.submitCode("123456")
        try await Task.sleep(for: .milliseconds(900))
        precondition(verification.saveTick == 1 && !verification.needsCode)
        precondition(verification.accounts.isEmpty)

        let ambiguous = AccountStore()
        ambiguous.loginSimulation = .ambiguous
        ambiguous.beginLoginSimulationIfNeeded()
        try await Task.sleep(for: .milliseconds(900))
        precondition(ambiguous.canEnterVerificationCode && !ambiguous.needsCode)
        ambiguous.enterVerificationCode()
        precondition(ambiguous.needsCode)
        ambiguous.cancelValidation()
        precondition(!ambiguous.needsCode && !ambiguous.canEnterVerificationCode)

        let cancellation = AccountStore()
        cancellation.loginSimulation = .slow
        cancellation.beginLoginSimulationIfNeeded()
        try await Task.sleep(for: .milliseconds(900))
        cancellation.submitCode("123456")
        precondition(cancellation.isValidating)
        cancellation.cancelValidation()
        cancellation.loginSimulation = .verification
        cancellation.beginLoginSimulationIfNeeded()
        try await Task.sleep(for: .milliseconds(900))
        precondition(cancellation.needsCode && cancellation.saveTick == 0)
        try await Task.sleep(for: .seconds(10))
        precondition(cancellation.needsCode && !cancellation.isValidating && cancellation.saveTick == 0)
        precondition(cancellation.accounts.isEmpty)
        cancellation.cancelValidation()
        print("Login simulation passed: challenge, invalid code, success, ambiguous response, cancellation and stale callback.")
    }
}
