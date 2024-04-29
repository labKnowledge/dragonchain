FROM python:3.8-alpine as base

WORKDIR /usr/src/core
# Install necessary base dependencies and set UTC timezone for apscheduler
RUN apk --no-cache upgrade  &&  apk --no-cache add libffi libstdc++ gmp && echo "UTC" > /etc/timezone

# Install yq for yaml processing
RUN wget https://github.com/mikefarah/yq/releases/download/v4.25.1/yq_linux_amd64 -O /usr/bin/yq && \
    chmod +x /usr/bin/yq

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | sh



# Install Minikube (note: running Minikube inside Docker is not recommended for production)
RUN wget -O kubectl https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/ 

RUN kubectl version --client

FROM base AS builder
# Install build dependencies
RUN apk --no-cache add g++ make gmp-dev libffi-dev automake autoconf libtool
# Install python dependencies
ENV SECP_BUNDLED_EXPERIMENTAL 1
ENV SECP_BUNDLED_WITH_BIGNUM 1
COPY requirements.txt .
RUN python3 -m pip install --no-cache-dir -r requirements.txt

FROM base AS release
# Copy the installed python dependencies from the builder
COPY --from=builder /usr/local/lib/python3.8/site-packages /usr/local/lib/python3.8/site-packages
COPY --from=builder /usr/local/bin/gunicorn /usr/local/bin/gunicorn
# Copy our actual application
COPY --chown=1000:1000 . .

# Expose port for web access, if needed
EXPOSE 8080