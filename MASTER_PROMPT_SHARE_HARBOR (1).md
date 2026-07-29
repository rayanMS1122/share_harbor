# Master-Prompt: `share_harbor`

## Rolle und Arbeitsweise

Du arbeitest als leitender Flutter-Plugin-Engineer, Swift-Engineer, Kotlin-Engineer, API-Designer, Security-Engineer, Test-Engineer, Release-Engineer und technischer Dokumentationsautor.

Deine Aufgabe ist nicht, lediglich einen Plan oder ein Demo-Plugin zu schreiben. Du sollst ein produktionsreifes, mobile-only Flutter-Plugin entwickeln, vollständig testen, dokumentieren, bereinigen und als releasefähiges Artefakt ausliefern.

Arbeite autonom, aber nicht blind:

- Untersuche zuerst den vorhandenen Workspace, `git status`, vorhandene Dateien, Toolchain und mögliche Nutzeränderungen.
- Bewahre fremde oder bereits vorhandene Änderungen.
- Verwende keine destruktiven Git-Befehle.
- Frage nur nach echten Produktentscheidungen, nicht nach gewöhnlichen technischen Details.
- Stelle keine Frage, deren Antwort du aus dem Workspace, offiziellen Dokumentationen oder sicheren Defaults ableiten kannst.
- Nach den notwendigen Antworten: implementiere. Beende deine Arbeit nicht nach Recherche, Architektur oder Planung.
- Berichte regelmäßig knapp über den Fortschritt.
- Erfinde keine Testergebnisse, Messwerte, Geräteprüfungen oder Build-Erfolge.
- Wenn ein benötigtes Werkzeug nicht verfügbar ist, dokumentiere exakt, was dadurch ungeprüft bleibt.
- Veröffentliche nichts auf pub.dev, erstelle kein öffentliches Repository und pushe keinen Code ohne ausdrückliche Freigabe. Ein Publish-Dry-Run ist dagegen Pflicht.

## Produktziel

Entwickle ein neues Flutter-Plugin für Android und iOS, das Text, URLs, HTML, Bilder, Videos und beliebige Dateien zuverlässig aus dem nativen Share Sheet anderer Apps empfängt.

Das Plugin ist keine weitere dünne Hülle um:

```dart
getInitialShare()
shareStream
reset()
```

Der wesentliche Produktvorteil ist eine dauerhafte, transaktionale Inbox mit kontrollierter Verarbeitung, Crash-Recovery, stabilen Delivery-IDs und expliziter Bestätigung.

Empfohlener Arbeitsname:

```text
share_harbor
```

Empfohlene Produktbeschreibung:

```text
A durable inbound share inbox for Flutter on Android and iOS.
```

Empfohlene Metapher:

> Geteilte Inhalte erreichen zuerst einen sicheren Hafen und werden erst gelöscht, nachdem die Flutter-App ihre Verarbeitung bestätigt hat.

## Phase 0: Stelle zuerst diese Fragen

Stelle zu Beginn genau einen kompakten Fragenblock mit höchstens fünf Fragen. Verwende klare Auswahlmöglichkeiten und nenne jeweils deinen empfohlenen Default.

1. **Name**
   - Empfohlen: `share_harbor`
   - Alternativen: `share_inbox`, `share_latch`
   - Frage, ob der Nutzer den empfohlenen Namen akzeptiert oder einen eigenen Namen möchte.
2. **Publisher und Repository**
   - Frage nach dem späteren pub.dev-Publisher beziehungsweise der Repository-Organisation.
   - Wenn noch unbekannt, verwende neutrale lokale Platzhalter und blockiere die Implementierung nicht.
3. **Lizenz**
   - Empfohlen: BSD-3-Clause.
   - Alternativ: MIT oder Apache-2.0.
4. **Kompatibilitätsziel**
   - Empfohlen für eine neue, moderne Version: aktuelle stabile Flutter-Version, Android `minSdk` 23 und iOS 13 oder neuer.
   - Falls breitere Flutter-Kompatibilität gewünscht ist, muss diese durch eine echte CI-Matrix bewiesen werden.
5. **Share-Erlebnis**
   - Empfohlen: Inhalt nativ und dauerhaft sichern, danach eine kleine Erfolgsansicht zeigen; das automatische Öffnen der Haupt-App nur als optionale Best-Effort-Funktion behandeln.
   - Frage, ob ein sofortiger Wechsel in die Haupt-App ausdrücklich gewünscht ist.

Wenn der Nutzer sagt „entscheide selbst“, verwende alle empfohlenen Defaults. Frage anschließend nicht erneut nach Architektur, Dateinamen, Klassenstruktur, Teststrategie oder normalen Implementierungsdetails.

## Namensprüfung

Bevor du den Package-Ordner, Imports und Native Module endgültig benennst:

1. Prüfe den Namen direkt über die aktuelle pub.dev-API:

   ```text
   https://pub.dev/api/packages/<package_name>
   ```

2. Suche exakt nach dem Namen auf:
   - pub.dev
   - GitHub
   - allgemeinen Suchmaschinen
   - bei offensichtlichen Konflikten zusätzlich nach Marken und gleichnamigen Entwicklerprodukten
3. Prüfe, ob der Name:
   - in `lowercase_with_underscores` geschrieben ist,
   - ein gültiger Dart-Identifier ist,
   - kurz und aussprechbar ist,
   - nicht mit einem bekannten Flutter-Package verwechselt wird,
   - nicht fälschlicherweise Versand statt Empfang suggeriert.
4. Präsentiere dem Nutzer den Verfügbarkeitsstand als Momentaufnahme. Behaupte niemals, ein Name sei weltweit oder dauerhaft garantiert frei.
5. Prüfe unmittelbar vor einem späteren Publish erneut.

Am 29. Juli 2026 lieferten die Namen `share_harbor`, `share_inbox`, `share_latch`, `sharbor` und `relay_inbox` auf der pub.dev-Package-API jeweils 404. Diese Information ist nur ein Ausgangspunkt und muss aktuell verifiziert werden.

Wenn `share_harbor` noch verfügbar ist und der Nutzer keinen anderen Namen auswählt, verwende:

```text
Package: share_harbor
Dart-Haupteinstieg: lib/share_harbor.dart
Primäre API-Klasse: ShareHarbor
iOS-Core-Modul: ShareHarborCore
iOS-Plugin-Modul: ShareHarborPlugin
Android-Namespace: dev.<publisher>.share_harbor
```

Verwende für den Android-Namespace niemals einen erfundenen finalen Publisher. Nutze bis zur Klärung einen klar dokumentierten Platzhalter.

## Ehrliche Zustellgarantie

Versprich keine unmögliche „100-%-Zustellung“ und kein „exactly once“.

Die verbindliche Garantie lautet:

> Sobald eine Delivery vollständig und atomar in den package-eigenen Speicher committed wurde, bleibt sie bis zu einem erfolgreichen expliziten `ack()` verfügbar.

Die Semantik ist:

```text
durable at-least-once delivery after commit
```

Konsequenzen:

- Vor dem Commit kann das Betriebssystem die iOS Extension oder den Android-Prozess beenden.
- Nach dem Commit darf ein Crash keinen stillen Verlust verursachen.
- Ein Crash nach fachlicher Verarbeitung, aber vor `ack()`, kann zu erneuter Zustellung führen.
- Nutzer des Plugins müssen anhand der stabilen `deliveryId` idempotent arbeiten können.
- Events dürfen verloren gehen; committed Deliveries nicht.
- Dokumentation, API und Tests müssen diese Grenze überall identisch erklären.

## Unterstützter Umfang

Pflicht:

- Android und iOS
- Mobile only
- Warm start
- Cold start
- App im Hintergrund
- App vollständig beendet
- Einzelne und mehrere Anhänge
- Text
- URL
- optionales HTML
- Bilder
- Videos
- beliebige Dateien, sofern von der Konfiguration zugelassen
- gemischte Deliveries
- stabile Delivery- und Item-IDs
- Claim/Lease-Verarbeitung
- ACK
- Release/Retry
- Recovery nach Prozessabbruch
- konfigurierbare Quoten
- typed errors
- Diagnosewerkzeug

Nicht Bestandteil von Version 1:

- Web
- Windows
- macOS
- Linux
- Versand von Inhalten
- Cloud-Synchronisation
- Netzwerk-Uploads
- automatische Dateikonvertierung
- Archiv-Entpackung
- Medienbearbeitung
- vollständige Flutter-UI innerhalb der iOS Share Extension

Deklariere ausschließlich Android und iOS als unterstützte Plattformen. Implementiere keine leeren Desktop-/Web-Stubs, nur um zusätzliche Pub-Punkte zu erhalten.

## Architekturentscheidungen

### 1. Zunächst ein monolithisches Plugin

Baue Version 1 als ein einziges Flutter-Plugin mit Android- und iOS-Code.

Erstelle noch kein federated Plugin-Monorepo. Pigeon-generierter Dart-, Swift- und Kotlin-Code muss aus derselben Pigeon-Version stammen. Das Aufteilen des generierten Codes über mehrere Packages kann zu Versionskonflikten und Abstürzen führen.

Die interne Architektur muss trotzdem sauber getrennt sein:

```text
share_harbor/
├── lib/
│   ├── share_harbor.dart
│   └── src/
│       ├── api/
│       ├── model/
│       ├── state/
│       ├── errors/
│       ├── storage_contract/
│       └── platform/generated/
├── pigeon/
│   └── share_harbor_api.dart
├── android/
│   └── src/
│       ├── main/kotlin/.../
│       ├── test/kotlin/.../
│       └── androidTest/kotlin/.../
├── ios/
│   └── share_harbor/
│       ├── Package.swift
│       └── Sources/
│           ├── ShareHarborCore/
│           └── ShareHarborPlugin/
├── ios_share_extension_template/
├── example/
├── test/
├── integration_test/
├── tool/
├── doc/
└── benchmark/
```

### 2. Native Aufnahme vor Flutter

Die Aufnahme darf nicht davon abhängen, dass:

- die Flutter Engine läuft,
- Dart initialisiert ist,
- ein Stream-Listener registriert ist,
- die Haupt-App bereits geöffnet wurde.

Android und iOS müssen die Daten nativ übernehmen und zuerst dauerhaft committen. Flutter liest sie später.

### 3. Pigeon nur intern

Verwende eine aktuell geprüfte, exakt gepinnte Pigeon-Version als `dev_dependency`.

- Generiere Dart, Kotlin und Swift aus einer gemeinsamen Definition.
- Checke generierte Dateien ein.
- CI muss die Generierung erneut ausführen und bei einem Diff fehlschlagen.
- Exportiere keine Pigeon-generierten Typen als öffentliche API.
- Schicke niemals große Binärdaten oder Base64 über Platform Channels.
- Platform Channels übertragen nur kleine Metadaten und Befehle.

### 4. Mehrere Flutter Engines

Gehe nicht davon aus, dass ein Plugin nur einmal registriert wird.

- Kein unkontrollierter globaler statischer Pluginzustand.
- Engine-spezifische Listener und Channel-Handler gehören zur jeweiligen Plugin-Instanz.
- Gemeinsamer Dateispeicher wird über echte Cross-Process-/Cross-Instance-Locks geschützt.
- Beim Detach alle Listener, Coroutines, Tasks und Channel-Handler sauber entfernen.

## Storage- und Commit-Protokoll

Verwende für Version 1 einen dateibasierten, append-orientierten Spool. Vermeide eine zentrale mutable Indexdatei als Single Point of Corruption.

Empfohlene Struktur:

```text
share_harbor/v1/
├── deliveries/
│   └── <delivery-id>/
│       ├── items/
│       │   ├── <item-id>.payload
│       │   └── ...
│       ├── manifest.json
│       ├── ready.marker
│       ├── claim.json
│       └── ack.marker
├── failed/
├── quarantine/
├── locks/
└── diagnostics/
```

### Schreibreihenfolge

1. Kryptografisch zufällige oder standardkonforme UUID/ULID für die Delivery erzeugen.
2. Delivery-Verzeichnis anlegen.
3. Jeden Anhang streamend in `<item-id>.partial` schreiben.
4. Während des Schreibens Quoten und Abbruch prüfen.
5. Daten flushen; wo sinnvoll und verfügbar, bis zum Dateisystem synchronisieren.
6. `.partial` atomar in `.payload` umbenennen.
7. Versioniertes Manifest zuerst als temporäre Datei schreiben.
8. Manifest atomar ersetzen.
9. `ready.marker` als letzten Commit-Schritt atomar erstellen.
10. Erst nach erfolgreichem Marker gilt die Delivery als sichtbar.
11. Erst danach native Erfolgs-UI, Event oder App-Weiterleitung auslösen.

Verlasse dich für die Korrektheit nicht ausschließlich auf das Verschieben eines kompletten Ordners. Der atomare Marker innerhalb desselben Containers definiert den Commit.

### Reader-Regeln

- Ohne gültigen `ready.marker` niemals ausliefern.
- Manifest vollständig validieren.
- Pfade ausschließlich aus internen Item-IDs konstruieren.
- Keine Pfade aus `originalName` übernehmen.
- Payload muss innerhalb des erwarteten Delivery-Verzeichnisses liegen.
- Symlinks ablehnen.
- Neuere unbekannte Schema-Versionen nicht löschen, sondern mit `schemaUnsupported` melden.
- Beschädigte Einträge nach `quarantine` verschieben und diagnostizierbar halten.

### Zustandsmaschine

```text
receiving -> ready -> claimed -> acknowledged -> cleaned
                ^        |
                |        v
                +---- released
```

Fehlerzustände:

```text
rejected
failed
quarantined
```

Regeln:

- `pending()` liefert nur `ready`.
- `claim()` ist atomar.
- Ein Claim enthält eine Lease mit Ablaufzeit.
- Nach Prozessabbruch wird ein abgelaufener Claim erneut `ready`.
- `ack()` ist idempotent.
- `release()` ist idempotent.
- Ein ACK wird zuerst dauerhaft gespeichert; die Payload-Bereinigung folgt danach.
- Ein Crash während der Bereinigung darf nicht zur erneuten fachlichen Zustellung eines bereits bestätigten Eintrags führen.
- Doppelte Events dürfen keine doppelten Claims erzeugen.

### Cross-Process-Synchronisation

Implementiere echte Sperren:

- iOS: POSIX Lock oder korrekt eingesetzter `NSFileCoordinator`.
- Android: `FileChannel.lock()` oder gleichwertige prozessübergreifende Sperre.
- `AtomicFile` darf für atomare Manifest-Schreibvorgänge verwendet werden, ersetzt aber keine Sperre.

Nicht zulässig:

- eine Boolean-Datei ohne Kernel-Lock,
- `File.exists()` als Synchronisationsmechanismus,
- nur ein Dart-`Mutex`,
- nur ein Kotlin-`synchronized`,
- nur eine Swift-Serial-Queue.

Diese Mechanismen reichen nicht über Prozessgrenzen.

## Manifest

Definiere und dokumentiere ein stabiles, versioniertes Schema:

```json
{
  "schemaVersion": 1,
  "deliveryId": "stable-id",
  "receivedAtUtc": "2026-07-29T12:00:00.000Z",
  "platform": "ios",
  "state": "ready",
  "attempt": 0,
  "items": [
    {
      "itemId": "stable-item-id",
      "kind": "image",
      "originalName": "photo.jpg",
      "internalName": "stable-item-id.payload",
      "declaredMimeType": "image/jpeg",
      "resolvedMimeType": "image/jpeg",
      "byteLength": 123456
    }
  ],
  "text": null,
  "subject": null,
  "source": null
}
```

Regeln:

- UTC-Zeit mit klarer ISO-8601-Darstellung.
- `source` ist optional und immer als untrusted/best effort dokumentiert.
- Originalname nur zur Anzeige.
- Keine temporären externen URIs speichern.
- Keine absoluten internen Pfade im Manifest.
- Keine sensiblen Inhalte in Diagnostics oder Logs.
- Prüfsummen nur optional und streamend; große Dateien nicht standardmäßig vollständig hashen, solange daraus kein bewiesener Nutzen entsteht.

## Build-Time- und Runtime-Konfiguration

Ein häufiger Architekturfehler ist eine Konfiguration, die nur aus Dart gesetzt wird. Das funktioniert nicht zuverlässig, wenn die App nie gestartet wurde oder beendet ist.

Teile die Konfiguration:

### Native Build-Time-Konfiguration

Muss für Extension/Receiver ohne Flutter verfügbar sein:

- App Group ID
- erlaubte Share-Kategorien
- maximale Item-Anzahl
- maximale Einzelgröße
- maximale Delivery-Größe
- maximale Inbox-Größe
- Extension-Titel und Texte
- Verhalten nach erfolgreichem Commit

Liefer eine eindeutige Template- oder Generatorlösung. Der Doctor muss prüfen, dass Android, iOS Extension und Dart-Dokumentation dieselben Werte erwarten.

### Runtime-Konfiguration

Darf Verhalten nur weiter einschränken oder die Verarbeitung steuern:

- Lease-Dauer
- Retention
- automatisches Cleanup
- Sortierung
- Diagnoselevel
- optionale MIME-Policies

Sichere native Defaults müssen auch vor dem ersten App-Start gelten.

## iOS-Implementierung

### Native Share Extension

Implementiere die Aufnahme in Swift.

Die Extension:

- startet standardmäßig keine Flutter Engine,
- verwendet keine Flutter-Plugins,
- importiert nur den app-extension-safe `ShareHarborCore`,
- greift über eine App Group auf den gemeinsamen Container zu,
- zeigt nur eine kleine native Progress-/Erfolg-/Fehleroberfläche,
- verarbeitet Anhänge speicherschonend und mit begrenzter Parallelität.

`ShareHarborCore` darf nicht von Flutter abhängen. `ShareHarborPlugin` darf Flutter anbinden und denselben Core verwenden.

### `NSItemProvider`

- Ermittle alle Attachments aus allen `NSExtensionItem`s.
- Definiere eine deterministische UTType-Priorität.
- Bevorzuge für Dateien eine File Representation.
- Kopiere die von `loadFileRepresentation` gelieferte temporäre Datei innerhalb des Completion Handlers in den App-Group-Container.
- Verwende `loadInPlaceFileRepresentation` nur, wenn seine Semantik korrekt behandelt wird; übernimm externe Dateien trotzdem dauerhaft in den eigenen Speicher.
- Verwende `loadDataRepresentation` nur für kleine passende Datentypen.
- Lade große Dateien niemals vollständig über `Data(contentsOf:)`.
- Unterstütze Provider, die falsche Endungen, unvollständige Metadaten oder verzögerte Antworten liefern.
- Begrenze Parallelität, um Extension-Speicher nicht zu überlasten.
- Reagiere korrekt auf Cancellation und Provider-Fehler.

### App Group und Dateizugriff

- Runner und Share Extension müssen exakt dieselbe App Group besitzen.
- Prüfe fehlende oder falsche Entitlements mit klaren Fehlern.
- Synchronisiere gemeinsamen Zugriff.
- Nutze nur app-extension-safe APIs.
- Setze `Require Only App-Extension-Safe API` korrekt.
- Dokumentiere Data-Protection-Verhalten und Verhalten bei gesperrtem Gerät.

### Extension Lifecycle

- Rufe `completeRequest` erst nach erfolgreichem Commit auf.
- Bei Abbruch oder Fehler keine Delivery fälschlich als erfolgreich markieren.
- Nach `completeRequest` keine kritische Arbeit mehr starten.
- Verlasse dich nicht darauf, dass die Extension danach weiterläuft.
- Keine privaten Responder-Chain-Hacks, um die Host-App zu öffnen.
- Host-App-Öffnung nur als klar dokumentierte Best-Effort-Funktion über erlaubte APIs.
- Die dauerhafte Inbox darf niemals von erfolgreichem Deep Linking abhängen.

### Aktivierungsregel

- Präzise `NSExtensionActivationRule`.
- Kein `TRUEPREDICATE` im Release.
- MaxCounts müssen zu den nativen Quoten passen.
- Unterstützte UTTypes und tatsächliche Verarbeitung müssen übereinstimmen.

### Distribution

- Unterstütze Swift Package Manager.
- Unterstütze bis auf Weiteres zusätzlich CocoaPods.
- Liefere ein korrektes `Package.swift`.
- Liefere ein korrektes Podspec.
- Falls Required-Reason-APIs verwendet werden, liefere ein in beiden Integrationswegen korrekt gebündeltes `PrivacyInfo.xcprivacy`.
- Erfinde keine Privacy-Manifest-Einträge. Trage nur tatsächlich verwendete APIs und Datennutzung ein.
- Halte Deployment Target von Runner und Extension konsistent.
- Prüfe Build-Phase-Reihenfolge.

## Android-Implementierung

### Eigene Receiver Activity

Verwende eine kleine native `ShareHarborReceiverActivity`, statt Share-Logik in die Nutzer-`MainActivity` zu pressen.

Vorteile:

- keine Konflikte mit bestehendem `launchMode`,
- keine Kollision mit Deep-Link-Plugins,
- Aufnahme funktioniert vor Flutter,
- klare Lifecycle- und Progress-Steuerung.

Die Activity:

- ist nur wegen der präzisen Share-Intent-Filter exportiert,
- validiert Action, Typ, URI und Extras,
- kopiert binäre Inhalte auf einem I/O-Dispatcher,
- zeigt bei längerer Arbeit Fortschritt und Abbruch,
- commitet vor dem Wechsel in die Haupt-App,
- beendet sich sauber,
- speichert keine Activity-Referenz in statischem Zustand.

### Intent-Verarbeitung

Unterstütze defensiv:

- `ACTION_SEND`
- `ACTION_SEND_MULTIPLE`
- `Intent.EXTRA_TEXT`
- `Intent.EXTRA_HTML_TEXT`
- `Intent.EXTRA_SUBJECT`
- `Intent.EXTRA_TITLE`
- `Intent.EXTRA_STREAM`
- `Intent.data`
- `ClipData`

Regeln:

- Dedupliziere dieselbe URI, falls Sender sie gleichzeitig in mehreren Feldern ablegt.
- Behandle MIME-Type, Dateiname, Größe und Source-App als untrusted.
- Nutze `ContentResolver.getType`.
- Frage `OpenableColumns.DISPLAY_NAME` und `SIZE` defensiv ab.
- Akzeptiere unbekannte Größe.
- Prüfe tatsächliche gelesene Bytes gegen Quoten.
- Verlasse dich nicht auf einen echten Dateisystempfad.
- Kopiere `content://` sofort in den eigenen Speicher.
- Speichere die externe URI nicht zur späteren Verarbeitung.
- Verwende `takePersistableUriPermission` nur, wenn Intent-Flags und Provider es tatsächlich erlauben; mache die Korrektheit niemals davon abhängig.
- Keine Binär-I/O auf dem UI-Thread.

### Berechtigungen

- Fordere nicht pauschal `READ_EXTERNAL_STORAGE`.
- Fordere nicht pauschal `MANAGE_EXTERNAL_STORAGE`.
- Verwende die temporäre URI-Leseberechtigung des Share-Intents.
- Verwende keine `file://`-URIs.
- Deklariere nur notwendige Manifest-Komponenten.
- Verwende `*/*` nur, wenn die Konfiguration tatsächlich beliebige Inhalte unterstützt. Dokumentiere, dass spezifische MIME-Filter vorzuziehen sind.

### Background Work

- Verschiebe die erste Datenkopie nicht in WorkManager.
- Temporäre URI-Rechte können vorher ablaufen.
- Cleanup bereits eigener Dateien darf später über geeignete Hintergrundmechanismen erfolgen.
- Für sehr große Inhalte müssen Grenzen, Fortschritt und ehrliche Fehlersemantik existieren.

### Toolchain

- Nutze das aktuelle Flutter-Plugin-Template als Ausgangspunkt.
- Verwende die moderne Flutter Android Plugin API.
- Berücksichtige die aktuelle AGP-/Built-in-Kotlin-Migration.
- Wenn ältere Flutter-Versionen unterstützt werden, beweise beide Gradle-Pfade in CI.
- Keine veraltete `io.flutter.app.FlutterApplication`-Konfiguration.

## Öffentliche Dart-API

Halte die API klein, typisiert und testbar.

Beispiel:

```dart
final harbor = await ShareHarbor.open(
  const ShareHarborConfig(
    leaseTimeout: Duration(minutes: 5),
    retention: Duration(days: 7),
  ),
);

final pending = await harbor.pending();
final claim = await harbor.claim(pending.first.id);

try {
  await importIntoApplication(claim.delivery);
  await harbor.ack(claim);
} catch (error) {
  await harbor.release(
    claim,
    reason: error.toString(),
  );
}
```

Mindestens:

```dart
abstract interface class ShareHarborApi {
  Future<List<ShareDelivery>> pending();
  Future<ShareClaim> claim(String deliveryId);
  Future<ShareClaim?> claimNext();
  Future<void> ack(ShareClaim claim);
  Future<void> release(ShareClaim claim, {String? reason});
  Future<void> retry(String deliveryId);
  Future<ShareHarborHealth> inspect();
  Future<ShareCleanupResult> cleanup();
  Stream<ShareHarborChange> get changes;
}
```

API-Regeln:

- `changes` ist nur ein Wake-up-Hinweis.
- Nach jedem Event erneut `pending()` lesen.
- Auch bei App-Resume `pending()` lesen.
- Keine automatische Löschung beim Lesen.
- Kein automatisches `reset()`.
- Keine ACK-Ausführung in einem pauschalen `finally`.
- Keine nackten Maps in der öffentlichen API.
- Keine nativen Typen, Pigeon-Typen oder externen URIs exportieren.
- Immutable Models.
- Value Equality.
- Vollständige `///`-Dokumentation aller öffentlichen APIs.
- Alle Exceptions als stabile Package-Fehlertypen abbilden.
- API-Typen mit passenden Dart-3-Class-Modifiern vor unkontrolliertem Implementieren/Subclassing schützen.
- Keine unnötige globale Singleton-API; Instanzen und Dependency Injection müssen in Tests möglich sein.

Erwäge:

```dart
Stream<List<int>> openRead(ShareItem item);
```

oder eine gleichwertige kontrollierte Lese-API, damit Nutzer nicht von internen Speicherpfaden abhängig werden. Wenn zusätzlich eine lokale URI exponiert wird, dokumentiere exakt, dass sie nach ACK/Cleanup ungültig werden kann.

## Fehler-Taxonomie

Definiere stabile Codes, mindestens:

```text
configurationInvalid
appGroupUnavailable
unsupportedType
unsupportedSchema
sourcePermissionDenied
sourceUnavailable
itemTooLarge
deliveryTooLarge
tooManyItems
inboxQuotaExceeded
cancelled
ioFailure
corruptManifest
unsafeMetadata
lockTimeout
deliveryNotFound
claimConflict
claimExpired
alreadyAcknowledged
platformFailure
```

Jeder Fehler braucht:

- stabilen maschinenlesbaren Code,
- Pipeline-Stage,
- sichere öffentliche Nachricht,
- optionale redigierte Diagnose,
- ursprüngliche native Ursache nur intern beziehungsweise im Debug-Modus.

Keine sensitiven Inhalte, vollständigen Dateipfade, geteilten Texte oder Original-URIs in Standardlogs.

## Sicherheit

Erstelle ein Threat Model.

Behandle alles vom Sender als feindlich oder fehlerhaft:

- manipulierte MIME-Types,
- leere Dateien,
- unbekannte Größen,
- extrem große Streams,
- Streams ohne Ende,
- doppelte URIs,
- doppelte Namen,
- Unicode-Sonderfälle,
- `../` und absolute Pfade,
- Null-Bytes und ungültige Zeichen,
- Symlinks,
- Provider-Abbruch,
- Provider, der weniger oder mehr Bytes liefert als angekündigt,
- beschädigte Manifestdateien,
- Replay desselben Intents.

Pflichtmaßnahmen:

- interne zufällige Dateinamen,
- kanonische Path-Containment-Prüfung,
- Quoten während des Streamings,
- bounded concurrency,
- Timeouts nur dort, wo sie keine gültigen langsamen Provider willkürlich zerstören,
- keine Archivextraktion,
- kein Netzwerk,
- kein dynamisches Ausführen oder Öffnen empfangener Inhalte,
- minimale Berechtigungen,
- Redaction in Logs,
- sichere Cleanup-Regeln.

Dokumentiere klar, dass App-Sandbox/App-Group-Schutz keine Ende-zu-Ende-Verschlüsselung ist. Implementiere keine halb fertige eigene Kryptografie.

## Performance

Performance bedeutet hier:

- kein Flutter-Engine-Start in der iOS Extension,
- keine Base64-Konvertierung,
- keine kompletten Großdateien im RAM,
- streamende Kopie,
- begrenzte Parallelität,
- keine Binärdaten über Platform Channels,
- keine wiederholten vollständigen Verzeichnisscans auf dem UI-Thread,
- inkrementelles und recoverbares Cleanup.

Zentrale Buffergrößen und Limits müssen benannt, dokumentiert und benchmarkbar sein. Keine verstreuten Magic Numbers.

Erstelle echte Benchmarks für:

- kleine Text-Delivery,
- einzelne kleine Datei,
- mehrere gemischte Dateien,
- große Datei innerhalb des konfigurierten Limits,
- Inbox mit vielen committed Deliveries,
- Startup-Recovery mit unvollständigen Einträgen.

Berichte:

- gemessene Dauer,
- Dateigröße,
- Gerät/Simulator,
- OS-Version,
- Build-Modus,
- Peak-Memory, sofern wirklich gemessen,
- Einschränkungen der Messung.

Keine erfundenen Zielwerte oder Ergebnisse.

## Tests

### Dart Unit Tests

Teste:

- Models und Serialisierung,
- Schema-Versionierung,
- Zustandsmaschine,
- Claim/Lease,
- idempotentes ACK und Release,
- Sortierung,
- Fehler-Mapping,
- Recovery-Entscheidungen,
- Konfiguration,
- Fake Platform Adapter,
- mehrere Plugin-Instanzen.

### Property- und Fuzz-Tests

Generiere:

- zufällige Manifestvarianten,
- ungültige JSON-Strukturen,
- extrem lange Namen,
- Unicode-Namen,
- Zeit- und Lease-Grenzfälle,
- zufällige Operationsfolgen.

Invariant:

```text
Eine committed und nicht bestätigte Delivery bleibt auffindbar.
Eine nicht committed Delivery wird niemals als pending ausgeliefert.
Eine bestätigte Delivery wird niemals erneut fachlich ausgeliefert.
```

### Native Unit Tests

Android:

- Intent-Decoder,
- ClipData/EXTRA_STREAM-Deduplizierung,
- ContentResolver-Fehler,
- unbekannte Größe,
- Quoten,
- AtomicFile und Locks,
- Recovery.

iOS:

- NSItemProvider-Repräsentationen über Test-Doubles,
- temporäre Dateien,
- App-Group-Fehler,
- UTType-Priorität,
- Cancellation,
- Quoten,
- Locks und Recovery.

### Integration Tests

Erstelle kontrollierte Sender-Fixtures, die absichtlich folgende Fälle senden:

- Text
- URL
- Text plus URL
- Bild
- Video
- PDF
- mehrere Bilder
- mehrere gemischte Dateien
- doppelte URI
- falscher MIME-Type
- unbekannte Größe
- Provider-Fehler

Teste:

- App warm,
- App im Hintergrund,
- App beendet,
- erster App-Start,
- zweiter Share während Verarbeitung,
- App-Restart nach Commit,
- App-Restart nach Claim.

Flutter-`integration_test` allein reicht für native System-UI nicht. Verwende zusätzlich:

- AndroidX Test/Espresso beziehungsweise UI Automator,
- XCTest/XCUITest,
- reale native Sender-Fixtures.

Patrol kann optional verwendet werden, darf aber keine nativen Unit- und Plattformtests ersetzen.

### Fault Injection

Baue ausschließlich für Test/Debug kontrollierte Crash-Punkte ein:

1. nach Delivery-Verzeichnis,
2. mitten im Item-Stream,
3. nach Payload-Flush,
4. nach Payload-Rename,
5. nach Manifest-Schreiben,
6. nach Ready-Marker,
7. nach Event, aber vor UI-Ende,
8. nach Claim,
9. nach ACK-Marker,
10. mitten im Cleanup.

Nach jedem simulierten Prozessabbruch Recovery starten und Invarianten prüfen.

Fault-Injection-Schalter dürfen nicht versehentlich in der Release-API oder Release-Konfiguration aktiv bleiben.

### Reale Geräte

Teste mindestens:

- jeweils die minimale unterstützte OS-Version,
- eine mittlere verbreitete Version,
- die aktuellste stabile Version,
- mindestens ein physisches Android-Gerät,
- mindestens ein physisches iPhone in Release-Konfiguration.

Teste zusätzlich mit verbreiteten Senderklassen:

- Browser,
- Foto-App,
- Datei-App,
- Mail-App,
- Messenger oder kontrollierte Fixture-App.

Dokumentiere Abweichungen einzelner Sender. Behaupte keine vollständige Kompatibilität mit Apps, die nicht tatsächlich geprüft wurden.

## Compile- und Analyzer-Fallen

Vermeide insbesondere:

- nicht konstante Getter oder Methoden in `const`-Constructor-Assertions,
- unzulässige Ausdrücke wie `value.isFinite` in einem Const-Kontext,
- unvollständige `switch`-Ausdrücke,
- Nullability-Casts ohne Validierung,
- unbeantwortete Pigeon-Callbacks,
- mehrfach beantwortete native Callbacks,
- Swift Continuations, die nicht exakt einmal resumed werden,
- Coroutines, die nach Activity-/Plugin-Detach weiterlaufen,
- unawaited kritische Schreiboperationen,
- Exceptions, die still geschluckt werden.

Bei einem Bereich `0 <= value <= 1` muss eine const-kompatible Assertion verwendet werden. Die Bereichsvergleiche müssen zugleich `NaN` und Infinity zuverlässig abweisen. Prüfe dies mit echten Const-Instanzen im Test.

Führe Analyzer und Compiler früh aus, nicht erst nach Fertigstellung.

## Fehler, die ausdrücklich verboten sind

Implementiere keinen der folgenden schlechten Ansätze:

1. Event-Stream als einzige Datenquelle.
2. `getInitial...()` plus `reset()` ohne dauerhafte Delivery.
3. Löschen beim Lesen.
4. Löschen vor ACK.
5. ACK trotz fehlgeschlagener Fachverarbeitung.
6. Flutter Engine als Voraussetzung für iOS Share.
7. Flutter Engine standardmäßig in der iOS Share Extension.
8. Payload in `UserDefaults` oder SharedPreferences.
9. große JSON-/Base64-Payloads über Method Channels.
10. komplette Dateien mit `readAsBytes`, `Data(contentsOf:)` oder gleichwertig in den RAM laden.
11. temporäre `NSItemProvider`-Datei nach Ende des Callbacks weiterverwenden.
12. externe Android-URI zur späteren Verarbeitung speichern.
13. erste Android-Kopie in WorkManager verschieben.
14. breite Storage Permissions anfordern.
15. blind `*/*` registrieren.
16. MIME-Type oder Originaldateiname vertrauen.
17. Originaldateiname als internen Pfad verwenden.
18. private iOS-Responder-Hacks zum automatischen Öffnen der App.
19. stilles Überschreiben bestehender Xcode-/Manifest-Konfiguration.
20. nicht idempotente Setup-Skripte.
21. statische Activity- oder ViewController-Referenzen.
22. nur In-Process-Locks für gemeinsamen Speicher.
23. nur Simulator-Tests.
24. nur Happy-Path-Tests.
25. erfundene Coverage-, Performance- oder Kompatibilitätswerte.
26. Pigeon-Typen in der öffentlichen API.
27. Pigeon-generierten Dart- und Native-Code auf getrennte Packages verteilen.
28. frühzeitige Plugin-Federation ohne echten Bedarf.
29. leere Web-/Desktop-Implementierungen.
30. unnötige Abhängigkeiten und Codegeneratoren.
31. `latest` als Dependency-Version.
32. unkommentierte Magic Numbers.
33. hart codierte App Group, Bundle ID oder Publisher-ID.
34. automatische Veröffentlichung ohne Zustimmung.
35. Stable-Release, bevor reale Cold-Start- und Process-Kill-Tests bestanden sind.

## Setup und Doctor

Liefere:

```bash
dart run share_harbor:doctor
```

Der Doctor ist standardmäßig read-only und prüft:

- Flutter- und Dart-Version,
- Android Gradle/AGP/Kotlin-Kompatibilität,
- Android Receiver vorhanden,
- `android:exported` korrekt,
- Intent-Filter und MIME-Typen,
- keine unnötigen Storage Permissions,
- iOS Share Extension vorhanden,
- Runner und Extension verwenden dieselbe App Group,
- Entitlements,
- Activation Rule,
- Deployment Targets,
- Build-Phase-Reihenfolge,
- SwiftPM-Verknüpfung,
- CocoaPods-Fallback,
- Privacy Manifest, falls erforderlich,
- Extension-safe Build Settings,
- Schema-/Config-Versionen,
- erwartete Verzeichnisse und Rechte.

Ausgabe:

- `PASS`
- `WARN`
- `FAIL`
- konkrete Datei,
- konkrete Ursache,
- konkrete Reparaturanweisung.

Keine vagen Meldungen wie „iOS setup is invalid“.

Wenn du ein `setup --apply` implementierst:

- zuerst `--dry-run`,
- Änderungen als Diff zeigen,
- Backups,
- idempotent,
- keine unbekannten Nutzeränderungen überschreiben,
- automatisierte Fixture-Tests für Xcode- und Android-Projektvarianten.

Wenn zuverlässige Xcode-Projektmutation nicht bewiesen werden kann, liefere stattdessen hochwertige Templates und den Doctor. Eine halb zuverlässige Automatisierung ist schlechter als klare, geprüfte Schritte.

## Example-App

Die Example-App muss ein reales Integrationsprojekt sein, keine Counter-Demo.

Sie zeigt:

- Setup-Status,
- pending Deliveries,
- Delivery-Details,
- Items und sichere Metadaten,
- Claim,
- simulierten Import,
- ACK,
- Release,
- Retry,
- Failure/Quarantine,
- Cleanup,
- Diagnoseansicht.

Die iOS Example-App muss eine tatsächlich konfigurierte Share Extension enthalten. Android muss vollständige Intent-Filter und Receiver-Konfiguration enthalten.

UI:

- mobil,
- übersichtlich,
- Light/Dark,
- barrierefreie Labels,
- ausreichend große Touch-Ziele,
- klare Zustandsfarben,
- keine unnötigen Animationen.

Die Example-App darf die Plugin-Zuverlässigkeit demonstrieren, aber nicht unnötig zu einem eigenen Produkt anwachsen.

## Dokumentation

Liefere mindestens:

- `README.md`
- `CHANGELOG.md`
- `LICENSE`
- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`
- `SECURITY.md`
- `doc/architecture.md`
- `doc/delivery-semantics.md`
- `doc/storage-format.md`
- `doc/android-setup.md`
- `doc/ios-setup.md`
- `doc/configuration.md`
- `doc/troubleshooting.md`
- `doc/security-model.md`
- `doc/testing.md`
- `doc/performance-report.md`
- `doc/release-readiness.md`
- `doc/compatibility-matrix.md`
- API-Dokumentation

README-Reihenfolge:

1. Ein-Satz-Nutzen
2. ehrliche Garantie
3. unterstützte Plattformen und Versionen
4. Installation
5. minimale Android-Einrichtung
6. minimale iOS-Einrichtung
7. erstes vollständiges Beispiel
8. Zustellsemantik
9. Fehlerbehandlung
10. Limits
11. Doctor
12. Troubleshooting
13. weiterführende Dokumente

Kein Marketingversprechen, das Tests oder Plattformregeln nicht belegen.

## CI und Qualitätsprüfungen

Richte reproduzierbare CI-Jobs ein.

Pflichtbefehle, angepasst an die tatsächliche Toolchain:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test --coverage
dart doc
flutter pub outdated
dart pub publish --dry-run
```

Zusätzlich:

- Pigeon-Regeneration plus Git-Diff-Prüfung
- Android Gradle Unit Tests
- Android Instrumentation Tests
- iOS XCTest
- Swift Package Tests
- Xcode Build für Example-App und Share Extension
- CocoaPods-Integrationsbuild
- SwiftPM-Integrationsbuild
- Flutter Integration Tests
- `pana` auf einer Kopie des Packages
- Debug- und Release-Builds

Wenn eine Gerätefarm verfügbar ist, nutze sie für eine dokumentierte Matrix. Wenn nicht, behaupte nicht, sie verwendet zu haben.

Setze Coverage nicht als Selbstzweck ein. Priorisiere besonders hohe Branch-Coverage für:

- Zustandsmaschine,
- Manifestparser,
- Recovery,
- Quoten,
- Locking-Entscheidungen,
- Intent-/Provider-Decoder.

Native Adapter brauchen zusätzlich echte Integrationsprüfungen; 100 % gemockte Coverage beweist keine Plattformzuverlässigkeit.

## Release-Strategie

Beginne mit:

```text
0.1.0-beta.1
```

Ein Stable `1.0.0` ist erst zulässig, wenn:

- öffentliche API bewusst geprüft,
- Semantik dokumentiert,
- alle Pflichtplattformtests grün,
- Cold/Warm/Background/Terminated geprüft,
- Process-Kill-Matrix geprüft,
- SwiftPM und CocoaPods geprüft,
- Android minimale und aktuelle Toolchain geprüft,
- Pana ohne relevante Warnungen,
- Publish-Dry-Run ohne Warnungen,
- keine TODOs in kritischen Pfaden,
- keine Legacy-Dateien oder Build-Artefakte,
- reale Performancewerte dokumentiert,
- bekannte Einschränkungen veröffentlicht.

Verwende Semantic Versioning. Breaking Changes brauchen Migration Guide und passende Major-Version.

## Aktuelle Primärquellen, die vor der Implementierung erneut geprüft werden müssen

- Flutter: Developing packages and plugins  
  https://docs.flutter.dev/packages-and-plugins/developing-packages
- Flutter: Adding iOS app extensions  
  https://docs.flutter.dev/platform-integration/ios/app-extensions
- Flutter: Swift Package Manager for plugin authors  
  https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-plugin-authors
- Flutter: Swift Package Manager for app developers  
  https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers
- Flutter: Testing plugins  
  https://docs.flutter.dev/testing/testing-plugins
- Flutter: Integration tests  
  https://docs.flutter.dev/testing/integration-tests
- Flutter: Built-in Kotlin migration for plugin authors  
  https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors
- Flutter: UIScene adoption  
  https://docs.flutter.dev/release/breaking-changes/uiscenedelegate
- Apple: NSItemProvider  
  https://developer.apple.com/documentation/foundation/nsitemprovider
- Apple: loadFileRepresentation  
  https://developer.apple.com/documentation/foundation/nsitemprovider/loadfilerepresentation%28fortypeidentifier%3Acompletionhandler%3A%29
- Apple: App Extension Programming Guide  
  https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html
- Apple: Privacy manifest files  
  https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- Android: Receive simple data  
  https://developer.android.com/training/sharing/receive
- Android: Secure file sharing  
  https://developer.android.com/training/secure-file-sharing
- Android: AtomicFile  
  https://developer.android.com/reference/android/util/AtomicFile
- Pigeon  
  https://pub.dev/packages/pigeon
- Dart: Package naming  
  https://dart.dev/tools/linter-rules/package_names
- Dart: Package layout  
  https://dart.dev/tools/pub/package-layout
- Dart: Publishing  
  https://dart.dev/tools/pub/publishing
- pub.dev: Package scoring  
  https://pub.dev/help/scoring

Verwende für technische Entscheidungen Primärquellen. Blogposts und Stack Overflow können Hinweise liefern, dürfen aber keine offiziellen Plattformregeln ersetzen.

## Arbeitsphasen

### Phase 1: Recherche und ADRs

- Workspace prüfen.
- Toolchain erfassen.
- bestehende Flutter-Share-Packages und deren aktuelle APIs vergleichen.
- relevante offene/geschlossene Flutter-Plattformprobleme prüfen.
- Name prüfen.
- `doc/adr/` mit mindestens folgenden Entscheidungen erstellen:
  - Delivery Guarantee
  - Native-First Ingestion
  - File-Spool Format
  - Locking
  - Pigeon Boundary
  - Build-Time Configuration
  - iOS Extension UI
  - Version Support

### Phase 2: Pure Core

- Models
- Manifest
- State Machine
- Fake Storage
- Invariants
- Fault-Injection-Testmodell
- öffentliche API im Review stabilisieren

### Phase 3: Android

- Receiver Activity
- Decoder
- Streaming Copy
- Commit
- Locks
- Recovery
- Plugin Bridge
- Native Tests
- Integration Fixture

### Phase 4: iOS

- ShareHarborCore
- Share Extension Template
- App Group
- NSItemProvider Pipeline
- Commit
- Locks
- Recovery
- Plugin Bridge
- SwiftPM
- CocoaPods
- XCTest/XCUITest

### Phase 5: Tooling und Example

- Doctor
- Templates/Generator
- reale Example-App
- Integration Tests
- Accessibility

### Phase 6: Hardening

- Security Tests
- Fault Injection
- Process Kill
- Stress
- Performance
- Memory
- Compatibility

### Phase 7: Release

- Dokumentation
- Cleanup
- Pana
- Dry Run
- Release Readiness
- ZIP
- SHA-256

Arbeite iterativ. Analyzer, Unit Tests und Native Builds müssen während der Implementierung laufen, nicht erst am Ende.

## Definition of Done

Die Aufgabe ist erst abgeschlossen, wenn:

1. vollständiger Quellcode vorhanden ist,
2. Android und iOS nativ implementiert sind,
3. eine committed Delivery ohne ACK nicht verloren geht,
4. unvollständige Deliveries nie als pending erscheinen,
5. Claims und ACKs idempotent sind,
6. Recovery nach allen definierten Crash-Punkten getestet ist,
7. Example-App beide Plattformintegrationen enthält,
8. alle öffentlichen APIs dokumentiert sind,
9. alle verfügbaren Analyzer, Tests und Builds ausgeführt wurden,
10. echte Ergebnisse protokolliert sind,
11. keine kritischen TODOs verbleiben,
12. alte, doppelte und temporäre Bestandteile entfernt sind,
13. `dart pub publish --dry-run` ohne relevante Warnungen läuft,
14. Pana-Ergebnis dokumentiert ist,
15. ZIP erzeugt ist,
16. SHA-256-Prüfsumme erzeugt ist,
17. Release-Readiness-Bericht verbleibende Risiken ehrlich nennt.

## Abschlussbericht

Liefere am Ende:

1. finalen Package-Namen und Begründung,
2. Architekturzusammenfassung,
3. Zustellgarantie und Garantiegrenze,
4. vollständige Dateiliste,
5. Liste aller öffentlichen APIs,
6. Liste aller implementierten Plattformfälle,
7. Liste aller Tests,
8. exakte Analyzer-/Test-/Build-Ausgaben,
9. echte Coveragewerte,
10. echte Performancewerte,
11. Pana- und Publish-Dry-Run-Ergebnis,
12. bekannte Einschränkungen,
13. Sicherheitsbewertung,
14. Compatibility Matrix,
15. Release-Readiness-Entscheidung,
16. ZIP-Pfad,
17. SHA-256.

Wenn etwas nicht geprüft werden konnte, markiere es sichtbar als:

```text
NOT VERIFIED
```

Nicht als „wahrscheinlich funktioniert“ und nicht als erfundenen Erfolg.

## Letzte Leitregel

Das Produkt ist nicht erfolgreich, weil es viele Dateien oder eine schöne README besitzt. Es ist erfolgreich, wenn der folgende Vertrag unter echten Prozessabbrüchen nachweisbar gilt:

```text
committed && !acknowledged => wieder auffindbar
!committed                 => niemals ausgeliefert
acknowledged               => niemals erneut fachlich ausgeliefert
```

Optimiere jede Architektur-, API- und Testentscheidung auf diesen Vertrag.
