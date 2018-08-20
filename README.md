# Notification System for Terminal #

Collects messages by applications using this system and dispatches them in
terminal.

For gui support also install package msgcollector-gui.

Package: msgcollector-gui
Architecture: all
Depends: msgcollector, wmctrl, python3-pyqt5, zenity,
libnotify-bin | kde-baseapps-bin, mate-notification-daemon, x11-utils,
libgnome2-bin, ${misc:Depends}
Provides: ${diverted-files}
Conflicts: ${diverted-files}
Description: Notification System for X
# Notification System for X #

Collects messages by applications using this system and dispatches them in X.

A metapackage that installs required dependencies for X support.
## How to install `msgcollector` using apt-get ##

1\. Add [Whonix's Signing Key](https://www.whonix.org/wiki/Whonix_Signing_Key).

```
sudo apt-key --keyring /etc/apt/trusted.gpg.d/whonix.gpg adv --keyserver hkp://ipv4.pool.sks-keyservers.net:80 --recv-keys 916B8D99C38EAF5E8ADC7A2A8D66066A2EEACCDA
```

3\. Add Whonix's APT repository.

```
echo "deb http://deb.whonix.org stretch main" | sudo tee /etc/apt/sources.list.d/whonix.list
```

4\. Update your package lists.

```
sudo apt-get update
```

5\. Install `msgcollector`.

```
sudo apt-get install msgcollector
```

## How to Build deb Package ##

Replace `apparmor-profile-torbrowser` with the actual name of this package with `msgcollector` and see [instructions](https://www.whonix.org/wiki/Dev/Build_Documentation/apparmor-profile-torbrowser).

## Contact ##

* [Free Forum Support](https://forums.whonix.org)
* [Professional Support](https://www.whonix.org/wiki/Professional_Support)

## Payments ##

`msgcollector` requires [payments](https://www.whonix.org/wiki/Payments) to stay alive!
