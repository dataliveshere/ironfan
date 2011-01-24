#
# Author:: Philip (flip) Kromer (<flip@infochimps.com>)
# Copyright:: Copyright (c) 2011 Infochimps, Inc
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'socket'
require 'chef/knife'
require 'json'

class Chef
  class Knife
    class ClusterLaunch < Knife

      banner "knife cluster launch CLUSTER_NAME FACET_NAME (options)"

      attr_accessor :initial_sleep_delay

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password"

      option :prerelease,
        :long => "--prerelease",
        :description => "Install the pre-release chef gems"

      def h
        @highline ||= HighLine.new
      end

      def tcp_test_ssh(hostname)
        tcp_socket = TCPSocket.new(hostname, 22)
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
          yield
          true
        else
          false
        end
      rescue Errno::ETIMEDOUT
        false
      rescue Errno::ECONNREFUSED
        sleep 2
        false
      ensure
        tcp_socket && tcp_socket.close
      end

      def run
        require 'fog'
        require 'highline'
        require 'net/ssh/multi'
        require 'readline'

        # Fog.mock!
        # Fog::Mock.delay = 0

        $stdout.sync = true

        $: << File.expand_path('~/ics/sysadmin/cluster_chef/clusters')
        require 'hadoop_demo'

        cluster_name, facet_name = @name_args
        cluster = Chef::Config[:clusters][cluster_name]
        facet   = cluster.facet(facet_name)
        facet.resolve!
        facet.cloud.security_groups.each{|name,group| group.run }
        puts facet.to_hash_with_cloud.to_yaml

        # servers = facet.list_servers
        # server  = servers.last
        server = facet.create_servers
        
        puts "#{h.color("Instance ID      ", :cyan)}: #{server.id}"
        puts "#{h.color("Flavor           ", :cyan)}: #{server.flavor_id}"
        puts "#{h.color("Image            ", :cyan)}: #{server.image_id}"
        puts "#{h.color("Availability Zone", :cyan)}: #{server.availability_zone}"
        puts "#{h.color("Security Groups  ", :cyan)}: #{server.groups.join(", ")}"
        puts "#{h.color("SSH Key          ", :cyan)}: #{server.key_name}"
        puts "#{h.color("User Data        ", :cyan)}: #{server.user_data}"
        
        print "\n#{h.color("Waiting for server", :magenta)}"
        
        # wait for it to be ready to do stuff
        server.wait_for { print "."; ready? }
        
        puts("\n")
        
        puts "#{h.color("Public DNS Name    ", :cyan)}: #{server.dns_name}"
        puts "#{h.color("Public IP Address  ", :cyan)}: #{server.ip_address}"
        puts "#{h.color("Private DNS Name   ", :cyan)}: #{server.private_dns_name}"
        puts "#{h.color("Private IP Address ", :cyan)}: #{server.private_ip_address}"
        
        # puts "#{h.color("Server ", :cyan)}: #{JSON.pretty_generate(JSON.load(server.to_json))}"
        # puts "#{h.color("All Servers ", :cyan)}: #{JSON.pretty_generate(JSON.load(facet.list_servers.to_json))}"
        
        print "\n#{h.color("Waiting for sshd", :magenta)}"
        
        print(".") until tcp_test_ssh(server.dns_name) { sleep @initial_sleep_delay ||= 10; puts("done") }
        
        config[:ssh_user]       = facet.cloud.ssh_user                
        config[:identity_file]  = facet.cloud.ssh_identity_file
        config[:chef_node_name] = facet.chef_node_name
        config[:distro]         = facet.cloud.bootstrap_distro
        config[:run_list]       = facet.run_list
        # config[:template_file]  = facet.cloud.template_file

        bootstrap_for_node(server).run

        puts "\n"
        puts "#{h.color("Instance ID        ", :cyan)}: #{server.id}"
        puts "#{h.color("Flavor             ", :cyan)}: #{server.flavor_id}"
        puts "#{h.color("Image              ", :cyan)}: #{server.image_id}"
        puts "#{h.color("Availability Zone  ", :cyan)}: #{server.availability_zone}"
        puts "#{h.color("Security Groups    ", :cyan)}: #{server.groups.join(", ")}"
        puts "#{h.color("SSH Key            ", :cyan)}: #{server.key_name}"
        puts "#{h.color("Public DNS Name    ", :cyan)}: #{server.dns_name}"
        puts "#{h.color("Public IP Address  ", :cyan)}: #{server.ip_address}"
        puts "#{h.color("Private DNS Name   ", :cyan)}: #{server.private_dns_name}"
        puts "#{h.color("Private IP Address ", :cyan)}: #{server.private_ip_address}"
        puts "#{h.color("Run List           ", :cyan)}: #{@name_args.join(', ')}"
      end

      def bootstrap_for_node(server)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args               = [server.dns_name]
        bootstrap.config[:run_list]       = config[:run_list]
        bootstrap.config[:ssh_user]       = config[:ssh_user]
        bootstrap.config[:identity_file]  = config[:identity_file]
        bootstrap.config[:chef_node_name] = config[:chef_node_name] || server.id
        bootstrap.config[:prerelease]     = config[:prerelease]
        bootstrap.config[:distro]         = config[:distro]
        bootstrap.config[:use_sudo]       = true
        bootstrap.config[:template_file]  = config[:template_file]                  
        bootstrap
      end

    end
  end
end
