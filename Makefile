account = $(shell aws sts get-caller-identity --query "Account" --output text)
repo = morningstar
region = us-east-1
version = 2.0


build:
	docker build -t $(repo):$(version) .

login: build
	aws ecr get-login-password --region $(region) | docker login --username AWS --password-stdin $(account).dkr.ecr.$(region).amazonaws.com

push: login
	docker tag $(repo):$(version) $(account).dkr.ecr.$(region).amazonaws.com/$(repo):$(version)
	docker push $(account).dkr.ecr.$(region).amazonaws.com/$(repo):$(version)

deploy:	push
	cat manifests/deploy.yaml | sed "s/ACCT_NUMBER/$(account)/g; s/region-change/$(region)/g; s/version-change/$(version)/g" | kubectl apply -f -

ingress:
	kubectl delete -f manifests/ingress-controller-alb.yaml
	kubectl -n ingress-nginx patch service ingress-nginx-controller -p '{"spec":{"externalTrafficPolicy":"Cluster"}}'
