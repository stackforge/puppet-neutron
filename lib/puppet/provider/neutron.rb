require 'puppet/provider/openstack'
require 'puppet/provider/openstack/auth'
require 'puppet/provider/openstack/credentials'

class Puppet::Provider::Neutron < Puppet::Provider::Openstack

  extend Puppet::Provider::Openstack::Auth

  initvars

  def self.get_network_name(id)
    network = self.request('network', 'show', [id])
    return network[:name]
  end

  def self.get_subnet_name(id)
    subnet = self.request('subnet', 'show', [id])
    return subnet[:name]
  end

  def self.parse_subnet_id(value)
    fixed_ips = JSON.parse(value.gsub(/\\"/,'"').gsub('\'','"'))
    subnet_ids = []
    fixed_ips.each do |fixed_ip|
      subnet_ids << fixed_ip['subnet_id']
    end

    if subnet_ids.length > 1
      subnet_ids
    else
      subnet_ids.first
    end
  end

  def self.parse_availability_zone_hint(value)
    hints = JSON.parse(value.gsub(/\\"/,'"').gsub('\'','"'))
    if hints.length > 1
      hints
    else
      hints.first
    end
  end
end
