docker buildx build . -t localdev/pgaof-extensions:v2.1-16

docker buildx build . --output type=tar,dest=./build_cache.tar

docker tag d71f3af9a48f registry.cn-hangzhou.aliyuncs.com/ym01/pgaof-extensions:v2.1-16

docker push registry.cn-hangzhou.aliyuncs.com/ym01/pgaof-extensions:v2.1-16