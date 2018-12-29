# Docker Concepts (96d)

## Introduction
Docker and the DevOps tools surrounding it have fostered a revolution in the way services are delivered over the internet. In this book, we're piggybacking on a small piece of that revolution, Docker on the desktop.

## Virtual machines and hypervisors
Linux is primarily a server hosting operating system. While many people run Linux on desktops and laptops, that isn't a large majority of either Linux installations or of desktops / laptops.

A _virtual machine_ is a machine that is running purely as software hosted by another real machine. To the outside user, a virtual machine looks just like a real one. But it has no processors, memory or I/O devices - all of those are supplied and managed by the host.

A virtual machine can run any operating system that will run on the host's hardware. A Linux host can run a Windows virtual machine and vice versa.

A _hypervisor_ is the component of the host system software that manages virtual machines, usually called _guests_. Linux systems have a native hypervisor called _Kernel Virtual Machine (kvm)_. And laptop, desktop and server processors from Intel and Advanced Micro Devices (AMD) have hardware that makes this hypervisor more efficient.

Windows servers and Windows 10 Pro have a hypervisor called _Hyper-V_. Like kvm, it can take advantage of the hardware in Intel and AMD processors. On Macintosh, there is a _Hypervisor Framework_ (<https://developer.apple.com/documentation/hypervisor>) and other tools build on that.

## Containers
A _container_ is a set of processes running in an operating system. The host operating system is usually Linux, but other operating systems also can host containers.

Unlike a virtual machine, the container has no operating system of its own. If the host is running Linux, so is the container.

A container *does* have its own filesystem. From inside the container, this filesystem looks like a Linux filesystem, but it can use any Linux distro. For example, you can have an Ubuntu 18.04 LTS host running Ubuntu 14.04 LTS or Fedora 28 or CentOS 7 containers.
