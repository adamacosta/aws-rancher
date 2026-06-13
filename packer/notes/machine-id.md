# `machine-id`

The guide for [Building Images Safely](https://systemd.io/BUILDING_IMAGES/) provided by `systemd` indicates some standard cleanup that should be done on a machine image before distributing, such that deployed systemd end up unique. One of these is removing the `machine-id` in `/etc/machine-id`. However, when attempting to do at first, EC2 instances booted without a `machine-id` never became reachable over the network. To figure out why, I enabled the serial console and found that it was prompting interactively for a keymap.

The following prompt is shown:

```console
> Please enter the new keymap name or number (empty to skip, "list" to list options):
```

This is part of `systemd-firstboot.service`, which has the following unit definition:

```console
rancher@ip-10-100-86-229:~> systemctl --no-pager cat systemd-firstboot.service
# /usr/lib/systemd/system/systemd-firstboot.service
#  SPDX-License-Identifier: LGPL-2.1-or-later
#
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.

[Unit]
Description=First Boot Wizard
Documentation=man:systemd-firstboot(1)

ConditionPathIsReadWrite=/etc
ConditionFirstBoot=yes

DefaultDependencies=no
# This service may need to write to the file system:
After=systemd-remount-fs.service
# Both systemd-sysusers and systemd-tmpfiles may create the root account
# (via factory files or credentials), obviating the need for us to do that:
After=systemd-sysusers.service systemd-tmpfiles-setup.service
# Let vconsole-setup do its setup before starting user interaction:
After=systemd-vconsole-setup.service

Wants=first-boot-complete.target
Before=first-boot-complete.target sysinit.target
Conflicts=shutdown.target
Before=shutdown.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=systemd-firstboot --prompt-locale --prompt-keymap --prompt-timezone --prompt-root-password
StandardOutput=tty
StandardInput=tty
StandardError=tty

# Optionally, pick up basic fields from credentials passed to the service
# manager. This is useful for importing this data from nspawn's
# --set-credential= switch.
ImportCredential=passwd.hashed-password.root
ImportCredential=passwd.plaintext-password.root
ImportCredential=passwd.shell.root
ImportCredential=firstboot.*
```

The man page says the following:

```
DESCRIPTION
       The systemd-firstboot.service unit is one of the units which are used to initialize the machine configuration during "First
       Boot", i.e. when the system is freshly installed or after a factory reset. The systemd(1) manager itself will initialize
       machine-id(5) and preset all units, enabling or disabling them according to the systemd.preset(5) settings.
       systemd-firstboot.service is started later to interactively initialize basic system configuration. It is started only if
       ConditionFirstBoot=yes is met, which essentially means that /etc/ is unpopulated, see systemd.unit(5) for details. System
       credentials may be used to inject configuration; those settings are not queried interactively.

       The systemd-firstboot command can also be used to non-interactively initialize an offline system image.

       The following settings may be configured:

       •   The machine ID of the system

       •   The system locale, more specifically the two locale variables LANG= and LC_MESSAGES

       •   The system keyboard map

       •   The system time zone

       •   The system hostname

       •   The kernel command line used when installing kernel images

       •   The root user's password and shell

       Each of the fields may either be queried interactively by users, set non-interactively on the tool's command line, or be copied
       from a host system that is used to set up the system image.

       If a setting is already initialized, it will not be overwritten and the user will not be prompted for the setting.

       Note that this tool operates directly on the file system and does not involve any running system services, unlike localectl(1),
       timedatectl(1) or hostnamectl(1). This allows systemd-firstboot to operate on mounted but not booted disk images and in early
       boot. It is not recommended to use systemd-firstboot on the running system after it has been set up.
```

The problem seems to be that everything else is already set, so not prompted for. The root password has a `*` entry in the `/etc/shadow` file, indicating root login is disabled. `/etc/locale.conf` has the setting `LANG=en_US.UTF-8` and `/etc/localtime` is a symlink to UTC. However, `localectl` indicates no keymaps are set:

```console
ip-10-100-86-229:~ # localectl status
System Locale: LANG=en_US.UTF-8
    VC Keymap: (unset)
   X11 Layout: (unset)
```

This makes sense as, generally speaking, no keyboard will ever send input directly to an EC2 instance. X11 is not installed because it is a headless system, and the virtual console will usually be inaccessible. When logged in over ssh or EC2 serial console via a web browser, your local terminal's keymap is used. Running `localectl set-keymap us`, then `echo uninitialized > /etc/machine-id`, then rebooting again, did bypass the `systemd-firstboot` prompt, so it appears this is all that is necessary to get a clean image that will nonetheless boot fully-unattended.

Note that the EC2 still ends up getting the same `machine-id` even though it was wiped, indicating this is set in some deterministic manner. Looking at the man page for `machine-id` shows some possibilities:

```
INITIALIZATION
       Each machine should have a non-empty ID in normal operation. The ID of each machine should be unique. To achieve those
       objectives, /etc/machine-id can be initialized in a few different ways.

       For normal operating system installations, where a custom image is created for a specific machine, /etc/machine-id should be
       populated during installation.

       systemd-machine-id-setup(1) may be used by installer tools to initialize the machine ID at install time, but /etc/machine-id
       may also be written using any other means.

       For operating system images which are created once and used on multiple machines, for example for containers or in the cloud,
       /etc/machine-id should be either missing or an empty file in the generic file system image (the difference between the two
       options is described under "First Boot Semantics" below). An ID will be generated during boot and saved to this file if
       possible. Having an empty file in place is recommended because it allows a temporary file to be bind-mounted over the real
       file, in case the image is used read-only and when /etc is mounted read-only in the early boot. Also see Safely Building
       Images[1].

       systemd-firstboot(1) may be used to initialize /etc/machine-id on mounted (but not booted) system images.

       When a machine is booted with systemd(1) the ID of the machine will be established. If systemd.machine_id= or --machine-id=
       options (see first section) are specified, this value will be used. Otherwise, the value in /etc/machine-id will be used. If
       this file is empty or missing, systemd will attempt to use the D-Bus machine ID from /var/lib/dbus/machine-id, the value of the
       kernel command line option container_uuid, the KVM DMI product_uuid or the devicetree vm,uuid (on KVM systems), the Xen
       hypervisor uuid, and finally a randomly generated UUID.  systemd.machine_id=firmware can be set to generate the machine ID from
       the firmware.

       After the machine ID is established, systemd(1) will attempt to save it to /etc/machine-id. If this fails, it will attempt to
       bind-mount a temporary file over /etc/machine-id. It is an error if the file system is read-only and does not contain a
       (possibly empty) /etc/machine-id file.

       systemd-machine-id-commit.service(8) will attempt to write the machine ID to the file system if /etc/machine-id or /etc/ are
       read-only during early boot but become writable later on.
```

In fact, it does turn out that the hypervisor UUID is used:

```console
ip-10-100-86-229:~ # cat /etc/machine-id
ec2641aea4a2bb062a8edcbd0a3e3a39
ip-10-100-86-229:~ # dmidecode -s system-uuid | tr -d '-'
ec2641aea4a2bb062a8edcbd0a3e3a39
```