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
#       :http_open_timeout => 120
}

templ_name = "RubyPwdTempl"
templ_desc = templ_name+"-Description"
wait_time_in_sec = 60
keyname = "Ruby-Keypair-1"

#ec2= AWS.ec2
AWS.config({:http_read_timeout => 120, :http_idle_timeout => 120, :http_open_timeout => 120, :max_retries => 4})
##AWS.config.http_read_timeout = 300
ec2 = AWS::EC2.new(cred)

all_images = ec2.client.describe_images({
        :executable_users => ["self"],
        :filters => [{:name => "name", :values => [templ_name]}]
})

image = all_images[:images_set].first
print "Image Name: " + image[:name] + "\n Image ID: " + image[:image_id] + "\n"

created_keypair = ec2.client.create_key_pair({
        :key_name => keyname
})

new_instances = ec2.client.run_instances({
        :image_id => image[:image_id],
        :instance_type => "m1.small",
        :min_count => 1,
        :max_count => 1,
	:key_name => keyname
})

instance = new_instances[:instances_set].first
print "Instance ID: " + instance[:instance_id] + "\n"
print "Instance's State: " + instance[:instance_state][:name] + "\n"

instance_password = ec2.client.get_password_data({
       :instance_id => instance[:instance_id]
})

print "Instance's ID: " + instance_password[:instance_id] + "Instance's Password Data: " + instance_password[:password_data] + "\n"

terminated_instances = ec2.client.terminate_instances({
        :instance_ids => [instance[:instance_id]]
})

print "Terminated Instance's ID: " + terminated_instances[:instances_set].first[:instance_id] + "\n"
print "Terminated Instance's previous State: " +  terminated_instances[:instances_set].first[:previous_state][:name] + "\n"
print "Terminated Instance's current State: " +  terminated_instances[:instances_set].first[:current_state][:name] + "\n"

ec2.client.delete_key_pair({
        :key_name => keyname
})

exit

