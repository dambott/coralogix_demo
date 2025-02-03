# Needs to match 1-start.sh
export DEMO_NAMESPACE=astronomy-demo

# delete secrets
kubectl delete secret coralogix-keys -n ${DEMO_NAMESPACE}
kubectl delete secret coralogix-rum-key -n ${DEMO_NAMESPACE}

# stop the collector
helm delete  otel-coralogix-integration

# stop the otel demo
helm delete my-otel-demo

# delete the expose services (loadbalancers)
kubectl delete svc awsexpose 
kubectl delete svc exposecollector
kubectl delete namespace ${DEMO_NAMESPACE}
