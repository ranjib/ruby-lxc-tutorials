### Setting up  LXC

#### The Base VM
As mentioned in the beginning, lxc 1.0 stable is not released yet. Its actively tested on ubuntu 12.04 and 14.04. It is possible to build lxc on almost any linux (kernel 2.6+) system, but to make our life simpler, we'll use ubuntu 14.04. You can setup a VM using KVM or VirtualBox or something similar. I'll recommend giving liberal amount of CPU and RAM to this vm, alse setup bridge networking if possible. Ubuntu 14.04 can iso can be found [here](http://cdimage.ubuntu.com/ubuntu-server/daily/current/).

Post installation, create a user, give admin privileges to that user. You can also setup sudoers file with `NOPASSWD:` flag, if you want.

#### Installing LXC
LXC 1.0 beta is already available on main ubuntu repo. You can install it using `apt-get`
```sh
sudo apt-get install -y liblxc0 lxc lxc-templates python3-lxc
```
`liblxc0` provides the shared library, while package `lxc` provides all the `lxc-*` binaries (e.g. lxc-start, lxc-stop), stock configs, etc. `lxc-templates` provide templates to create containers for different linux distributions (like ubuntu, centos, fedora etc). `python3-lxc` provides the python binding for lxc (lxc-ls is written using the python binding). All these packages are maintained by the core lxc group.

#### Installing ruby
If you are reading this, probably you already know this. But still, this is what I use.
- Install dependencies
  ```sh
  sudo apt-get -y install build-essential git ncurses-term zlib1g-dev python3-software-properties
  ```

- Install [ruby-build](https://github.com/sstephenson/ruby-build#installing-as-a-standalone-program-advanced)
  ```sh
  git clone https://github.com/sstephenson/ruby-build.git
  ```

- Install ruby 2.1 using ruby build
  ```sh
  ./ruby_build/bin/ruby-build 2.1.0 /opt/ruby
  ```

- Update rubygems
  ```sh
  /opt/ruby/bin/gem update --system
  ```

- Install bundler
  ```sh
  /opt/ruby/bin/gem install bundler
  ```

#### Installing ruby-lxc binding

- Get the ruby-lxc [source](https://github.com/lxc/ruby-lxc)
  ```sh
  git clone https://github.com/lxc/ruby-lxc.git
  ```

- Build the gem
  ```sh
  /opt/ruby/bin/bundle install --path
  /opt/ruby/bin/bundle rake package
  ```

  this should create the ruby-lxc gem package in the `/pkg` directory.
 
- Install the ruby-lxc gem
  ```sh
  /opt/ruby/bin/gem install pkg/ruby-lxc*.gem
  ```

Thats it. Now we are all setup to explore lxc.
