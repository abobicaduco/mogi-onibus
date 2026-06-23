# 🚌 Ônibus Mogi

App Android **não oficial** com os horários de ônibus de **Mogi das Cruzes (SP)**.
Funciona **offline**, é leve e os horários são atualizados pela internet sem
precisar reinstalar o app.

> Dados extraídos do portal da **Secretaria de Mobilidade e Trânsito** de Mogi das Cruzes:
> <https://mobilidadeservicos.mogidascruzes.sp.gov.br/site/transportes>

## ✨ Recursos

- **83 linhas** com horários de **Dia Útil**, **Sábado** e **Domingo/Feriado**, nos dois sentidos (Ida / Volta).
- **Busca** por número da linha, nome ou bairro.
- **Destaque do próximo ônibus** com base no horário atual e no dia da semana.
- **100% offline** depois da primeira abertura.
- **Atualização de horários pela internet**: quando os horários do repositório são mais recentes, o app mostra um popup perguntando se você quer atualizar.
- **Aviso de nova versão do app**: quando há um novo APK publicado nos *Releases* do GitHub, o app avisa ao abrir.

## 📥 Instalação

1. Vá em [**Releases**](../../releases/latest).
2. Baixe o arquivo `.apk`.
3. No Android, abra o arquivo e permita "instalar de fontes desconhecidas".

Compatível com **Android 5.0 (API 21) ou superior** — APK universal (todas as arquiteturas).

## 🔄 Como funciona a atualização

Existem **dois tipos** de atualização, independentes:

| O quê | Onde fica | Quando atualizar | Esforço |
|------|-----------|------------------|---------|
| **Horários** (`schedules.json`) | arquivo no repositório | semanalmente / quando a prefeitura mudar | só dar `commit` no JSON |
| **App** (`.apk`) | *Releases* do GitHub | só quando o código muda | publicar um novo release |

O app, ao abrir:

1. Mostra os horários do **cache local** (ou do JSON embarcado, na primeira vez).
2. Em segundo plano, compara `data_versao` do `schedules.json` no GitHub com a versão local. Se for **mais nova**, oferece o popup *"Novos horários disponíveis"*.
3. Consulta o último *release* via API do GitHub. Se a versão (`tag`) for **maior** que a instalada, oferece o popup *"Nova versão do app"* com link de download.

## 🗓️ Atualizando os horários (rotina semanal)

```bash
# 1. Re-raspar o site
python tools/scrape.py            # regenera app/assets/schedules.json

# 2. Commitar e enviar
git add app/assets/schedules.json
git commit -m "horarios: atualização semanal"
git push
```

Pronto — todos os usuários com o app instalado recebem o popup de atualização de
horários na próxima abertura. **Não precisa gerar novo APK.**

## 🛠️ Build do app (quando o código muda)

```bash
cd app
flutter pub get
flutter build apk --release      # gera build/app/outputs/flutter-apk/app-release.apk
```

A assinatura usa `app/android/key.properties` (não versionado). Veja
`app/android/key.properties.example`.

Para publicar:

```bash
# subir a versão em app/pubspec.yaml (ex.: 1.0.1+2), depois:
gh release create v1.0.1 build/app/outputs/flutter-apk/app-release.apk \
  --title "v1.0.1" --notes "Novidades..."
```

## 📂 Estrutura

```
mogi-onibus/
├── app/                    # projeto Flutter
│   ├── assets/schedules.json   # horários (fonte da verdade p/ o app)
│   └── lib/                    # código Dart
├── tools/scrape.py         # raspador do site da prefeitura
├── LICENSE                 # MIT
└── README.md
```

## ⚖️ Aviso

Projeto pessoal e **não oficial**. Os horários podem mudar a qualquer momento;
confira sempre a [fonte oficial](https://mobilidadeservicos.mogidascruzes.sp.gov.br/site/transportes).
Sem afiliação com a Prefeitura de Mogi das Cruzes ou com as empresas operadoras.

## 📄 Licença

[MIT](LICENSE) © 2026 Carlos Eduardo (@abobicaduco)
