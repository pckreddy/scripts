require 'aws-sdk'

cred = {:access_key_id => 'DfE5QvkvDxvlbZpvKexrgp3drv-IlSzEfI6bzrYvC-k9ogQVs-yRsjN9ASA4YkPzdGwgJKvNg7nFSKO9uZ_IzA',
        :secret_access_key => 'FGhKmQWuQ-cJzJCYcUcJ0Dy81ZQ5hXtV_khjl1WwNv8KedRUodNQsIzbjvBqo5JeqYaZRbDPUwJ1C5DWyu6N8A',
        :ec2_service_path => '/awsapi/',
        :ec2_endpoint => '10.223.52.59',
        :ec2_port => 7080,
        :use_ssl => false,
        :http_read_timeout => 500,
        :http_wire_trace => true, #set this to true for debug
        :ssl_verify_peer => false,
	:http_idle_timeout => 120,
#	:http_open_timeout => 120
}

image_loc = "http://nfs1.lab.vmops.com/templates/eec2209b-9875-3c8d-92be-c001bd8a0faf.qcow2.bz2"
templ_name = "RubyPwdTempl"
templ_desc = templ_name+"-Description"
templ_frm_vm_name = templ_name+"-FromVM"
wait_time_in_sec = 60
sg_name = "Ruby-SG-3"
sg_desc = sg_name+"-Description"
keyname = "Ruby-Keypair"
keymaterial = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQCPcQE1/yryQA6M5KXoLYY5LnmppkeScdt8oFOvetyOFfXvqsGc020FrTM8iveuJfJnRngSkCfN3pxWa8kG+vs5PHE1uaxpFfu26Vsfkm2eB9PZl9EPYd0kdHiSlr8PcbkbvsBCpo/KNojkoshWKeBewLpv6Bt7RTLLF++cKK9u0w=="

AWS.config({:http_read_timeout => 120, :http_idle_timeout => 120, :http_open_timeout => 120, :max_retries => 4})
ec2 = AWS::EC2.new(cred)

#Describle Availability Zones
avail_zones =  ec2.client.describe_availability_zones()
avail_zone = avail_zones[:availability_zone_info].first

#new_image = ec2.client.register_image(options = {
#	:name => templ_name,
#	:description => templ_desc,
#	:image_location => image_loc,
#	:architecture => "QCOW2:Adv-KVM-Zone1:CentOS 5.5 (64-bit):kvm" 
#})
#sleep((wait_time_in_sec)*3)

all_images = ec2.client.describe_images({
	:executable_users => ["self"],
	:filters => [{:name => "name", :values => [templ_name]}]
})

image = all_images[:images_set].first
print "Image Name: " + image[:name] + "\n Image ID: " + image[:image_id] + "\n" 

list_image_attr = ec2.client.describe_image_attribute({
	:image_id => image[:image_id],
	:attribute => "LaunchPermission"
})

print "Image's ID: " + list_image_attr[:image_id] + "\nImage's Launch Permission User ID: " + list_image_attr[:launch_permission].first[:user_id] + "\n"

ec2.client.modify_image_attribute({
	:image_id => list_image_attr[:image_id],
	:launch_permission => {:add => [:user_id => list_image_attr[:launch_permission].first[:user_id], :group => "all"]}
})

ec2.client.reset_image_attribute({
        :image_id => image[:image_id],
        :attribute => "LaunchPermission"	
})

new_instances = ec2.client.run_instances({
	:image_id => image[:image_id],
	:instance_type => "m1.small",
	:min_count => 1,
	:max_count => 1
})

instance = new_instances[:instances_set].first
print "Instance ID: " + instance[:instance_id] + "\n"
print "Instance's State: " + instance[:instance_state][:name] + "\n"

sleep((wait_time_in_sec)*3)

desc_instances = ec2.client.describe_instances({
	:instance_ids => [instance[:instance_id]]        
})

specific_instance = desc_instances[:reservation_set].first[:instances_set].first
print "Listed Instance ID: " + specific_instance[:instance_id] + "\n Listed Instance Image ID: " + specific_instance[:image_id] + "\n Listed Instance's current state: " + specific_instance[:instance_state][:name] + "\n"

desc_instance_attr = ec2.client.describe_instance_attribute({
	:instance_id => instance[:instance_id],
	:attribute => "instanceType"
})

print "Instance ID: " + desc_instance_attr[:instance_id] + "\n Instance Type: " + desc_instance_attr[:instance_type][:value] + "\n"

allocated_address = ec2.client.allocate_address({
	:domain => "standard"
})

print "Allocated IP Address: " + allocated_address[:public_ip] + "\n Domain: " + allocated_address[:domain] + "\n"

associated_address = ec2.client.associate_address({
	:instance_id => instance[:instance_id],
	:public_ip => allocated_address[:public_ip]
})

ec2.client.describe_addresses({})

ec2.client.disassociate_address({
	:public_ip =>  allocated_address[:public_ip],
})

ec2.client.release_address({
	:public_ip =>  allocated_address[:public_ip],
})

created_keypair = ec2.client.create_key_pair({
	:key_name => keyname
})

list_keypairs = ec2.client.describe_key_pairs({
})

ec2.client.delete_key_pair({
	:key_name => keyname
})

imported_keypair = ec2.client.import_key_pair({
	:key_name => keyname,
	:public_key_material => keymaterial
})

ec2.client.delete_key_pair({
        :key_name => keyname
})

stopped_instances = ec2.client.stop_instances({
	:instance_ids => [instance[:instance_id]]
})

print "Stopped Instance's current State: " + stopped_instances[:instances_set].first[:current_state][:name] + "\n"

started_instances = ec2.client.start_instances({
        :instance_ids => [instance[:instance_id]]
})

print "Started Instance's previous State: " + started_instances[:instances_set].first[:previous_state][:name] + "\n"
print "Started Instance's current State: " + started_instances[:instances_set].first[:current_state][:name] + "\n"

ec2.client.reboot_instances({
	:instance_ids => [instance[:instance_id]]
})

sleep((wait_time_in_sec)*3)
 
stopped_instances = ec2.client.stop_instances({
        :instance_ids => [instance[:instance_id]]
})

new_image_frm_vm = ec2.client.create_image({
	:instance_id => instance[:instance_id],
	:name => templ_frm_vm_name
})

print "Image Created from VM's ID: " + new_image_frm_vm[:image_id] + "\n"

ec2.client.deregister_image({
	:image_id => new_image_frm_vm[:image_id]
})

ec2.client.start_instances({
        :instance_ids => [instance[:instance_id]]
})

created_volume = ec2.client.create_volume({
	:size => 15,
	:availability_zone => avail_zone[:zone_name],
	:volume_type => "standard"
})

created_tags = ec2.client.create_tags({
	:resources => ["volume:"+created_volume[:volume_id]],
	:tags => [{:key => "test3", :value => "result1"}, {:key => "test4", :value => "result2"}]
})

listed_tags = ec2.client.describe_tags({
	:filters => [{:name => "key", :values => ["test3"]}]
})

specific_tag_resource = listed_tags[:tag_set].first
print "Listed Tag's Resource's ID: " + specific_tag_resource[:resource_id] + "Listed Tag's Resource's Type: " + specific_tag_resource[:resource_type] + "Listed Tag's Key: " + specific_tag_resource[:key] + "Listed Tag's Value: " + specific_tag_resource[:value] + "\n"

ec2.client.delete_tags({
        :resources => ["volume:"+created_volume[:volume_id]],
        :tags => [{:key => "test3", :value => "result1"}, {:key => "test4", :value => "result2"}]
})   

listed_volumes = ec2.client.describe_volumes({
	:volume_ids => [created_volume[:volume_id]]
})

specific_volume = listed_volumes[:volume_set].first
print "Listed Volume ID: " + specific_volume[:volume_id] + "\n Listed Volume's Size: " + specific_volume[:size].to_s + "\n Listed Volume's Status: " + specific_volume[:status] + "\n Listed Volume's Availability Zone: " + specific_volume[:availability_zone] + "\n"

attached_volume = ec2.client.attach_volume({
	:volume_id => created_volume[:volume_id],
	:instance_id => instance[:instance_id],
	:device => "/dev/sdb"
})

print "Attached Volume's Status: " + attached_volume[:status] + "\n"

created_snapshot = ec2.client.create_snapshot({
	:volume_id => attached_volume[:volume_id]
})

print "Created Snapshot's ID: " + created_snapshot[:snapshot_id] + "\nCreated Snapshot's Volume's ID: " + created_snapshot[:volume_id] + "\nCreated Snapshot's Status: " + created_snapshot[:status] + "\n"

ec2.client.describe_snapshots({
	:snapshot_ids => [created_snapshot[:snapshot_id]]
})

ec2.client.delete_snapshot({
	:snapshot_id => created_snapshot[:snapshot_id]
})

detached_volume = ec2.client.detach_volume({
	:volume_id => attached_volume[:volume_id]
})

print "Detached Volume's Status: " + detached_volume[:status] + "\n"

ec2.client.delete_volume({
	:volume_id => detached_volume[:volume_id]
})

created_sg = ec2.client.create_security_group({
	:group_name => sg_name,
	:description => sg_desc
})

print "Created Security Group's ID: " + created_sg[:group_id] + "\n"

ec2.client.authorize_security_group_ingress({
	:group_id => created_sg[:group_id],
	:group_name => sg_name,
	:ip_permissions => [{
			   	:ip_protocol => "tcp",
				:from_port => 2,
				:to_port => 98,
				:ip_ranges => [{:cidr_ip => "10.223.130.0/24"}]	
				}]
})

listed_sgs = ec2.client.describe_security_groups({
	:group_ids => [created_sg[:group_id]]
})

specific_sg = listed_sgs[:security_group_info].first
ip_perm = specific_sg[:ip_permissions].first
print "SG Group ID: " + specific_sg[:group_id] + "\n SG Group Name: " + specific_sg[:group_name] + "\n SG Group Description: " + specific_sg[:group_description] + "\n SG Group's Ingress Rule's IP Protocol: " + ip_perm[:ip_protocol] + "\n From Port: " + ip_perm[:from_port].to_s + " To Port: " + ip_perm[:to_port].to_s + "\n IP Range: " + ip_perm[:ip_ranges].first[:cidr_ip] + "\n"

ec2.client.revoke_security_group_ingress({
        :group_id => created_sg[:group_id],
	:group_name => sg_name,
        :ip_permissions => [{
                                :ip_protocol => "tcp",
                                :from_port => 2,
                                :to_port => 98,
                                :ip_ranges => [{:cidr_ip => "10.223.130.0/24"}]
                                }]
})

ec2.client.delete_security_group({
	:group_id => created_sg[:group_id],
	:group_name => sg_name
})


terminated_instances = ec2.client.terminate_instances({
	:instance_ids => [instance[:instance_id]]
})

print "Terminated Instance's ID: " + terminated_instances[:instances_set].first[:instance_id] + "\n"
print "Terminated Instance's previous State: " +  terminated_instances[:instances_set].first[:previous_state][:name] + "\n"
print "Terminated Instance's current State: " +  terminated_instances[:instances_set].first[:current_state][:name] + "\n" 


exit
