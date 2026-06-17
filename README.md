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

# Installation
### Minimum Requirements (single-server PoC / Test)
- 8 Core CPU
- 16 GB Ram
- 200 GB Disk

This all-in-one script installs MongoDB 8.0, Elasticsearch 8.17 and the Apinizer modules (API Manager + Gateway) as standalone Virtual Server (Linux VM) packages with embedded OpenJDK 25 — no Kubernetes/containers required. It is intended for PoC/Test environments only; for production topologies see https://docs.apinizer.com.

#### Run the following script on Ubuntu 24.04 LTS version to install Apinizer.
```
sudo curl -s https://raw.githubusercontent.com/apinizer/apinizer/main/installApinizer.sh | bash
```

#### Component-based installation
To install each component (MongoDB, Elasticsearch, API Manager, Gateway) separately — for example on dedicated servers — use the per-component scripts under the [`install/`](install/README.md) directory. See [`install/README.md`](install/README.md) for detailed, step-by-step instructions.

## Configuration
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
