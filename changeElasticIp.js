db.environment_log_server.updateOne(
{ "name": "ElasticsearchLocal" },
{ "$set": { "elasticHostList.$[].host": nodeIpPort } }
)
