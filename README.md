# iOS Reverse Lab

Aplicativo SwiftUI para inspecionar estaticamente arquivos IPA que você possui ou tem autorização para analisar.

## Recursos implementados
- Importação local de IPA no iPhone.
- Leitura do contêiner ZIP e contagem de entradas.
- Localização segura de `Payload/*.app/Info.plist`.
- Extração limitada e leitura de Bundle ID, nome do executável, versão, build e iOS mínimo.
- Leitura do cabeçalho Mach-O para identificar arquiteturas comuns (arm64, arm, x86_64 e x86).
- Testes básicos de arquivos inválidos e ZIP sem app.

A análise não executa o binário, não remove assinatura, DRM ou proteções e não garante que um IPA seja instalável.

## Requisitos
- Xcode 16+
- iOS 16+
- XcodeGen

## Build local
```sh
brew install xcodegen
xcodegen generate
xcodebuild -project iOSReverseLab.xcodeproj -scheme iOSReverseLab \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

O GitHub Actions gera o projeto, compila e executa testes. O pacote sem assinatura do CI não instala diretamente no iPhone; distribuição requer assinatura e provisioning profile válidos.
