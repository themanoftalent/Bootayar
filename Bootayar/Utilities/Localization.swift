import Foundation
import SwiftUI

final class LanguageManager: ObservableObject, @unchecked Sendable {
    static let shared = LanguageManager()

    @Published private(set) var currentLanguage: String = "en"

    private init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage")
        if let saved, (saved == "tr" || saved == "en") {
            currentLanguage = saved
        } else {
            let sys = Locale.current.language.languageCode?.identifier ?? "en"
            currentLanguage = sys.hasPrefix("tr") ? "tr" : "en"
        }
    }

    func setLanguage(_ lang: String) {
        let normalized = lang.hasPrefix("tr") ? "tr" : "en"
        UserDefaults.standard.set(normalized, forKey: "appLanguage")
        UserDefaults.standard.set([normalized], forKey: "AppleLanguages")
        if Thread.isMainThread {
            currentLanguage = normalized
        } else {
            DispatchQueue.main.async {
                self.currentLanguage = normalized
            }
        }
    }

    func toggleLanguage() {
        setLanguage(currentLanguage == "en" ? "tr" : "en")
    }

    var locale: Locale {
        Locale(identifier: currentLanguage)
    }

    func localized(_ key: String) -> String {
        guard currentLanguage == "tr" else { return key }
        if let exact = Self.trTable[key] {
            return exact
        }
        return Self.translateDynamic(key)
    }

    private static func translateDynamic(_ s: String) -> String {
        if s.hasPrefix("Version ") {
            return "Sürüm " + s.dropFirst("Version ".count)
        }
        if s.hasPrefix("Bootayar v") && s.hasSuffix(" is up to date.") {
            let ver = s.dropFirst("Bootayar v".count).dropLast(" is up to date.".count)
            return "Bootayar v\(ver) güncel."
        }
        if s.hasPrefix("New version v") && s.hasSuffix(" available!") {
            let ver = s.dropFirst("New version v".count).dropLast(" available!".count)
            return "Yeni sürüm v\(ver) mevcut!"
        }
        if s.hasPrefix("Exit ") {
            return "Çıkış " + s.dropFirst("Exit ".count)
        }
        if s.hasPrefix("Every ") && s.hasSuffix("s") {
            let sec = s.dropFirst("Every ".count).dropLast(1)
            return "Her \(sec) sn"
        }
        if s.hasPrefix("Watch path: ") {
            return "İzlenen yol: " + s.dropFirst("Watch path: ".count)
        }
        if s.hasPrefix("Daily at ") {
            return "Her gün " + s.dropFirst("Daily at ".count)
        }
        if s.hasPrefix("Daily ") {
            return "Her gün " + s.dropFirst("Daily ".count)
        }
        if s.hasPrefix("Delete ") && s.hasSuffix("?") {
            let item = s.dropFirst("Delete ".count).dropLast(1)
            return "\(item) silinsin mi?"
        }
        if s.hasPrefix("Running (PID ") {
            return "Çalışıyor (PID " + s.dropFirst("Running (PID ".count)
        }
        if s.hasPrefix("Last run: exit code ") {
            return "Son çalışma: çıkış kodu " + s.dropFirst("Last run: exit code ".count)
        }
        if s.hasPrefix("Stopped (signal ") {
            return "Durduruldu (sinyal " + s.dropFirst("Stopped (signal ".count)
        }
        if s.hasPrefix("Logs — ") {
            return "Günlükler — " + s.dropFirst("Logs — ".count)
        }
        if s.hasPrefix("Container: ") {
            return "Konteyner: " + s.dropFirst("Container: ".count)
        }
        if s.hasPrefix("Image: ") {
            return "İmaj: " + s.dropFirst("Image: ".count)
        }
        return s
    }

    private static let trTable: [String: String] = [
        "%lld items": "%lld öğe",
        "%lld services": "%lld servis",
        "(Log is empty)": "(Günlük boş)",
        "(No logs)": "(Günlük yok)",
        "About Bootayar": "Bootayar Hakkında",
        "Add Rule": "Kural Ekle",
        "Add Variable": "Değişken Ekle",
        "Administrator password required to save": "Kaydetmek için yönetici parolası gerekli",
        "Administrator password required to start/stop": "Başlatmak/durdurmak için yönetici parolası gerekli",
        "Administrator password required when saving system crontab.": "Sistem crontab dosyasını kaydederken yönetici parolası gerekir.",
        "All": "Tümü",
        "Basic Info": "Temel Bilgiler",
        "Before You Delete a Task": "Bir Görevi Silmeden Önce",
        "Bootayar Help": "Bootayar Yardım",
        "Bootayar is up to date.": "Bootayar güncel.",
        "Bootayar v%@ is up to date.": "Bootayar v%@ güncel.",
        "Brew: started, waiting for process": "Brew: başlatıldı, işlem bekleniyor",
        "Browse Launch Agent Templates…": "Launch Agent Şablonlarına Göz At…",
        "Browse…": "Göz At…",
        "Buy Me a Coffee": "Bana Kahve Ismarla",
        "Cancel": "İptal",
        "Cannot encode XML": "XML kodlanamadı",
        "Cannot load plist; check syntax and file path": "Plist yüklenemedi; sözdizimini ve dosya yolunu kontrol edin",
        "Cannot locate Docker container; terminating docker-proxy directly would break Docker networking. Use docker stop or Docker Desktop.": "Docker konteyneri bulunamadı; docker-proxy'yi doğrudan sonlandırmak Docker ağını bozar. docker stop veya Docker Desktop kullanın.",
        "Check for Updates…": "Güncellemeleri Denetle…",
        "Checking…": "Denetleniyor…",
        "Choose Tools": "Araçları Seç",
        "Choose Your Tools": "Araçlarınızı Seçin",
        "Choose which tools appear in the sidebar": "Kenar çubuğunda hangi araçların görüneceğini seçin",
        "Clear Log": "Günlüğü Temizle",
        "Click Refresh to load system logs": "Sistem günlüklerini yüklemek için Yenile'ye tıklayın",
        "Clone Agent": "Aracıyı Kopyala",
        "Clone…": "Kopyala…",
        "Close": "Kapat",
        "Command": "Komut",
        "Command to execute": "Çalıştırılacak komut",
        "Container": "Konteyner",
        "Container ID": "Konteyner Kimliği",
        "Copied": "Kopyalandı",
        "Copy Address": "Adresi Kopyala",
        "Copy Command": "Komutu Kopyala",
        "Create": "Oluştur",
        "Create Launch Agent…": "Launch Agent Oluştur…",
        "Crontab": "Crontab",
        "Crontab Header": "Crontab Başlığı",
        "Current Version": "Mevcut Sürüm",
        "Custom": "Özel",
        "Custom Calendar": "Özel Takvim",
        "Custom Months": "Özel Aylar",
        "Custom calendar": "Özel takvim",
        "Daemon": "Daemon",
        "Daily": "Günlük",
        "Day": "Gün",
        "Day of Month": "Ayın Günü",
        "Days": "Günler",
        "Delete": "Sil",
        "Delete Group": "Grubu Sil",
        "Delete this Cron job?": "Bu Cron görevi silinsin mi?",
        "Deleting a task configuration does not delete its app. Changes to system tasks may require an administrator password.": "Bir görev yapılandırmasını silmek uygulamasını silmez. Sistem görevlerindeki değişiklikler yönetici parolası gerektirebilir.",
        "Developed by:": "Geliştiren Firma:",
        "Developer & support": "Geliştirici ve destek",
        "Developer:": "Geliştirici:",
        "Direct Download": "Doğrudan İndir",
        "Disable": "Devre Dışı Bırak",
        "Disabled": "Devre Dışı",
        "Disabled by system (launchctl override)": "Sistem tarafından devre dışı bırakıldı (launchctl override)",
        "Display & Scanning": "Görünüm ve Tarama",
        "Display Name": "Görünen Ad",
        "Docker Port Forward": "Docker Port Yönlendirme",
        "Docker executable not found": "Docker çalıştırılabilir dosyası bulunamadı",
        "Done": "Bitti",
        "Download Bootayar.dmg": "Bootayar.dmg İndir",
        "Edit": "Düzenle",
        "Edit Agent": "Aracıyı Düzenle",
        "Edit Cron Job": "Cron Görevini Düzenle",
        "Edit Mode": "Düzenleme Modu",
        "Edit Task Settings": "Görev Ayarlarını Düzenle",
        "Edit in XML": "XML Olarak Düzenle",
        "Enable": "Etkinleştir",
        "Enabled": "Etkin",
        "Enabling…": "Etkinleştiriliyor…",
        "Environment Variables (optional)": "Ortam Değişkenleri (isteğe bağlı)",
        "Error": "Hata",
        "Every": "Her",
        "Every 24 hours (86400s)": "Her 24 saatte bir (86400 sn)",
        "Every Month": "Her Ay",
        "Every hour on the hour": "Her saat başı",
        "Every minute": "Her dakika",
        "Executable": "Çalıştırılabilir Dosya",
        "Exit %lld": "Çıkış %lld",
        "Exit Code": "Çıkış Kodu",
        "Expression": "İfade",
        "Feel free to fork, modify, use, and contribute!": "Çatallamaktan, değiştirmekten, kullanmaktan ve katkıda bulunmaktan çekinmeyin!",
        "File Header": "Dosya Başlığı",
        "File Logs": "Dosya Günlükleri",
        "File Modified on Disk": "Dosya Diskte Değiştirildi",
        "File already exists": "Dosya zaten mevcut",
        "File already exists. Overwrite?": "Dosya zaten mevcut. Üzerine yazılsın mı?",
        "File or path does not exist": "Dosya veya yol mevcut değil",
        "Filter keywords": "Anahtar kelimeleri filtrele",
        "Find background startup tasks and Homebrew services": "Arka plan başlangıç görevlerini ve Homebrew servislerini bulun",
        "Find local network ports and running services": "Yerel ağ portlarını ve çalışan servisleri bulun",
        "Find personal and system scheduled tasks": "Kişisel ve sistem zamanlanmış görevlerini bulun",
        "Follow & Support": "Takip Et ve Destekle",
        "Form": "Form",
        "Formula": "Formül",
        "Frequency": "Sıklık",
        "Fri": "Cum",
        "Get Started": "Başla",
        "GitHub": "GitHub",
        "GitHub:": "GitHub:",
        "Global": "Genel",
        "Global Agents": "Genel Aracılar",
        "Global · /Library": "Genel · /Library",
        "HELP": "YARDIM",
        "Homebrew not found. Please install Homebrew or verify brew is in PATH.": "Homebrew bulunamadı. Lütfen Homebrew yükleyin veya brew komutunun PATH içinde olduğunu doğrulayın.",
        "Host Mechanism": "Ana Sistem Mekanizması",
        "Hour": "Saat",
        "Hourly": "Saatlik",
        "Hours": "Saat",
        "How Login Items Differ from Launchd": "Oturum Açma Öğeleri ile Launchd Arasındaki Fark",
        "If you find this project useful, star the repository, follow me, or buy me a coffee! Your support helps keep future projects free and open-source.": "Bu projeyi faydalı bulduysanız depoya yıldız verin, beni takip edin veya bir kahve ısmarlayın! Desteğiniz gelecekteki projelerin ücretsiz ve açık kaynak kalmasına yardımcı olur.",
        "Image": "İmaj",
        "Import": "İçe Aktar",
        "Import Into": "Şuraya İçe Aktar",
        "Import Plist": "Plist İçe Aktar",
        "Installed brew formulas will appear in their scope once started": "Yüklü brew paketleri başlatıldığında ilgili kapsamda görünür",
        "Insufficient permissions or path is inaccessible": "Yetersiz izin veya yola erişilemiyor",
        "Interval": "Aralık",
        "Invalid": "Geçersiz",
        "Invalid Config": "Geçersiz Yapılandırma",
        "Invalid plist": "Geçersiz plist",
        "Keep Alive (restart automatically on crash)": "Canlı Tut (çöktüğünde otomatik yeniden başlat)",
        "Keep At Least One Module": "En Az Bir Araç Seçili Kalmalı",
        "Keep at least one tool selected. Hidden tools stop checking for updates in the background.": "En az bir aracı seçili tutun. Gizlenen araçlar arka planda tarama yapmayı durdurur.",
        "KeepAlive uses a format not supported by the form editor. Please edit in XML mode.": "KeepAlive form düzenleyicinin desteklemediği bir biçim kullanıyor. Lütfen XML modunda düzenleyin.",
        "Label": "Etiket (Label)",
        "Label already exists": "Bu etiket zaten mevcut",
        "Language": "Dil",
        "Last run: exited normally (0)": "Son çalışma: normal şekilde sonlandı (0)",
        "Later": "Daha Sonra",
        "Latest Version": "Son Sürüm",
        "Launch Agents": "Başlangıç Aracıları",
        "LaunchDaemons": "Sistem Servisleri (LaunchDaemons)",
        "Launchd (Managed by Bootayar)": "Launchd (Bootayar ile Yönetilir)",
        "Learn how macOS Login Items work below, then manage them in System Settings.": "macOS Oturum Açma Öğelerinin nasıl çalıştığını aşağıdan öğrenin ve Sistem Ayarları'ndan yönetin.",
        "Listening": "Dinliyor",
        "Load": "Yükle",
        "Load Agent Now?": "Aracı Şimdi Yüklensin mi?",
        "Loaded": "Yüklendi",
        "Loaded, waiting for trigger": "Yüklendi, tetikleyici bekleniyor",
        "Loading…": "Yükleniyor…",
        "Local Instances": "Yerel Servisler",
        "Local ports and services": "Yerel portlar ve servisler",
        "Log Paths (optional)": "Günlük Yolları (isteğe bağlı)",
        "Login Items": "Oturum Açma Öğeleri",
        "Login Items (Managed in System Settings)": "Oturum Açma Öğeleri (Sistem Ayarları'nda Yönetilir)",
        "Manage Startup Tasks": "Başlangıç Görevlerini Yönet",
        "Manage apps that open at login": "Oturum açıldığında başlayan uygulamaları yönetin",
        "Manage startup apps, background services, and scheduled tasks.": "Başlangıç uygulamalarını, arka plan servislerini ve zamanlanmış görevleri yönetin.",
        "Managed By": "Yöneten",
        "Many Login Items correspond to a launchd plist. If they appear under Launch Agents or LaunchDaemons, manage them right here in Bootayar.": "Birçok Oturum Açma Öğesi bir launchd plist dosyasına karşılık gelir. Başlangıç Aracıları altında görünüyorlarsa doğrudan Bootayar içinden yönetebilirsiniz.",
        "Min": "Dk",
        "Minute": "Dakika",
        "Minutes": "Dakika",
        "Mon": "Pzt",
        "Month": "Ay",
        "Monthly": "Aylık",
        "Months": "Aylar",
        "Months:": "Aylar:",
        "New": "Yeni",
        "New Agent": "Yeni Aracı",
        "New Cron Job": "Yeni Cron Görevi",
        "New Global Agent": "Yeni Genel Aracı",
        "New Job": "Yeni Görev",
        "New LaunchDaemon": "Yeni LaunchDaemon",
        "New System Cron Job": "Yeni Sistem Cron Görevi",
        "New User Agent": "Yeni Kullanıcı Aracısı",
        "New User Cron Job": "Yeni Kullanıcı Cron Görevi",
        "New version v%@ available!": "Yeni sürüm v%@ mevcut!",
        "No Agents": "Aracı Yok",
        "No Automatic Trigger": "Otomatik Tetikleyici Yok",
        "No Cron Jobs": "Cron Görevi Yok",
        "No Dev Services Found": "Geliştirme Servisi Bulunamadı",
        "No Homebrew Services": "Homebrew Servisi Yok",
        "No LaunchAgents or LaunchDaemons found": "LaunchAgent veya LaunchDaemon bulunamadı",
        "No Log File Configured": "Günlük Dosyası Yapılandırılmadı",
        "No Matching Results": "Eşleşen Sonuç Yok",
        "No Services Found": "Servis Bulunamadı",
        "No environment variables": "Ortam değişkeni yok",
        "No listening TCP services found": "Dinleyen TCP servisi bulunamadı",
        "Not loaded": "Yüklü değil",
        "OK": "Tamam",
        "One argument per line": "Her satıra bir argüman",
        "Open": "Aç",
        "Open Guide": "Rehberi Aç",
        "Open Login Items Settings": "Oturum Açma Öğeleri Ayarlarını Aç",
        "Open Source | Free to Fork & Use": "Açık Kaynak | Ücretsiz Kullanım ve Çatallama",
        "Open the User Guide?": "Kullanım Kılavuzu Açılsın mı?",
        "Open the login items guide and System Settings": "Oturum açma öğeleri rehberini ve Sistem Ayarları'nı açın",
        "Operation cancelled": "İşlem iptal edildi",
        "Options": "Seçenekler",
        "Order is for display only and does not affect priority.": "Sıralama yalnızca görünüm içindir, çalışma önceliğini etkilemez.",
        "Orphaned": "Sahipsiz",
        "Other Trigger Conditions": "Diğer Tetikleme Koşulları",
        "Other trigger conditions": "Diğer tetikleme koşulları",
        "Overwrite": "Üzerine Yaz",
        "PID %lld": "PID %lld",
        "Paste from XML…": "XML'den Yapıştır…",
        "Path": "Yol",
        "Permission denied": "İzin reddedildi",
        "Personal and system schedules": "Kişisel ve sistem zamanlamaları",
        "Please use XML mode to edit this rule.": "Bu kuralı düzenlemek için lütfen XML modunu kullanın.",
        "Plist must contain a Label key": "Plist bir Label anahtarı içermelidir",
        "Ports": "Portlar",
        "Privilege": "Yetki",
        "Process Dir": "İşlem Dizini",
        "Program": "Program",
        "Program Path": "Program Yolu",
        "Project Dir": "Proje Dizini",
        "Quarterly": "Üç Ayda Bir",
        "Refresh": "Yenile",
        "Register & Start": "Kaydet ve Başlat",
        "Reload": "Yeniden Yükle",
        "Reset to Auto": "Otomatiğe Sıfırla",
        "Restart": "Yeniden Başlat",
        "Restarting…": "Yeniden Başlatılıyor…",
        "Run as User": "Kullanıcı Olarak Çalıştır",
        "Run at Login": "Oturum Açıldığında Çalıştır",
        "Run at login": "Oturum açıldığında çalıştır",
        "Run once when loaded at login; also runs when manually reloaded.": "Oturum açıldığında yüklendiğinde bir kez çalışır; elle yeniden yüklendiğinde de çalışır.",
        "Run tasks at set times, at intervals, or when files change": "Görevleri belirli saatlerde, aralıklarda veya dosyalar değiştiğinde çalıştırın",
        "Running": "Çalışıyor",
        "SSH Port Forward": "SSH Port Yönlendirme",
        "Sat": "Cmt",
        "Save": "Kaydet",
        "Saving will reload the job and may run it immediately.": "Kaydetmek görevi yeniden yükler ve hemen çalıştırabilir.",
        "Scan Failed": "Tarama Başarısız",
        "Schedule": "Zamanlama",
        "Schedule Tasks": "Görevleri Zamanla",
        "Scheduled Tasks": "Zamanlanmış Görevler",
        "Scope": "Kapsam",
        "Search command or schedule": "Komut veya zamanlama ara",
        "Search label, path, or formula": "Etiket, yol veya paket ara",
        "Search service, port, or project…": "Servis, port veya proje ara…",
        "Seconds": "Saniye",
        "See local network ports, Homebrew services, and Docker containers": "Yerel ağ portlarını, Homebrew servislerini ve Docker konteynerlerini görün",
        "Select Choose Tools at the bottom left to show this tool.": "Bu aracı göstermek için sol alttaki Araçları Seç düğmesini kullanın.",
        "Select at least one tool to continue.": "Devam etmek için en az bir araç seçin.",
        "Semi-Annually": "Altı Ayda Bir",
        "Service is already loaded": "Servis zaten yüklü",
        "Service is not loaded or already stopped": "Servis yüklü değil veya zaten durdurulmuş",
        "Services": "Servisler",
        "Set StandardOutPath / StandardErrorPath in Edit Agent to enable file logging.": "Dosya günlüğünü etkinleştirmek için Aracıyı Düzenle içinde StandardOutPath / StandardErrorPath ayarlayın.",
        "Show All": "Tümünü Göster",
        "Skip This Version": "Bu Sürümü Atla",
        "Sponsor Me": "Sponsor Ol",
        "Start": "Başlat",
        "Start a dev server or enable Show All": "Bir geliştirme sunucusu başlatın veya Tümünü Göster'i açın",
        "Starting": "Başlatılıyor",
        "Starting…": "Başlatılıyor…",
        "Startup Tasks": "Başlangıç Görevleri",
        "Status": "Durum",
        "Stop": "Durdur",
        "Stop Container": "Konteyneri Durdur",
        "Stop Container?": "Konteyner Durdurulsun mu?",
        "Stop Container…": "Konteyneri Durdur…",
        "Stopped": "Durduruldu",
        "Stopping…": "Durduruluyor…",
        "Sun": "Paz",
        "Switch to English": "İngilizce'ye geç",
        "Switch to Turkish": "Türkçe'ye geç",
        "System Crontab": "Sistem Crontab",
        "System Logs": "Sistem Günlükleri",
        "System Service (launchd)": "Sistem Servisi (launchd)",
        "System Services": "Sistem Servisleri",
        "System · /Library": "Sistem · /Library",
        "Terminate Process": "İşlemi Sonlandır",
        "Terminate Process…": "İşlemi Sonlandır…",
        "Terminate Service?": "Servis Sonlandırılsın mı?",
        "The file on disk was modified externally. Reloading will discard unsaved changes.": "Diskteki dosya dışarıdan değiştirildi. Yeniden yüklemek kaydedilmemiş değişiklikleri siler.",
        "The user guide will open in your web browser.": "Kullanım kılavuzu web tarayıcınızda açılacaktır.",
        "This file is empty or malformed and cannot be loaded by launchd.": "Bu dosya boş veya hatalı biçimlendirilmiş ve launchd tarafından yüklenemiyor.",
        "This plist contains keys not supported by the form editor. Please edit in XML mode.": "Bu plist form düzenleyicinin desteklemediği anahtarlar içeriyor. Lütfen XML modunda düzenleyin.",
        "This rule maps to multiple calendar entries. Deleting it will remove the entire group.": "Bu kural birden fazla takvim girdisine karşılık geliyor. Silmek tüm grubu kaldırır.",
        "This will permanently delete the plist file. This cannot be undone.": "Bu işlem plist dosyasını kalıcı olarak silecektir. Geri alınamaz.",
        "This will unload and permanently delete the plist file. This cannot be undone.": "Bu işlem görevi kaldıracak ve plist dosyasını kalıcı olarak silecektir. Geri alınamaz.",
        "Thu": "Per",
        "Tool Hidden": "Araç Gizli",
        "Trigger": "Tetikleyici",
        "Trigger rules act independently; the job starts when any rule fires.": "Tetikleme kuralları bağımsız çalışır; herhangi bir kural tetiklendiğinde görev başlar.",
        "Triggers": "Tetikleyiciler",
        "Triggers may be skipped while asleep or already running.": "Bilgisayar uykudayken veya görev zaten çalışıyorken tetikleyiciler atlanabilir.",
        "Try a different search query": "Farklı bir arama sorgusu deneyin",
        "Tue": "Sal",
        "Type": "Tür",
        "Unable to check GitHub releases right now.": "Şu anda GitHub sürümleri denetlenemiyor.",
        "Unknown": "Bilinmiyor",
        "Unload": "Kaldır",
        "Unloaded": "Kaldırıldı",
        "Unloading…": "Kaldırılıyor…",
        "Unregistered": "Kayıtsız",
        "Unregistered Homebrew Services": "Kayıtsız Homebrew Servisleri",
        "Unresponsive": "Yanıt Vermiyor",
        "Update Available": "Güncelleme Mevcut",
        "Upgrade via Homebrew": "Homebrew ile Güncelle",
        "Use a simple form or edit the configuration file directly": "Basit bir form kullanın veya yapılandırma dosyasını doğrudan düzenleyin",
        "User": "Kullanıcı",
        "User Agents": "Kullanıcı Aracıları",
        "User Crontab": "Kullanıcı Crontab",
        "User Guide": "Kullanım Kılavuzu",
        "User Services": "Kullanıcı Servisleri",
        "User crontab and /etc/crontab are empty. Click New to add a scheduled job.": "Kullanıcı crontab ve /etc/crontab boş. Zamanlanmış bir görev eklemek için Yeni'ye tıklayın.",
        "User · ~/Library": "Kullanıcı · ~/Library",
        "User, system, and Homebrew tasks": "Kullanıcı, sistem ve Homebrew görevleri",
        "Value": "Değer",
        "Version %@": "Sürüm %@",
        "View Logs": "Günlükleri Gör",
        "View Release on GitHub": "Sürümü GitHub'da Gör",
        "View Services and Ports": "Servisleri ve Portları Gör",
        "View and manage tasks that start automatically, without using Terminal": "Otomatik başlayan görevleri Terminal kullanmadan görüntüleyin ve yönetin",
        "Watch Path": "Yolu İzle",
        "Watches the specified path for changes. Events may coalesce.": "Belirtilen yoldaki değişiklikleri izler.",
        "Wed": "Çar",
        "Weekday": "Haftanın Günü",
        "Weekdays": "Hafta İçi",
        "Weekly": "Haftalık",
        "Welcome to Bootayar": "Bootayar'a Hoş Geldiniz",
        "Working Directory": "Çalışma Dizini",
        "WorkingDirectory (optional)": "Çalışma Dizini (isteğe bağlı)",
        "YOUR TOOLS": "ARAÇLARINIZ",
        "Yearly": "Yıllık",
        "macOS Startup & Automation Manager": "macOS Başlangıç ve Otomasyon Yöneticisi",
    ]
}

func L(_ key: String) -> String {
    LanguageManager.shared.localized(key)
}
