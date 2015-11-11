require 'xmlrpc/client'
require 'fileutils'

Puppet::Type.type(:cobbler_distro).provide(:ruby) do
  desc "Provides cobbler distro via cobbler_api"

  # Supports redhat only
  confine    :osfamily => :redhat
  defaultfor :osfamily => :redhat
  commands   :cobbler  => 'cobbler'

  mk_resource_methods
  # generates the following methods via Ruby metaprogramming
  # def version
  #   @property_hash[:version] || :absent
  # end

  # Resources discovery
  def self.instances
    distros = []
    cserver = XMLRPC::Client.new2('http://127.0.0.1/cobbler_api')
    xmlresult = cserver.call('get_distros')

    # get properties of current system to @property_hash
    xmlresult.each do |distro|
      distros << new(
        :name    => distro['name'],
        :ensure  => :present,
        :arch    => distro['arch'],
        :kernel  => distro['kernel'],
        :initrd  => distro['initrd'],
        :comment => distro['comment'],
        :owners  => distro['owners']
      )
    end
    distros
  end

  def self.prefetch(resources)
    instances.each do |distro|
      if resource = resources[distro.name]
        resource.provider = distro
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    # Import if not exists
    if @property_hash[:ensure] != :present
      self.import
    end
    # set properties as they are not set by defaut
    properties = [
      :kernel,
      :initrd,
      :arch,
      :comment,
      :owners
    ]
    for property in properties
      unless self.send(property) == @resource.should(property) or @resource[property].nil?
        self.send("#{property}=", @resource.should(property))
      end
    end

    cobbler("sync")
    @property_hash[:ensure] = :present
  end


  def destroy
    # remove cobbler distribution
    Puppet.warning("All child objects of #{@resource[:name]} distribution are deleted")
    
    cobbler(
      [
        "distro", 
        "remove",
        "--recursive",
        "--name=#{@resource[:name]}"
      ]
    )
    @property_hash.clear
  end

  def import
    # import cobbler distribution
    cobbler(
      [
        "import", 
        "--name=#{@resource[:name]}",
        "--arch=#{@resource[:arch]}",
        "--path=#{@resource[:path]}" 
      ]
    )
  end

  def set_field(what, value)
    if value.is_a? Array
      value = value.join(' ')
    end

    cobbler(
      [
        "distro",
        "edit",
        "--name=" + @resource[:name],
        "--#{what.tr('_','-')}=" + value
      ]
    )
    @property_hash[what] = value
  end

  #Setters
  def kernel=(value)
    raise ArgumentError, '%s: not exists' % value unless File.exists? value
    self.set_field(:kernel, value)
  end

  def initrd=(value)
    raise ArgumentError, '%s: not exists' % value unless File.exists? value
    self.set_field(:initrd, value)
  end

  def comment=(value)
    self.set_field(:comment, value)
  end

  def owners=(value)
    self.set_field(:owners, value)
  end

  def arch=(value)
    self.set_field(:arch, value)
  end
end