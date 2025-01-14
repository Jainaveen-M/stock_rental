// import 'dart:convert';
// import 'dart:io';
// import 'package:googleapis/drive/v3.dart' as drive;
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:archive/archive.dart';
// import 'package:path/path.dart' as path;
// import 'package:sembast/sembast.dart';
// import 'package:googleapis_auth/googleapis_auth.dart' as auth;
// import 'package:http/http.dart' as http;

// class BackupSettings {
//   final String? lastBackupDate;
//   final bool autoBackupEnabled;

//   BackupSettings({
//     this.lastBackupDate,
//     this.autoBackupEnabled = false,
//   });
// }

// class BackupService {
//   final GoogleSignIn _googleSignIn = GoogleSignIn(
//     scopes: [
//       'email',
//       'https://www.googleapis.com/auth/drive.file',
//     ],
//   );

//   Future<void> performBackup() async {
//     // 1. Sign in to Google
//     final GoogleSignInAccount? account = await _googleSignIn.signIn();
//     if (account == null) throw Exception('Google Sign in failed');

//     // 2. Get auth headers
//     final GoogleSignInAuthentication auth = await account.authentication;
//     final headers = await account.authHeaders;

//     // 3. Create Drive API client
//     final authClient = await auth.clientViaGoogle(account);
//     final client = drive.DriveApi(authClient);

//     // 4. Create backup zip file
//     final backupFile = await _createBackupZip();

//     // 5. Upload to Drive
//     var driveFile = drive.File();
//     driveFile.name =
//         'stock_rental_backup_${DateTime.now().toIso8601String()}.zip';
//     driveFile.parents = ['appDataFolder']; // Store in app-specific folder

//     await client.files.create(
//       driveFile,
//       uploadMedia: drive.Media(
//         File(backupFile.path).openRead(),
//         backupFile.lengthSync(),
//       ),
//     );

//     // 6. Update backup settings
//     await _updateBackupSettings(DateTime.now());
//   }

//   Future<File> _createBackupZip() async {
//     final appDir = await getApplicationDocumentsDirectory();
//     final dbDir = appDir.path;

//     // Create archive
//     final archive = Archive();

//     // Add database files to archive
//     final dbFiles =
//         Directory(dbDir).listSync().where((file) => file.path.endsWith('.db'));

//     for (var file in dbFiles) {
//       final bytes = await File(file.path).readAsBytes();
//       final archiveFile = ArchiveFile(
//         path.basename(file.path),
//         bytes.length,
//         bytes,
//       );
//       archive.addFile(archiveFile);
//     }

//     // Save archive to temp file
//     final zipFile = File(path.join(dbDir, 'backup.zip'));
//     final zipBytes = ZipEncoder().encode(archive);
//     if (zipBytes != null) {
//       await zipFile.writeAsBytes(zipBytes);
//     }

//     return zipFile;
//   }

//   Future<void> _updateBackupSettings(DateTime backupDate) async {
//     // Save backup settings to local storage
//     final appDir = await getApplicationDocumentsDirectory();
//     final settingsFile = File('${appDir.path}/backup_settings.json');
//     await settingsFile.writeAsString(
//       '{"lastBackupDate": "${backupDate.toIso8601String()}", "autoBackupEnabled": true}',
//     );
//   }

//   Future<BackupSettings> getBackupSettings() async {
//     try {
//       final appDir = await getApplicationDocumentsDirectory();
//       final settingsFile = File('${appDir.path}/backup_settings.json');
//       if (!await settingsFile.exists()) {
//         return BackupSettings();
//       }
//       final contents = await settingsFile.readAsString();
//       final json = jsonDecode(contents);
//       return BackupSettings(
//         lastBackupDate: json['lastBackupDate'],
//         autoBackupEnabled: json['autoBackupEnabled'] ?? false,
//       );
//     } catch (e) {
//       return BackupSettings();
//     }
//   }

//   Future<void> setAutoBackup(bool enabled) async {
//     final settings = await getBackupSettings();
//     final appDir = await getApplicationDocumentsDirectory();
//     final settingsFile = File('${appDir.path}/backup_settings.json');
//     await settingsFile.writeAsString(
//       '{"lastBackupDate": "${settings.lastBackupDate}", "autoBackupEnabled": $enabled}',
//     );
//   }
// }
