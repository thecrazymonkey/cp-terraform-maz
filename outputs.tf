// A variable for extracting the external ip of the instance
output "zookeeper_ip" {
 value = module.cp_maz_zk.*.ip
}
output "kafka_broker_ip" {
 value = module.cp_maz_bk.*.ip
}
output "schema_registry_ip" {
 value = module.cp_maz_sr.*.ip
}
output "kafka_connect_ip" {
 value = module.cp_maz_co.*.ip
}
output "kafka_rest_ip" {
 value = module.cp_maz_rp.*.ip
}
output "ksql_ip" {
 value = module.cp_maz_ks.*.ip
}
output "control_center_ip" {
 value = module.cp_maz_cc.*.ip
}
output "zookeeper" {
 value = module.cp_maz_zk.*.hostname
}
output "kafka_broker" {
 value = module.cp_maz_bk.*.hostname
}
output "schema_registry" {
 value = module.cp_maz_sr.*.hostname
}
output "kafka_connect" {
 value = module.cp_maz_co.*.hostname
}
output "kafka_rest" {
 value = module.cp_maz_rp.*.hostname
}
output "ksql" {
 value = module.cp_maz_ks.*.hostname
}
output "control_center" {
 value = module.cp_maz_cc.*.hostname
}
