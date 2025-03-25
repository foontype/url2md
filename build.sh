docker build \
	--build-arg HTTP_PROXY \
	--build-arg http_proxy \
	--build-arg HTTPS_PROXY \
	--build-arg https_proxy \
	--build-arg no_proxy \
	--build-arg NO_PROXY \
	-t url2aidoc_nkf \
	-f Dockerfile.nkf \
	.
