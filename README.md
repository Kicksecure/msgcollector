# Command Line Interface Messages Toolkit Library #

A programming library providing an application programming interface (API)
that allows the programmer to output colored text in terminal user interfaces
(CLI).

Applications can send messages to msgcollector which it collects and
dispatches once instructed to do so by the application.

For clarity and avoidance of confusion, msgcollector does not collect any
data. Applications that do not use msgcollector do not interact with
msgcollector. It is roughly in the same category as ncurses but has of course
much less and very different features.

For graphical user interface (GUI) support also install package
msgcollector-gui.

## How to install `msgcollector` using apt-get ##

1\. Download the APT Signing Key.

```
wget https://www.kicksecure.com/keys/derivative.asc
```

Users can [check the Signing Key](https://www.kicksecure.com/wiki/Signing_Key) for better security.

2\. Add the APT Signing Key.

```
sudo cp ~/derivative.asc /usr/share/keyrings/derivative.asc
```

3\. Add the derivative repository.

```
echo "deb [signed-by=/usr/share/keyrings/derivative.asc] https://deb.kicksecure.com bookworm main contrib non-free" | sudo tee /etc/apt/sources.list.d/derivative.list
```

4\. Update your package lists.

```
sudo apt-get update
```

5\. Install `msgcollector`.

```
sudo apt-get install msgcollector
```

## How to Build deb Package from Source Code ##

Can be build using standard Debian package build tools such as:

```
dpkg-buildpackage -b
```

See instructions.

NOTE: Replace `generic-package` with the actual name of this package `msgcollector`.

* **A)** [easy](https://www.kicksecure.com/wiki/Dev/Build_Documentation/generic-package/easy), _OR_
* **B)** [including verifying software signatures](https://www.kicksecure.com/wiki/Dev/Build_Documentation/generic-package)

## Contact ##

* [Free Forum Support](https://forums.kicksecure.com)
* [Premium Support](https://www.kicksecure.com/wiki/Premium_Support)

## Donate ##

`msgcollector` requires [donations](https://www.kicksecure.com/wiki/Donate) to stay alive!
