output "indexer_ip"     { value = module.wazuh_indexer.private_ip }
output "server_ip"      { value = module.wazuh_server.private_ip }
output "dashboard_ip"   { value = module.wazuh_dashboard.private_ip }

output "indexer_instance_id"    { value = module.wazuh_indexer.id }
output "server_instance_id"     { value = module.wazuh_server.id }
output "dashboard_instance_id"  { value = module.wazuh_dashboard.id }