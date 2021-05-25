# FreeBSD Port for code-server https://github.com/cdr/code-server

## Run VS Code on any machine anywhere and access it in the browser

</br>

> Submitted to be added to the FreeBSD Ports Tree on 5/25/2021: https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=256144

## **editors/code-server**

</br>

### **Install**

**Using packages:**

```sh
pkg install code-server
```

**Or using ports:**

```sh
cd /usr/ports/editors/code-server
make install clean
```

### **Run**

```sh
/usr/local/bin/code-serve
```

Or run as a service via the rc.d script that gets installed:

```sh
service code_server enable  # Enable at start up
service code_server start   # Start service
service code_server stop    # Stop service
service code_server restart # Restart service
service code_server status  # Status of service
```

NOTE:
 The file permissions one has when using vscode from a web browser is dependant
on the user/group you choose to run this service. It defaults to `nobody` for
security reasons but you will probably want to specify a different user with
the appropriate permissions for your use case in `/etc/rc.conf` like:

```sh
code_server_user="myuser"  # default is "nobody"
code_server_group="myuser" # default is "nobody"
```

Other available variables to use in in `/etc/rc.conf` when using as a service:

- **code_server_config_file** *(filepath)*: Set to /var/code-server/nobody/config.yaml by default. Set to the full filepath of the config file.
- **code_server_user_data_dir** *(path)*: Set to /var/code-server/nobody/user-data by default. Set to the directory path to use for user data.
- **code_server_extensions_dir** *(path)*: Set to /var/code-server/nobody/extensions by default. Set to the directory path to use for extensions.
- **code_server_service_url** *(url)*: Set to https://open-vsx.org/vscode/gallery by default. Set to the service url of an extensions marketplace.
- **code_server_item_url** *(url)*: Set to https://open-vsx.org/vscode/item by default. Set to the item url of an extensions marketplace.

### **Access vscode from browser**

`http://localhost:8080`

IP address, port, and more can be set in `config.yaml`

See `cdr/code-server` repo for docs: https://github.com/cdr/code-server
