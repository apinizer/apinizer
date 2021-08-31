db.environment_settings.updateOne(
{ "name": "prod-env" },
{ "$set": { "accessUrl": nodeIpPort } }
);

db.environment_log_server.updateOne(
{ "name": "ElasticsearchLocal" },
{ "$set": { "elasticHostList.$[].host": nodeIpPort } }
);
