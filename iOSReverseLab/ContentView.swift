import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var showingImporter = false
    @State private var report: IPAReport?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    Button {
                        showingImporter = true
                    } label: {
                        Label("Importar arquivo IPA", systemImage: "square.and.arrow.down")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.cyan, in: RoundedRectangle(cornerRadius: 16))
                            .foregroundStyle(.black)
                    }
                    .accessibilityHint("Seleciona um arquivo IPA para inspeção local")

                    if let report {
                        reportCard(report)
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "shippingbox")
                                .font(.system(size: 36))
                                .foregroundStyle(.secondary)
                            Text("Nenhum IPA importado").font(.headline)
                            Text("Escolha um IPA que você tenha autorização para analisar.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 36)
                    }
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("Reverse Lab")
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [UTType(filenameExtension: "ipa") ?? .zip],
                allowsMultipleSelection: false,
                onCompletion: handleImport
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("iOS REVERSE LAB")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(.cyan)
            Text("Inspeção estática, direto no iPhone.")
                .font(.largeTitle.bold())
            Text("Metadados e estrutura do pacote, sem executar o binário.")
                .foregroundStyle(.secondary)
        }
    }

    private func reportCard(_ report: IPAReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RELATÓRIO").font(.caption.bold()).foregroundStyle(.cyan)
            row("Arquivo", report.fileName)
            row("Tamanho", ByteCountFormatter.string(fromByteCount: report.fileSize, countStyle: .file))
            row("Formato", report.isZip ? "ZIP / IPA reconhecido" : "Formato não reconhecido")
            row("Entradas", "\(report.entryCount)")
            row("Executável principal", report.executableName ?? "Não identificado")
            row("Bundle ID", report.bundleIdentifier ?? "Não encontrado")
            row("Versão", report.version ?? "Não encontrada")
            row("Resultado", "Validação preliminar concluída")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title).foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value).multilineTextAlignment(.trailing).textSelection(.enabled)
        }
        .font(.subheadline)
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            report = try IPAInspector.inspect(url: url)
            errorMessage = nil
        } catch {
            report = nil
            errorMessage = error.localizedDescription
        }
    }
}