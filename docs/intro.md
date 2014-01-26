### What is LXC

LXC is a container implementation on mainline linux. Containers are widely popular way of sharing and consolidating resources. From an usability standpoint, they can be uses like a virtual machine(vm) or virtual private server(vps), but they offer far more operational efficiency. Also, they can be used in much wider use cases than traditional virtualization. In this piece I'll be giving some background of container, current LXC status and finally some comparison with other virtualization technologies. Hopefully, this will provide a good enough background before we delve into details and explore LXC programmaticaly.


#### What are containers?

Containers, as their name suggest *contain* other entities inside them. In this case, they are operating system virtualization. i.e. cotainers provide virtual machine like entities (or vps) without using only software (OS). Containers are significantly different than full virtualization(like kvm, virtualbox) or para virtualization (like xen). In case of full or paravirtualization the host operating system can not see (or not aware) anything inside the guest virtual machines. This is because the hypervisor (the layer the provides full or paravirtualization capabilities) provides an opaque isolation. This also leads to indirection. What it means is, when you write inside a virtual machine using full or para virtualization, you write on virtual file system(in the guest vm) which then converted to the host file system by the hypervisor. This indirection has a two main consequences. On the positive side, this allows the guest virtual machine to use any architecture or file system(i.e a vm can run ext3 file system, while the host can run zfs). On the negative side this introduces a performance cost due to the indirection involve. 

Containers, on the other hand does not involve any indirection. They provide an interface to isolate and divide host operating system resources into smaller chunks, whithout any hypervisor layer. This reduces the performance cost drastically, but introduces certain limitation on what can be simulated on the vm (i.e. you cant have different kernel on host and containers, etc).


#### Some history

Virtualization has been popular for long time (specially on AIX), since early 80s. Container gained popularity with Virtuzzo (2001), then  Solaris Zones (since 2005). IBM offers container in the form of WPARs (since 2007). On linux container first appear with OpenVZ, which involved a patched kernel.

As far as i can understand, the OpenVZ folks tried a lot to get their patched merged in mainline linux, which didnt worked out. Later some of the building blocks to make container a reality (namespaces, cgroups etc) were introduced as distinct features. These building block allow isolation, resource accounting, fine grained access controls etc. Again, most of these work were done by the OpenVZ folks. It tool almost a decade to get these patches merged on linux mainline, after which LXC aka linux containers were implemented as an userland tool.

I think its important to remember LXC's background, as this will help us understand, compare and evaluate LXC better.

