# Apinizer API Lifecycle Management Platform
Apinizer is a product family that enables the following tasks to be done easily and quickly with simple configurations, without writing code as much as possible:

- Apinizer API Gateway: Performing security, traffic management, load balancing, logging, message content conversion and enrichment, validation, testing and many other tasks related to API/Web Services by configuration via form-based interfaces without writing code.
- Apinizer API Creator → Mock API Creator: Creating and publishing a Mock API instantly without the need for any server or writing code.
- Apinizer API Creator → DB-2-API: Creating and publishing an API/Web Service for database operations instantly without the need for a server, or the need for writing code other than SQL.
- Apinizer API Creator → Script-2-API: Creating and publishing an API/Web Service for JavaScript or Groovy code instantly without the need for a server.
- Apinizer API Monitor: Automatic and continuous monitoring of whether API/Web Services or external systems are working properly and being notified of problems instantly.
- Apinizer API Analytics: Visualizing performance, usage detail, error metrics, and etc. of API/Web Services.
- Apinizer API Portal: Providing API/Web Services documentation, trial opportunity, and collaboration platform to stakeholders.
- API Portal: An individual product in Apinizer family that is not natively integrated to Apinizer and can be used independently, optionally in front of any API Gateway. It provides documentation, trial opportunity, collaboration platform and pricing plans to stakeholders.
- Apinizer Integrator: Meeting and automating integration tasks without code, and optionally exposing as an API/Web Service.
- Apinizer Platform: Providing API teams a single, integrated API Development Lifecycle Management platform which users with various roles can work collaboratively and operate API lifecycle steps such as requirement setting, documentation, design, development, testing, publishing, versioning, monitoring, analytics, reporting and releasing.

# Documentation
You can find documentation at https://docs.apinizer.com. 
Official web site is at https://apinizer.com. 

# Getting Started

Bu bölüm iki kısımdan oluşur: önce **Kurulum** (Sanal Sunucu / VM üzerine bileşen bazında kurulum), ardından **Yapılandırma & Kullanım** (Yönetim Konsolu'na giriş ve ilk API Proxy'nin oluşturulması).

## 1. Installation

Apinizer modülleri Kubernetes/konteyner olmadan, **Sanal Sunucu (Linux VM)** üzerinde standalone paketler (gömülü OpenJDK 25, systemd servisleri, Jasypt ile şifrelenmiş yapılandırma) olarak kurulur. `components/` dizinindeki scriptler her bileşeni tek başına kurabilir; `installApinizer.sh` ise hepsini sırayla çalıştıran orchestrator'dır.

> **Önemli:** Bu scriptler **PoC / Test** ortamları içindir. Üretim (production) topolojileri için [docs.apinizer.com](https://docs.apinizer.com) adresindeki "Installations Overview" ve "Sanal Sunucu'ya Kurulum" sayfalarına bakın.

### Minimum Requirements (single-server PoC / Test)
- 8 Core CPU
- 16 GB Ram
- 200 GB Disk

This all-in-one script installs MongoDB 8.0, Elasticsearch 8.17 and the Apinizer modules (API Manager + Gateway) as standalone Virtual Server (Linux VM) packages with embedded OpenJDK 25 — no Kubernetes/containers required. It is intended for PoC/Test environments only; for production topologies see https://docs.apinizer.com.

#### Run the following script on Ubuntu 24.04 LTS version to install Apinizer.
```
sudo curl -s https://raw.githubusercontent.com/apinizer/apinizer/main/installApinizer.sh | bash
```

### İçerik

| Script | Görevi | Sürüm |
|--------|--------|-------|
| `install-mongodb.sh` | MongoDB (tek node replica set) + yetkili kullanıcı | MongoDB 8.0.17 |
| `install-elasticsearch.sh` | Elasticsearch (TLS + güvenlik + otomatik şifre) — opsiyonel | Elasticsearch 8.17.10 |
| `install-apinizer-manager.sh` | API Manager (VM standalone paketi) | 2026.04.2 |
| `install-apinizer-worker.sh` | Worker / API Gateway (VM standalone paketi) | 2026.04.2 |
| `install-apinizer-cache.sh` | Cache / Hazelcast (VM standalone paketi) | 2026.04.2 |
| `installApinizer.sh` | Tüm scriptleri sırayla çalıştıran orchestrator (all-in-one) | - |

### Sürüm Seçimi (VERSION) — ÖNEMLİ

Apinizer paketleri (`manager`, `worker`, `cache`) `packages.apinizer.com` üzerinden indirilir. Scriptlerdeki varsayılan `VERSION` değeri o an **yayınlanmamış** olabilir; bu durumda indirme `404` döner ve kurulum durur. Kurmadan önce indirmek istediğiniz sürümü ayarlayın.

**Yöntem 1 — Scripti düzenleyin:**

```bash
sudo vi components/install-apinizer-manager.sh
# Baştaki satırı kendi sürümünüzle değiştirin:
#   VERSION="${VERSION:-2026.04.2}"   ->   VERSION="${VERSION:-<istediğiniz-sürüm>}"
```

**Yöntem 2 — Çalıştırırken ortam değişkeniyle geçin (script dosyasını değiştirmeden):**

```bash
sudo -E VERSION=2026.04.2 bash components/install-apinizer-manager.sh
sudo -E VERSION=2026.04.2 bash components/install-apinizer-worker.sh
sudo -E VERSION=2026.04.2 bash components/install-apinizer-cache.sh
```

> Aynı kural Worker ve Cache scriptleri için de geçerlidir. Hatalı/yayınlanmamış bir sürüm verilirse scriptler net bir hata mesajıyla durur (sonsuz/anlaşılmaz hata vermez).

### Ön Gereksinimler

- **İşletim sistemi:** Ubuntu 24.04 LTS (önerilir); RHEL/Rocky/Alma 8+ de desteklenir
- **Yetki:** `sudo` yetkisine sahip bir kullanıcı (root login gerekmez)
- **Java:** Gerekmez — Apinizer paketlerinde OpenJDK 25 gömülüdür
- **Donanım (tek sunucu PoC):** 8 Core CPU, 16 GB RAM, 200 GB disk
- **Ağ erişimi:**
  - `packages.apinizer.com` (Apinizer modül paketleri)
  - `*.mongodb.org`, `artifacts.elastic.co`, `archive.ubuntu.com`, `raw.githubusercontent.com`
- **Standart araçlar:** `curl`, `tar`, `openssl`, `systemd`

> MongoDB, API Manager başlamadan önce **erişilebilir ve çalışır** durumda olmalıdır.

### Senaryo 1 — Tek Sunucuda Tüm Kurulum (All-in-One)

Tüm bileşenler aynı VM'e kurulur.

```bash
# Yereldeki dosyalarla
sudo bash installApinizer.sh
```

`installApinizer.sh` modülleri şu sırayla çalıştırır:

```
install-mongodb.sh  ->  install-elasticsearch.sh  ->  install-apinizer-manager.sh  ->  install-apinizer-worker.sh  ->  install-apinizer-cache.sh
```

Orchestrator, `components/` klasöründeki dosyaları yerelde bulursa onları, bulamazsa repodan indirerek çalıştırır. Tek satırlık kurulum da çalışır:

```bash
sudo curl -s https://raw.githubusercontent.com/apinizer/apinizer/main/installApinizer.sh | bash
```

### Senaryo 2 — Her Bileşen Ayrı Sunucuda

Her script tek başına çalışabilir; ihtiyacınız olan bileşeni ilgili sunucuda çalıştırın.

> Scriptler `NODE_IP` değerini sunucunun kendi IP'sinden otomatik bulur. MongoDB ayrı bir sunucudaysa, Manager/Gateway scriptlerinin başındaki `MONGO_HOST` değişkenini MongoDB sunucusunun IP'si olacak şekilde değiştirin.

#### Önerilen kurulum sırası

```text
1) MongoDB sunucusu        ->  sudo bash components/install-mongodb.sh
2) Elasticsearch sunucusu  ->  sudo bash components/install-elasticsearch.sh   (opsiyonel)
3) Manager sunucusu        ->  sudo bash components/install-apinizer-manager.sh
4) Worker sunucusu         ->  sudo bash components/install-apinizer-worker.sh
5) Cache sunucusu          ->  sudo bash components/install-apinizer-cache.sh
```

#### Bağımlılıklar

- `install-apinizer-manager.sh`, `install-apinizer-worker.sh` ve `install-apinizer-cache.sh`, **çalışan ve erişilebilir bir MongoDB** gerektirir.
- Worker, Manager arayüzünde tanımlanmış ve adı `APINIZER_ENVIRONMENT_NAME` (varsayılan `prod`) ile **birebir eşleşen** bir Environment olmadan proxy yüklemez.
- Cache, birden çok Worker çalıştırıldığında **zorunludur** (quota sayaçları senkron kalsın diye). Çoklu node için her node'da aynı `APINIZER_CACHE_CLUSTER_MEMBERS` IP listesi verilmelidir.
- Elasticsearch diğerlerinden bağımsızdır; herhangi bir sırada kurulabilir.

### Scriptler Ne Yapar?

#### `install-mongodb.sh`
- MongoDB 8.0.17 kurar, tek node replica set başlatır (port `25080`).
- `apinizer` yetkili kullanıcısını oluşturur (SCRAM-SHA-1).

#### `install-elasticsearch.sh`
- Elasticsearch 8.17.10 kurar (güvenlik + TLS aktif).
- Built-in kullanıcı şifrelerini otomatik üretir ve **scriptin çalıştırıldığı dizine `elastic-passwords.yaml`** olarak kaydeder. Tüm şifreler ayrıca `/opt/elasticsearch/elasticsearch-passwords.txt` dosyasına da yazılır.
- Şifre üretmeden önce Elasticsearch'in HTTP olarak gerçekten **ayağa kalkmasını bekler** (sabit `sleep` yerine aktif kontrol). ES yeterince hızlı açılmazsa veya cluster hazır olmazsa, `setup-passwords` tekrar denenir ve başarısız olursa script **net bir hata mesajıyla durur** ("password üretilemedi" yerine sessizce devam etmez).

> **Şifre üretilemedi hatası alırsanız:** Genellikle ES tam ayağa kalkmamıştır. `sudo journalctl -u elasticsearch -f` ile logları kontrol edin; `vm.max_map_count`, bellek (heap) ve disk izinlerinin uygun olduğundan emin olun. ES bir kez tam açıldıktan sonra scripti tekrar çalıştırmak yerine `elasticsearch-reset-password -u elastic` ile şifreyi sıfırlayabilirsiniz (`setup-passwords auto` yalnızca bir kez çalışır).

#### `install-apinizer-manager.sh`
- API Manager paketini `packages.apinizer.com`'dan indirir, checksum doğrular, `/opt/apinizer-manager`'a açar.
- `conf/application.env` içinde MongoDB bağlantısını ayarlar.
- Bundled installer'ı çalıştırır (`apinizer` sistem kullanıcısı + `master.key` + systemd servisi oluşturur), hassas değerleri Jasypt ile şifreler ve servisi başlatır.
- Manager `http://<IP>:8080` adresinde yayınlanır.

#### `install-apinizer-worker.sh`
- Worker (API Gateway) paketini indirir, `/opt/apinizer-worker`'a açar.
- `conf/apinizer-worker.env` içinde MongoDB bağlantısını, `APINIZER_ENVIRONMENT_NAME` ve `WORKER_TIMEZONE` değerlerini ayarlar.
- Installer + encrypt çalıştırır, servisi başlatır.
- Worker Management API `http://<IP>:8091` adresinde yayınlanır.

#### `install-apinizer-cache.sh`
- Cache (Hazelcast) paketini indirir, `/opt/apinizer-cache`'e açar.
- `conf/apinizer-cache.env` içinde MongoDB bağlantısını, `CACHE_QUOTA_TIMEZONE` ve (çoklu node için) `APINIZER_CACHE_CLUSTER_MEMBERS` değerlerini ayarlar.
- Installer + encrypt çalıştırır, servisi başlatır.
- Cache REST API `http://<IP>:8090` (Hazelcast `5701`) adresinde yayınlanır.

### Kurulum Sonrası

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

### Opsiyonel Modüller

API Manager, Worker ve Cache bu kurulum akışında yer alır. İhtiyaç halinde Integration (Quartz) ve API Portal modülleri de `packages.apinizer.com` üzerinden aynı yöntemle (indir → aç → env ayarla → installer → encrypt → start) kurulabilir. Adımlar için [Sanal Sunucu'ya Kurulum](https://docs.apinizer.com) belgesine bakın.

### Operasyon

| İşlem | Komut |
|-------|-------|
| Durum | `sudo systemctl status apinizer-apimanager` / `apinizer-apiworker` / `apinizer-apicache` |
| Yeniden başlat | `sudo systemctl restart apinizer-apimanager` |
| Durdur | `sudo systemctl stop apinizer-apimanager` |
| Günlükler | `sudo journalctl -u apinizer-apimanager -f` |

### Notlar

- **Master key:** Her modülün `conf/master.key` dosyası kurulumda otomatik üretilir ve hassas değerlerin şifresini çözer. **Yedekleyin** — kaybedilirse `ENC(...)` değerleri kurtarılamaz.
- **Saat dilimi:** Manager, Gateway, Cache ve Integration arasında saat dilimi tutarlı olmalıdır (Gateway için `WORKER_TIMEZONE`, varsayılan `+03:00`).
- **JVM heap:** Paketler varsayılan olarak `-XX:MaxRAMPercentage=75.0` kullanır; hedef donanımda yük testinden sonra ayarlayın.
- **Şifreler:** Varsayılan `Apinizer.1` (MongoDB) ve `Apinizer.1!` (Apinizer admin). Üretimde mutlaka değiştirin.

## 2. Configuration & Usage

### Step - 1: Login to Apinizer Management Console

Default Address : **http://YOUR-IP-ADDRESS:8080** <br />
Default username : **admin** <br />
Default password : **Apinizer.1!** <br />

![alt text](https://github.com/apinizer/apinizer/blob/main/images/image-0.png)

### Step – 1.1: Add the Elasticsearch Connector
Elasticsearch 8.x is installed with security (TLS + password) enabled, so the connector must be added manually.
Go to **Administration -> Connection Management -> Elasticsearch** and add the connection using the `elastic` user, the password printed at the end of the installation (also stored in `/opt/elasticsearch/elasticsearch-passwords.txt`), and the `elastic-certificates.crt` certificate located under `/opt/elasticsearch/elasticsearch-8.17.10/config/certs/`.

### Step – 2: Create Index Lifecycle Policies and Index Templates
Go to Elasticsearch Clusters Menu (Administration -> Server Management -> Elasticsearch Clusters)
Click **red cards** for Create Index Lifecycle Policies and Index Templates.

![alt text](https://github.com/apinizer/apinizer/blob/main/images/image-1.png)

After clicking to **red cards**, you should see them as below.

![alt text](https://github.com/apinizer/apinizer/blob/main/images/image-2.png)

### Step – 3: Define the Gateway as a Remote Environment and Publish.
The Gateway (Worker) is installed as a standalone VM package by the script. In the Manager UI, register it as a Remote Gateway environment:
Go to Gateway Runtimes (Administration -> Server Management -> Gateway Runtimes) and click **New**.
- Platform: **Virtual Server**, Management Type: **Remote Gateway**
- **Environment Name** must equal the Gateway's `APINIZER_ENVIRONMENT_NAME` (default `prod`)
- Gateway Management API URL: `http://YOUR-IP-ADDRESS:8091`

Then **Publish** the environment.

![alt text](https://github.com/apinizer/apinizer/blob/main/images/image-3.png)

After publishing, you should see them as below after about 2 minutes.

![alt text](https://github.com/apinizer/apinizer/blob/main/images/image-4.png)

### Step – 4: Create first API Proxy and Publish
Select default project on topbar.<br />

Select the default project from the window that comes up.<br />

![alt text](https://github.com/apinizer/apinizer/blob/main/images/image-5.png)

**You will see that left menu changes.**<br />

![alt text](https://github.com/apinizer/apinizer/blob/main/images/image-6.png)

**Note:** Quick Menu and Main Menu are prepared according to the roles and privileges of the active user.<br/>
Two different menus can be displayed in the Main Menu area:
<ul>
<li>If the active user has selected a Project, i.e. if the project name appears on the far left in the Quick Menu, ("demo" appears in this image), the Developer Menu is displayed. Jobs related to the items in this menu are described in the Developer's Guide.</li>
<li>If the active user has the Administrator role and selects any item from the Quick Menu (for example, clicks on Overview), the Admin Menu is displayed. Jobs related to the items in this menu are described in the Administrator's Guide.</li>
</ul>
When an item is selected from any menu, the Work Area is updated according to the selected item.
![alt text](https://github.com/apinizer/apinizer/blob/main/images/image-7.png)

**Go to API Proxies (Development -> API Proxies)** <br />
![alt text](https://github.com/apinizer/apinizer/blob/main/images/image-8.png)

### Creating an API Proxy
Click the **+Proxy** button at right top side of the interface. <br />
![alt text](https://github.com/apinizer/apinizer/blob/main/images/image-9.png)

Click the **Enter URL** link for Swagger 2.x from the options in the New API Proxy creation interface. <br />
![alt text](https://github.com/apinizer/apinizer/blob/main/images/image-10.png)

Enter [https://petstore.swagger.io/v2/swagger.json](https://petstore.swagger.io/v2/swagger.json) into the textbox labeled URL, and click the **Parse** button. <br />
![alt text](https://github.com/apinizer/apinizer/blob/main/images/image-11.png)

Apinizer parses the Swagger file at the address given, and display the details of the API. <br/>

Check [https://petstore.swagger.io/v2](https://petstore.swagger.io/v2) in the Addresses part, and enter **/petstoreProxy** into the Relative Path textbox before clicking the **Save** button at the right top. <br />

![alt text](https://github.com/apinizer/apinizer/blob/main/images/image-12.png)

That is all to create an API Proxy. 

### Deploying the API Proxy
When the API Proxy is created, several tabs appear on the interface. With the configurations to be made from these tabs, the behavior of API Proxy is customized. API Proxy must be installed to be accessible.
Open the **Develop** tab. <br />
![alt text](https://github.com/apinizer/apinizer/blob/main/images/image-13.png)

The Develop tab shows API Proxy's endpoints on the left, and policies and flow in the middle. Various links or buttons open interfaces related to configurations.
Click the **Deploy** button at the middle top. You will see active environment options (1 Prod in demo environment), choose the appropriate one. An deployment description entry window appears, but it is not mandatory to fill in. Continue by pressing the **Deploy** button. <br />
![alt text](https://github.com/apinizer/apinizer/blob/main/images/image-14.png)

**API Proxy is deployed and ready to access.**

### Accessing the API Proxy
When the API Proxy is deployed, the access address appears on the interface. API Proxy is now an API for clients (API Consumers) who want to access it and is available at this address. <br />
![alt text](https://github.com/apinizer/apinizer/blob/main/images/image-15.png)

There are many ways to send a request to an API. In this example, the interface provided by the platform will be used for simplicity.

On the left, select the endpoint/method you want to access. New links appear in the lower middle and the access address is updated to point to the address of the selected endpoint. Click the Test Endpoint link. <br />
![alt text](https://github.com/apinizer/apinizer/blob/main/images/image-16.png)

In the popup window that opens, there are tabs where the endpoint's header, body, validation rules or advanced settings can be managed, including which HTTP Method the endpoint expects, the access address, and the parameters tab under them by default.
Enter **pending** for the **status** parameter. You can see that the URL changes while you type. Click the **Send** button.  <br />

Tabs appear with the endpoint's response, headers, validation results if any validation rule defined, and detailed log records. <br />

**Congratulations 😊. You have created an API Proxy and accessed it.**

# Uninstallation
#### Run the following script on the server to uninstall Apinizer completely.
```
sudo curl -s https://raw.githubusercontent.com/apinizer/apinizer/main/uninstallApinizer.sh | bash
```
