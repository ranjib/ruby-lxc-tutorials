### Exploring LXC with ruby

Now that we have both lxc and the ruby bindings installed, lets start with some basic use cases. A container must be created before using. Lets create an ubuntu conatiner and start it.

  ```ruby
  ct = LXC::Container.new('pink-floyd')
  ct.create('ubuntu')
  ct.start
  ```

#### Container lifecycle

A container can go through multiple states in its lifespan. Like virtual machines, they can be created, started, stopped, destroyed etc. 

A container's state can be obtained using the `state` api method. The `defined?` method can be used to check if a container is already present (created) or not. When creating a container, we have to pass the template that will be used to create container. Standard lxc packages ships with templates for ubuntu, centos, fedora, oracle linux etc.

  ```ruby
  ct = LXC::Container.new('greatful-dead')
  p ct.defined? # returns false since the container is not created yet
  p.state
  ct.create('ubuntu')
  ct.defined? # returns true now
  ct.running? # returns false
  p ct.state  # returns stopped
  ct.start    
  p ct.state # returns true now
  ct.stop
  ct.destroy # will delete the container
  ```

Additionally containers can also be frozen, i.e. a state where the container is not active (i.e. suspended), but all its memory pages are kept in RAM. Containers that are in frozen state can be started again using(unfreeze). Following is an example of freezing and unfreezing a container.

  ```ruby
  ct = LXC::Container.new('jimi-hendrix')
  ct.create('ubuntu')
  ct.start
  ct.freeze
  p ct.state # will return :frozen
  ct.unfreeze
  ```

Frozen containers can be started much faster than a stopped container because the processes inside the container is in suspended mode, they need not to be created (which is the case for a stopped container). Frozen containers cost memory, but no CPU. They are very useful for cases where fast and ondemand containers are required (like systemd style socket activation). Lets test this, we'll use ruby's standard benchmark module to measure to time taken to start a stopped container and unfreeze a frozen container.

```ruby
require 'benchmark'
ct.stop 
p Benchmark.measure{ct.start}
ct.freeze
p Benchmark.measure{ct.unfreeze}
```
The first benchmark measures should be much higher than the second one. Note, the differenc will increase if we run more and more processes inside the container.


#### Dealing with configurations

A container has three major components:
  1. config file, which specifies all the configuration parameters for resource controls, mount logic etc.
  2. rootfs, which is treated as the root (/) file system for the container.

 the rootfs folder is also specified in the container config file. We can obtain the value of any configuration parameter of an existing container using the `config_item` method.
  ```ruby
  p ct.config_item('lxc.rootfs') # will return the directory path of the containers rootfs

  ```
`config_file_name` method will return the path of the config file used to start the container
  ```ruby
  p ct.config_file_name
  ```
We can set any configuration parament using `set_config_item` method. But this will not have an immediate effect. After setting the configuration parameter, we need to save the config file and then restart the container for the configration changes to apply.


#### Working inside a container
the `attach` method can be used to execute arbitary code inside a container. `attach` forks a new process and run it inside the container. Lets print the output of ifconfig command inside a container
  ```ruby
  ct.attach(wait: true) do
    p `ifconfig`
  end
  ```
  Note, the `wait: true` argument in attach method ensures the method is blocked untill the code inside do-end block is finished. We'll explore the attach method in greated details later.
