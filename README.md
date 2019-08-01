# Notification System for Terminal #

Collects messages by applications using this system and dispatches them in
terminal.

For gui support also install package msgcollector-gui.

Package: msgcollector-gui
Architecture: all
Depends: msgcollector, wmctrl, python3-pyqt5, zenity,
libnotify-bin | kde-baseapps-bin, mate-notification-daemon, x11-utils,
${misc:Depends}
Provides: ${diverted-files}
Conflicts: ${diverted-files}
Description: Notification System for X
# Notification System for X #

Collects messages by applications using this system and dispatches them in X.

A metapackage that installs required dependencies for X support.
## How to install `msgcollector` using apt-get ##

1\. Download [Whonix's Signing Key]().

```
wget https://www.whonix.org/patrick.asc
```

Users can [check Whonix Signing Key](https://www.whonix.org/wiki/Whonix_Signing_Key) for better security.

2\. Add Whonix's signing key.

```
sudo apt-key --keyring /etc/apt/trusted.gpg.d/whonix.gpg add ~/patrick.asc
```

3\. Add Whonix's APT repository.

```
echo "deb https://deb.whonix.org buster main contrib non-free" | sudo tee /etc/apt/sources.list.d/whonix.list
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

## Donate ##

`msgcollector` requires [donations](https://www.whonix.org/wiki/Donate) to stay alive!
