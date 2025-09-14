# syntax=docker/dockerfile:1
# --- Builder: deploy + optimize + first start/stop to warm runtime
# docker build -t ace-prebaked:13.0.4.0 .
# docker run -e LICENSE=accept -p 7600:7600 -p 7800:7800 --rm -ti ace-prebaked:13.0.4.0
FROM registry.access.redhat.com/ubi9/ubi-minimal AS builder
ENV LICENSE=accept
USER root
RUN microdnf update -y && microdnf install -y util-linux tar unzip findutils binutils xz

# install ace
RUN mkdir -p /opt/ibm/ace-13
COPY /sources/13.0-ACE-LINUXX64-13.0.4.0.tar.gz /opt/ibm/ace13.tar.gz
RUN tar -xvf /opt/ibm/ace13.tar.gz \
    --exclude ace-13.0.*.0/tools \
    --exclude ace-13.0.*.0/server/tools/ibm-dfdl-java.zip \
    --exclude ace-13.0.*.0/server/tools/proxyservlet.war \
    --exclude ace-13.0.*.0/server/bin/TADataCollector.sh \
    --exclude ace-13.0.*.0/server/transformationAdvisor/ta-plugin-ace.jar \
    --strip-components=1 \
    -C /opt/ibm/ace-13/ > /dev/null 2>&1

RUN /opt/ibm/ace-13/ace make registry global accept license deferred \
    && useradd --uid 1001 --create-home --home-dir /home/aceuser --shell /bin/bash -G mqbrkrs aceuser \
    && su - aceuser -c "export LICENSE=accept && . /opt/ibm/ace-13/server/bin/mqsiprofile && mqsicreateworkdir /home/aceuser/ace-server" \
    && echo ". /opt/ibm/ace-13/server/bin/mqsiprofile" >> /home/aceuser/.bashrc
    
# Bring BARs and optional overrides into the image
COPY bars/*.bar /bars/
COPY scripts/* /scripts/
#COPY config/overrides.properties /config/overrides.properties
SHELL ["/bin/bash","-lc"]

RUN ls -la /opt/ibm/ace-13/

RUN chown 1001:1001 /scripts/* \
 && chmod +x /scripts/warmup.sh \
 && sed -i 's/\r$//' /scripts/warmup.sh   # guard against CRLF on Windows

USER 1001
SHELL ["/bin/bash","-lc"]
RUN /scripts/warmup.sh

# --- Final: minimal runtime image with pre-warmed work dir
FROM registry.access.redhat.com/ubi9/ubi-minimal
RUN microdnf update -y && microdnf install -y procps-ng findutils util-linux git tar java-11-openjdk-devel nano procps jq zip unzip && microdnf clean -y all
RUN microdnf reinstall tzdata -y

# Install ACE and accept the license
COPY --from=builder /opt/ibm/ace-13 /opt/ibm/ace-13
COPY --from=builder /home/aceuser/ /home/aceuser/
COPY /licenses/ /licenses/

RUN rm -rf /home/aceuser/ace-server/log/*.*

RUN groupadd -g 1001 mqbrkrs || true \
 && useradd --uid 1001 --create-home --home-dir /home/aceuser --shell /bin/bash -g 1001 -G mqbrkrs aceuser \
 && chown -R 1001:1001 /home/aceuser

# Expose ports.  7600, 7800, 7843 for ACE;
EXPOSE 7600 7800 7843

# aceuser
USER 1001

# Set default Integration Server name
ENV ACE_SERVER_NAME=ace-server
ENV LICENSE=accept

# Set entrypoint for login shell
USER 1001
WORKDIR "/home/aceuser/ace-server"
ENTRYPOINT ["bash", "-c", ". /opt/ibm/ace-13/server/bin/mqsiprofile && IntegrationServer --name ${ACE_SERVER_NAME} -w /home/aceuser/ace-server > /tmp/is.log 2>&1"]
