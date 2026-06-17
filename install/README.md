# Apinizer Kurulum Scriptleri (Sanal Sunucu / VM)

Bu klasör, Apinizer'ı **bileşen bazında** kurmak için tek başına çalıştırılabilen scriptleri içerir. Apinizer modülleri Kubernetes/konteyner olmadan, **Sanal Sunucu (Linux VM)** üzerinde standalone paketler (gömülü OpenJDK 25, systemd servisleri, Jasypt ile şifrelenmiş yapılandırma) olarak kurulur.

> **Önemli:** Bu scriptler **PoC / Test** ortamları içindir. Üretim (production) topolojileri için [docs.apinizer.com](https://docs.apinizer.com) adresindeki "Installations Overview" ve "Sanal Sunucu'ya Kurulum" sayfalarına bakın.

---

## İçerik

| Script | Görevi | Sürüm |
|--------|--------|-------|
| `install-mongodb.sh` | MongoDB (tek node replica set) + yetkili kullanıcı | MongoDB 8.0.17 |
| `install-elasticsearch.sh` | Elasticsearch (TLS + güvenlik + otomatik şifre) — opsiyonel | Elasticsearch 8.17.10 |
| `install-apinizer-manager.sh` | API Manager (VM standalone paketi) | 2026.04.2 |
| `install-apinizer-worker.sh` | Worker / API Gateway (VM standalone paketi) | 2026.04.2 |
| `install-apinizer-cache.sh` | Cache / Hazelcast (VM standalone paketi) | 2026.04.2 |
| `../installApinizer.sh` | Tüm scriptleri sırayla çalıştıran orchestrator (all-in-one) | - |

---

## Ön Gereksinimler

- **İşletim sistemi:** Ubuntu 24.04 LTS (önerilir); RHEL/Rocky/Alma 8+ de desteklenir
- **Yetki:** `sudo` yetkisine sahip bir kullanıcı (root login gerekmez)
- **Java:** Gerekmez — Apinizer paketlerinde OpenJDK 25 gömülüdür
- **Donanım (tek sunucu PoC):** 8 Core CPU, 16 GB RAM, 200 GB disk
- **Ağ erişimi:**
  - `packages.apinizer.com` (Apinizer modül paketleri)
  - `*.mongodb.org`, `artifacts.elastic.co`, `archive.ubuntu.com`, `raw.githubusercontent.com`
- **Standart araçlar:** `curl`, `tar`, `openssl`, `systemd`

> MongoDB, API Manager başlamadan önce **erişilebilir ve çalışır** durumda olmalıdır.

---

## Senaryo 1 — Tek Sunucuda Tüm Kurulum (All-in-One)

Tüm bileşenler aynı VM'e kurulur.

```bash
# Yereldeki dosyalarla
sudo bash installApinizer.sh
```

`installApinizer.sh` modülleri şu sırayla çalıştırır:

```
install-mongodb.sh  ->  install-elasticsearch.sh  ->  install-apinizer-manager.sh  ->  install-apinizer-worker.sh  ->  install-apinizer-cache.sh
```

Orchestrator, `install/` klasöründeki dosyaları yerelde bulursa onları, bulamazsa repodan indirerek çalıştırır. Tek satırlık kurulum da çalışır:

```bash
sudo curl -s https://raw.githubusercontent.com/apinizer/apinizer/main/installApinizer.sh | bash
```

---

## Senaryo 2 — Her Bileşen Ayrı Sunucuda

Her script tek başına çalışabilir; ihtiyacınız olan bileşeni ilgili sunucuda çalıştırın.

> Scriptler `NODE_IP` değerini sunucunun kendi IP'sinden otomatik bulur. MongoDB ayrı bir sunucudaysa, Manager/Gateway scriptlerinin başındaki `MONGO_HOST` değişkenini MongoDB sunucusunun IP'si olacak şekilde değiştirin.

### Önerilen kurulum sırası

```text
1) MongoDB sunucusu        ->  sudo bash install-mongodb.sh
2) Elasticsearch sunucusu  ->  sudo bash install-elasticsearch.sh   (opsiyonel)
3) Manager sunucusu        ->  sudo bash install-apinizer-manager.sh
4) Worker sunucusu         ->  sudo bash install-apinizer-worker.sh
5) Cache sunucusu          ->  sudo bash install-apinizer-cache.sh
```

### Bağımlılıklar

- `install-apinizer-manager.sh`, `install-apinizer-worker.sh` ve `install-apinizer-cache.sh`, **çalışan ve erişilebilir bir MongoDB** gerektirir.
- Worker, Manager arayüzünde tanımlanmış ve adı `APINIZER_ENVIRONMENT_NAME` (varsayılan `prod`) ile **birebir eşleşen** bir Environment olmadan proxy yüklemez.
- Cache, birden çok Worker çalıştırıldığında **zorunludur** (quota sayaçları senkron kalsın diye). Çoklu node için her node'da aynı `APINIZER_CACHE_CLUSTER_MEMBERS` IP listesi verilmelidir.
- Elasticsearch diğerlerinden bağımsızdır; herhangi bir sırada kurulabilir.

---

## Scriptler Ne Yapar?

### `install-mongodb.sh`
- MongoDB 8.0.17 kurar, tek node replica set başlatır (port `25080`).
- `apinizer` yetkili kullanıcısını oluşturur (SCRAM-SHA-1).

### `install-elasticsearch.sh`
- Elasticsearch 8.17.10 kurar (güvenlik + TLS aktif).
- Built-in kullanıcı şifrelerini otomatik üretir ve **scriptin çalıştırıldığı dizine `elastic-passwords.yaml`** olarak kaydeder.

### `install-apinizer-manager.sh`
- API Manager paketini `packages.apinizer.com`'dan indirir, checksum doğrular, `/opt/apinizer-manager`'a açar.
- `conf/application.env` içinde MongoDB bağlantısını ayarlar.
- Bundled installer'ı çalıştırır (`apinizer` sistem kullanıcısı + `master.key` + systemd servisi oluşturur), hassas değerleri Jasypt ile şifreler ve servisi başlatır.
- Manager `http://<IP>:8080` adresinde yayınlanır.

### `install-apinizer-worker.sh`
- Worker (API Gateway) paketini indirir, `/opt/apinizer-worker`'a açar.
- `conf/apinizer-worker.env` içinde MongoDB bağlantısını, `APINIZER_ENVIRONMENT_NAME` ve `WORKER_TIMEZONE` değerlerini ayarlar.
- Installer + encrypt çalıştırır, servisi başlatır.
- Worker Management API `http://<IP>:8091` adresinde yayınlanır.

### `install-apinizer-cache.sh`
- Cache (Hazelcast) paketini indirir, `/opt/apinizer-cache`'e açar.
- `conf/apinizer-cache.env` içinde MongoDB bağlantısını, `CACHE_QUOTA_TIMEZONE` ve (çoklu node için) `APINIZER_CACHE_CLUSTER_MEMBERS` değerlerini ayarlar.
- Installer + encrypt çalıştırır, servisi başlatır.
- Cache REST API `http://<IP>:8090` (Hazelcast `5701`) adresinde yayınlanır.

---

## Kurulum Sonrası

1. **Yönetim arayüzü:** `http://<SUNUCU_IP>:8080`
   - Kullanıcı: `admin`  Şifre: `Apinizer.1!`

2. **Worker'ı Environment olarak tanımlayın (zorunlu).** Manager arayüzünde:
   - `Sunucu Yönetimi > Gateway Runtime'ları > Yeni`
   - Platform: **Sanal Sunucu**, Yönetim Tipi: **Remote Gateway**
   - **Ortam Adı**, Worker scriptindeki `APINIZER_ENVIRONMENT_NAME` (varsayılan `prod`) ile birebir aynı olmalı
   - Gateway Yönetim API URL: `http://<SUNUCU_IP>:8091`
   - **Oluştur** ve **Publish** edin.

3. **Cache sunucusunu kaydedin.** Manager arayüzünde:
   - `Admin > Cache Servers > Yeni`
   - Host: `<SUNUCU_IP>`, Port: `8090`

4. **Elasticsearch bağlantısını elle ekleyin** (kullanıldıysa). Elasticsearch 8 güvenlik gerektirdiğinden bağlantı otomatik kurulmaz:
   - `Administration > Connection Management > Elasticsearch`
   - Kullanıcı `elastic`, şifre `elastic-passwords.yaml` dosyasındaki değer
   - Sertifika: `/opt/elasticsearch/elasticsearch-8.17.10/config/certs/elastic-certificates.crt`

---

## Opsiyonel Modüller

API Manager, Worker ve Cache bu kurulum akışında yer alır. İhtiyaç halinde Integration (Quartz) ve API Portal modülleri de `packages.apinizer.com` üzerinden aynı yöntemle (indir → aç → env ayarla → installer → encrypt → start) kurulabilir. Adımlar için [Sanal Sunucu'ya Kurulum](https://docs.apinizer.com) belgesine bakın.

---

## Operasyon

| İşlem | Komut |
|-------|-------|
| Durum | `sudo systemctl status apinizer-apimanager` / `apinizer-apiworker` / `apinizer-apicache` |
| Yeniden başlat | `sudo systemctl restart apinizer-apimanager` |
| Durdur | `sudo systemctl stop apinizer-apimanager` |
| Günlükler | `sudo journalctl -u apinizer-apimanager -f` |

---

## Notlar

- **Master key:** Her modülün `conf/master.key` dosyası kurulumda otomatik üretilir ve hassas değerlerin şifresini çözer. **Yedekleyin** — kaybedilirse `ENC(...)` değerleri kurtarılamaz.
- **Saat dilimi:** Manager, Gateway, Cache ve Integration arasında saat dilimi tutarlı olmalıdır (Gateway için `WORKER_TIMEZONE`, varsayılan `+03:00`).
- **JVM heap:** Paketler varsayılan olarak `-XX:MaxRAMPercentage=75.0` kullanır; hedef donanımda yük testinden sonra ayarlayın.
- **Şifreler:** Varsayılan `Apinizer.1` (MongoDB) ve `Apinizer.1!` (Apinizer admin). Üretimde mutlaka değiştirin.
