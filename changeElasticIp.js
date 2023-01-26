db.environment_settings.updateOne(
{ "name": "prod-env" },
{ "$set": { "accessUrl": "http://"+nodeIpPort+":30080" } }
);


db.environment_log_server.updateOne(
{ "name": "elasticsearch" },
{ "$set": { "elasticHostList.$[].host": nodeIpPort } }
);
