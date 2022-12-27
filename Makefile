account = $(shell aws sts get-caller-identity --profile $(AWS_PROFILE) --query "Account" --output text)
oidc = $(shell aws eks describe-cluster --name $(cluster-name) --profile $(AWS_PROFILE) --query "cluster.identity.oidc.issuer" --output text | cut -c 9-77)
repo = centos-22b
version = v2.4.3
AWS_PROFILE = centos-dev # centos-22b-dev aaccess for CLI, can also export temp values.
region = us-east-1
cluster-name = eks-dev
s3role = s3accessfluentd #put any name, rolw will be created with given name.
s3PolicyPath = file://"s3policy.json" # trust relationship for s3 access, to be attached to role.


es:
	kubectl apply -f ./Elasticsearch/namespace.yaml
	kubectl apply -f ./Elasticsearch/headless_service.yaml
	kubectl apply -f ./Elasticsearch/elasticsearch.yaml

fluent_deploy:
	# kubectl apply -f ./FluentD/FluentD_Deploy.yaml
	cat ./FluentD/FluentD_Deploy.yaml | sed "s/ACCT_NUMBER/$(account)/g; s/region-change/$(region)/g; s/version-change/$(version)/g; s/exchange-web/$(repo)/g" | kubectl apply -f -
	kubectl apply -f FluentD/FluentD_SA.yaml

kibana:
	kubectl apply -f ./Kibana1/Ingress_rule.yaml
	kubectl apply -f ./Kibana1/kibana_deploy.yaml

build_fluent:
	docker build -t $(repo):$(version) ./FluenD_image/

login:
	aws ecr get-login-password --region $(region) --profile $(AWS_PROFILE) | docker login --username AWS --password-stdin $(account).dkr.ecr.$(region).amazonaws.com

push_fluent: login
	docker tag $(repo):$(version) $(account).dkr.ecr.$(region).amazonaws.com/$(repo):$(version)
	docker push $(account).dkr.ecr.$(region).amazonaws.com/$(repo):$(version)

role: es fluent_deploy
#to s3 for fluent plugin
#oidc = $(shell aws eks describe-cluster --name $(cluster-name) --profile $(AWS_PROFILE) --query "cluster.identity.oidc.issuer" --output text)
	aws iam create-role --role-name $(s3role) --profile $(AWS_PROFILE) --assume-role-policy-document $(s3PolicyPath) > ~/Documents/log.txt
	aws iam attach-role-policy --profile $(AWS_PROFILE) --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --role-name $(s3role)
	kubectl annotate serviceaccount fluentd -n kube-logging eks.amazonaws.com/role-arn=arn:aws:iam::$(account):role/$(s3role)
	kubectl rollout restart ds fluentd -n kube-logging

all: build_fluent push_fluent role kibana





