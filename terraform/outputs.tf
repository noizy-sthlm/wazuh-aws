output "indexer_ip"     { value = module.wazuh_indexer.private_ip }
output "server_ip"      { value = module.wazuh_server.private_ip }
output "dashboard_ip"   { value = module.wazuh_dashboard.private_ip }

output "indexer_instance_id"    { value = module.wazuh_indexer.id }
output "server_instance_id"     { value = module.wazuh_server.id }
output "dashboard_instance_id"  { value = module.wazuh_dashboard.id }

resource "local_file" "ansible_inventory" {
  content  = templatefile("${path.module}/../ansible/inventory.tftpl",
    {
      ds_instance_id = module.wazuh_dashboard.id,
      mngr_instance_id = module.wazuh_server.id,
      idx_instance_id = module.wazuh_indexer.id,
      ds_private_ip = module.wazuh_dashboard.private_ip,
      mngr_private_ip = module.wazuh_server.private_ip,
      idx_private_ip = module.wazuh_indexer.private_ip,
    }
  )
  
  filename = "${path.module}/../ansible/inventory.ini"
}