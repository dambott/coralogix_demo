# delete secrets
kubectl delete secret coralogix-keys coralogix-rum-key

# stop the collector
helm delete  otel-coralogix-integration

# stop the otel demo
helm delete my-otel-demo

# delete the expose services (loadbalancers)
kubectl delete svc awsexpose 
kubectl delete svc exposecollector
