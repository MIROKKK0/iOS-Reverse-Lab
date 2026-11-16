# iOS Reverse Lab

Aplicativo SwiftUI para importar e fazer inspeção estática de arquivos IPA que você possui ou tem autorização para analisar.

## Estado atual

**MVP inicial em desenvolvimento.** Esta primeira versão implementa a interface nativa e validação preliminar do contêiner ZIP. A leitura completa do diretório ZIP, do `Info.plist` e dos metadados Mach-O ainda será adicionada.

O app não executa binários importados e não remove assinatura, DRM ou proteções do iOS.

## Requisitos

- Xcode 16+
- iOS 16+
- XcodeGen (para gerar o projeto Xcode a partir de `project.yml`)

## Gerar e compilar

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project iOSReverseLab.xcodeproj -scheme iOSReverseLab \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

## CI

O GitHub Actions gera o projeto com XcodeGen, compila para iOS e executa os testes no simulador. O artefato sem assinatura é apenas um pacote de teste; **não pode ser instalado diretamente** no iPhone. Para distribuir um IPA instalável é necessário assinar com certificado e provisioning profile válidos de uma conta Apple Developer.

## Próximas etapas

1. Parser ZIP com validação de limites e diretório central.
2. Leitura segura de `Payload/*.app/Info.plist`.
3. Identificação de arquitetura e metadados Mach-O sem executar o binário.
4. Relatório exportável e testes com arquivos de amostra não sensíveis.

