# Go Cloud Frontend

Un'applicazione Flutter moderna e responsive per la gestione di autenticazione e utenti, completamente compatibile con web, mobile e desktop.

## 📱 Panoramica dell'App

Questa applicazione Flutter offre un'interfaccia utente completa per l'autenticazione e la gestione degli utenti, con supporto multipiattaforma e design responsivo.

### 🚀 Caratteristiche Principali

- **🔐 Autenticazione Completa**: Login/Register con JWT tokens
- **📱 Design Responsivo**: Layout ottimizzati per mobile, tablet e desktop  
- **🌐 Compatibilità Web**: Completamente funzionante su browser web
- **🔄 Auto-Refresh Token**: Gestione automatica del rinnovo dei token scaduti
- **💾 Storage Sicuro**: Utilizzo di Flutter Secure Storage per i token
- **🎨 UI Moderna**: Design elegante con gradient, card e animazioni

## 🏗️ Architettura

### 📁 Struttura del Progetto

```
lib/
├── main.dart                    # Entry point dell'applicazione
├── models/                      # Modelli dati con JSON serialization
│   ├── auth_response.dart       # Modello per risposta autenticazione
│   ├── auth_response.g.dart     # Codice generato automaticamente
│   ├── user.dart               # Modello utente
│   └── user.g.dart             # Codice generato automaticamente
├── screens/                     # Schermate UI
│   ├── home_screen.dart        # Dashboard principale (responsive)
│   ├── login_screen.dart       # Schermata di login (con nuvola)
│   ├── register_screen.dart    # Schermata registrazione
│   └── user_detail_screen.dart # Dettagli utente
├── services/                    # Logica di business
│   ├── auth_service.dart       # Gestione autenticazione e token
│   └── user_service.dart       # Operazioni CRUD utenti
├── utils/                       # Utilità e configurazioni
│   ├── constants.dart          # Costanti dell'app
│   └── token_manager.dart      # Gestione legacy token
└── widgets/                     # Widget riutilizzabili
    ├── custom_text_field.dart  # Campo di input personalizzato
    └── responsive_layout.dart  # Layout responsive system
```

## 🔧 Configurazione Backend

### 🌍 Endpoint API

- **Base URL**: `https://34.140.122.146`
- **Login**: `POST /auth/login`
- **Registrazione**: `POST /auth/register` 
- **Refresh Token**: `POST /auth/refresh`
- **Operazioni Utenti**: Vari endpoint con autorizzazione Bearer

### 🔐 Sistema di Autenticazione

#### Token Management
- **Access Token**: JWT per autorizzazione API (breve durata)
- **Refresh Token**: Per rinnovare access token (lunga durata)
- **Auto-Refresh**: Rinnovo automatico su 401 Unauthorized
- **Secure Storage**: Tutti i token salvati in modo sicuro

#### Flusso di Autenticazione
1. **Login**: Utente inserisce email/password
2. **JWT Decode**: Estrazione user_id e claim dal token
3. **Storage**: Salvataggio sicuro di access_token, refresh_token, user_id
4. **Navigation**: Reindirizzamento automatico alla home con user_id
5. **Auto-Refresh**: Gestione trasparente del rinnovo token

## 🎨 Design Responsivo

### 📱 Layout Mobile
- **ListView**: Elenchi verticali ottimizzati per touch
- **AppBar**: Navigazione standard mobile
- **Card Layout**: Design pulito e moderno

### 🖥️ Layout Desktop  
- **GridView**: Layout a griglia per schermi grandi
- **Centered Cards**: Card centrate con max-width
- **Gradient Backgrounds**: Sfondi eleganti con gradienti

### 🔄 Breakpoint System
- **Mobile**: < 600px larghezza
- **Desktop**: ≥ 600px larghezza
- **Auto-Switch**: Cambio automatico layout in base alle dimensioni

## 🚀 Setup e Installazione

### ✅ Prerequisiti
- Flutter SDK ≥ 3.0.0
- Dart ≥ 3.0.0
- Git (per dependency management)

### 📦 Installazione Dipendenze

```powershell
# Naviga nella directory del progetto
cd "go-cloud-front-end"

# Installa le dipendenze
dart pub get

# Genera i file di serializzazione JSON
dart run build_runner build

# Genera i mock per i test  
dart run build_runner build --delete-conflicting-outputs
```

### 🔧 Dipendenze Principali

```yaml
dependencies:
  flutter: sdk: flutter
  http: ^1.1.0                    # HTTP requests
  flutter_secure_storage: ^9.0.0  # Secure token storage  
  provider: ^6.1.0               # State management
  json_annotation: ^4.9.0        # JSON serialization
  jwt_decoder: ^2.0.1            # JWT token decoding

dev_dependencies:
  build_runner: ^2.4.0           # Code generation
  json_serializable: ^6.7.0      # JSON serialization  
  mockito: ^5.4.0               # Testing mocks
```

## 🌐 Build e Deploy

### 📱 Build Mobile
```powershell
# Android
flutter build apk --release

# iOS  
flutter build ios --release
```

### 🌐 Build Web
```powershell
# Build per produzione web
flutter build web --release

# Serve locale per test
flutter run -d chrome
```

### 🖥️ Build Desktop
```powershell
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux  
flutter build linux --release
```

## 🧪 Testing

### 🔬 Test Automatizzati
```powershell
# Esegui tutti i test
flutter test

# Test con coverage
flutter test --coverage

# Test specifici
flutter test test/auth_service_test.dart
```

### 📋 Test Coverage
- ✅ **AuthService**: Login, register, token refresh, storage
- ✅ **UserService**: CRUD operations con mock HTTP
- ✅ **Widget Tests**: Componenti UI principali

## 🔐 Sicurezza

### 🛡️ Best Practices Implementate
- **Secure Storage**: Token salvati con encryption
- **JWT Validation**: Verifica scadenza token automatica
- **Auto-Logout**: Logout automatico su errori persistenti
- **HTTPS Only**: Tutte le comunicazioni cifrate
- **Input Validation**: Validazione email e password

## 🎯 Funzionalità Chiave

### 🔑 Autenticazione
- [x] Login con email/password
- [x] Registrazione nuovi utenti  
- [x] Logout sicuro
- [x] Gestione sessioni persistenti
- [x] Auto-refresh token

### 👤 Gestione Utenti
- [x] Lista utenti (responsive)
- [x] Dettagli utente
- [x] Profilo utente corrente
- [x] Navigazione con user_id

### 🎨 User Experience
- [x] Design moderno con Material Design
- [x] Responsive layout mobile/desktop
- [x] Loading states e feedback visivo
- [x] Gestione errori user-friendly
- [x] Navigazione intuitiva

## 📚 Risorse Utili

### 🔗 Link di Riferimento
- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Web Support](https://docs.flutter.dev/platform-integration/web)
- [JWT.io](https://jwt.io/) - JWT Debugger
- [Material Design](https://material.io/design) - Design Guidelines

### 🆘 Troubleshooting
- **Git PATH Issues**: Usare `dart pub get` invece di `flutter pub get`
- **Build Errors**: Pulire cache con `flutter clean && flutter pub get`
- **Web Issues**: Verificare che `flutter config --enable-web` sia attivo
- **Token Issues**: Controllare formato JWT e claims nel debugger

## 👨‍💻 Sviluppo

### 🔄 Workflow di Sviluppo
1. **Feature Branch**: Crea branch per nuove funzionalità
2. **Code Generation**: Rigenera codice con `dart run build_runner build`
3. **Testing**: Esegui test prima del commit
4. **Build**: Verifica build per tutte le piattaforme target

### 📝 Convenzioni Codice
- **Naming**: camelCase per variabili, PascalCase per classi
- **Comments**: Documenta metodi pubblici
- **Error Handling**: Sempre gestire eccezioni HTTP
- **State Management**: Usa Provider per state globale

---

**🚀 App pronta per produzione con supporto completo web, mobile e desktop!**
