default[:nfs][:exports] = Mash.new

default[:nfs][:mounts] = [
  ['/home', { :owner => 'root', :remote_path => "/home" } ],
]

defaults[:firewall][:port_scan][:portmap] = { :port =>   111, :window => 20, :max_conns => 15, },
defaults[:firewall][:port_scan][:nfsd]    = { :port =>  2049, :window => 20, :max_conns => 15, },
defaults[:firewall][:port_scan][:mountd]  = { :port => 45560, :window => 20, :max_conns => 15, },
defaults[:firewall][:port_scan][:statd]   = { :port => 56785, :window => 20, :max_conns => 15, },