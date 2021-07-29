db.environment_log_server.updateOne(
{ "name": "ElasticsearchLocal" },
{ "$set": { "elasticHostList.$[].host": "10.0.1.1" } }
)
