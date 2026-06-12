[db_servers]
db_node_1 ansible_host=${db_ip} ansible_user=ia-admin ansible_password=silne_haslo123!

[app_servers]
app_node_1 ansible_host=${app_ip} ansible_user=ia-admin ansible_password=silne_haslo123!

[db_servers:vars]
db_port=5432
env_type=development
