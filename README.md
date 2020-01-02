# Robotica

Robotica is a system written in Elixir designed to manage IOT devices using a an
automatic schedule.

## Contents

* config: configuration files.
* LICENSE README.html README.md: documentation.
* robotica_plugins: common shared code.
* robotica base library for scheduling and interacting with devices.
* robotica_face: Web based interface.
* robotica_hello: Authentication for web based interface.
* robotica_nerves: Deployment for RPI3.
* robotica_ui: Scenic based User Interface.

## Quick start

Requirements:

* Need to have authenticated MQTT server using TLS and username and password.
* Copy CA certificate in ``./robotica_nerves/cafile.pem`` and ``robotica_nerves/rootfs_overlay/etc/cafile.pem```.

Follow the following steps:

1. Install ASDF. Follow [instructions](https://asdf-vm.com/#/core-manage-asdf-vm). Install plugins:

    ```
    asdf plugin-add elixir
    asdf plugin-add nodejs
    asdf install elixir 1.9.1-otp-22
    asdf install nodejs 11.10.1
    ```

2. Install source code:

    ```
    git clone https://github.com/brianmay/robotica-elixir.git
    cd robotica-elixir
    ```

3. Setup ASDF:

    ```
    asdf local elixir 1.9.1-otp-22
    asdf local nodejs 11.10.1
    ```

4. Setup required environment variables:

    ```
    export SUDO_ASKPASS=/usr/lib/ssh/x11-ssh-askpass
    export NERVES_NETWORK_SSID=...
    export NERVES_NETWORK_PSK=...
    export NERVES_NETWORK_MGMT="WPA-PSK"
    export MIX_TARGET="rpi3"
    export SECRET_KEY_BASE="$(mix phx.gen.secret)"
    export LOGIN_SECRET="$(mix guardian.gen.secret)"
    export SIGNING_SALT="$(mix phx.gen.secret 32)"
    export GOOGLE_USERNAME=""
    export GOOGLE_PASSWORD=""
    ```

5. Setup required config files. Look at config directory. Copy files ending with
   `.sample` to `.yaml` extensions and edit as required.

6. Build JavaScript stuff:

    ```
    cd robotica_hello
    mix deps.get
    npm install
    cd ../..
    ```

7. Configure nerves:

    ```
    cd robotica_nerves
    mkdir -p rootfs_overlay/etc/robotica/
    vim rootfs_overlay/etc/robotica/config-nerves-$cpuid.yaml  # based on config/config.yaml
    vim rootfs_overlay/etc/robotica/ui-nerves-$cpuid.yaml      # based on config/ui.yaml
    ```

8. Build nerves stuff:

    ```
    mix deps.get
    MIX_TARGET=rpi3 MIX_ENV=prod mix firmware
    ```

9. Write image to flash USB device:

    ```
    MIX_TARGET=rpi3 MIX_ENV=prod mix firmware.burn
    ```

10. Insert flash into RPI3, and boot.
