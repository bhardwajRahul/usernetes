ARG BASE_IMAGE=docker.io/kindest/node:v1.33.1@sha256:050072256b9a903bd914c0b2866828150cb229cea0efe5892e2b644d5dd3b34f
ARG CNI_PLUGINS_VERSION=v1.7.1
ARG HELM_VERSION=v3.18.3
ARG FLANNEL_VERSION=v0.27.0
FROM ${BASE_IMAGE}
COPY Dockerfile.d/SHA256SUMS.d/ /tmp/SHA256SUMS.d
ARG CNI_PLUGINS_VERSION
ARG HELM_VERSION
ARG FLANNEL_VERSION
RUN arch="$(uname -m | sed -e s/x86_64/amd64/ -e s/aarch64/arm64/)" && \
  fname="cni-plugins-linux-${arch}-${CNI_PLUGINS_VERSION}.tgz" && \
  curl -o "${fname}" -fSL "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/${fname}" && \
  grep "${fname}" "/tmp/SHA256SUMS.d/cni-plugins-${CNI_PLUGINS_VERSION}" | sha256sum -c && \
  mkdir -p /opt/cni/bin && \
  tar xzf "${fname}" -C /opt/cni/bin && \
  rm -f "${fname}" && \
  fname="helm-${HELM_VERSION}-linux-${arch}.tar.gz" && \
  curl -o "${fname}" -fSL "https://get.helm.sh/${fname}" && \
  grep "${fname}" "/tmp/SHA256SUMS.d/helm-${HELM_VERSION}" | sha256sum -c && \
  tar xzf "${fname}" -C /usr/local/bin --strip-components=1 -- "linux-${arch}/helm" && \
  rm -f "${fname}" && \
  fname="flannel.tgz" && \
  curl -o "${fname}" -fSL "https://github.com/flannel-io/flannel/releases/download/${FLANNEL_VERSION}/${fname}" && \
  grep "${fname}" "/tmp/SHA256SUMS.d/flannel-${FLANNEL_VERSION}" | sha256sum -c && \
  tar xzf "${fname}" -C / && \
  rm -f "${fname}"
# gettext-base: for `envsubst`
# moreutils: for `sponge`
# socat: for `socat` (to silence "[WARNING FileExisting-socat]" from kubeadm)
RUN apt-get update && apt-get install -y --no-install-recommends \
  gettext-base \
  moreutils \
  socat
ADD Dockerfile.d/etc_udev_rules.d_90-flannel.rules /etc/udev/rules.d/90-flannel.rules
ADD Dockerfile.d/u7s-entrypoint.sh /
ENTRYPOINT ["/u7s-entrypoint.sh", "/usr/local/bin/entrypoint", "/sbin/init"]
