# Build and run:
#
# docker build -t ace-init:13.0.4.0 -f Dockerfile .
# docker run -e LICENSE=accept -p 7600:7600 -p 7800:7800 --rm -ti ace-init:13.0.4.0
#
# Can also mount a volume for the work directory:
#
#
# This might require a local directory with the right permissions, or changing the userid further down . . .

FROM registry.access.redhat.com/ubi9/ubi-minimal AS builder

RUN microdnf update -y && microdnf install -y procps-ng util-linux tar && microdnf clean all

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

FROM registry.access.redhat.com/ubi9/ubi-minimal

# Force reinstall tzdata package to get zoneinfo files
RUN microdnf update -y && microdnf install -y procps-ng findutils util-linux which tar && microdnf reinstall -y tzdata && microdnf clean all

# Install ACE v13.0.1.0 and accept the license
COPY --from=builder /opt/ibm/ace-13 /opt/ibm/ace-13
RUN /opt/ibm/ace-13/ace make registry global accept license deferred \
    && useradd --uid 1001 --create-home --home-dir /home/aceuser --shell /bin/bash -G mqbrkrs aceuser \
    && su - aceuser -c "export LICENSE=accept && . /opt/ibm/ace-13/server/bin/mqsiprofile && mqsicreateworkdir /home/aceuser/ace-server" \
    && echo ". /opt/ibm/ace-13/server/bin/mqsiprofile" >> /home/aceuser/.bashrc

# Add required license as text file in Liceses directory (GPL, MIT, APACHE, Partner End User Agreement, etc)
COPY /licenses/ /licenses/
COPY /bars/*.bar /bars/
COPY /scripts/* /scripts/

RUN chown 1001:1001 /scripts/*
RUN chown 1001:1001 /bars/*
RUN chmod +x /scripts/*

# aceuser
USER 1001

# Expose ports.  7600, 7800, 7843 for ACE;
EXPOSE 7600 7800 7843

# Set default Integration Server name
ENV ACE_SERVER_NAME=ace-server

# Set entrypoint to run the server
ENTRYPOINT ["bash", "-c", ". /opt/ibm/ace-13/server/bin/mqsiprofile && IntegrationServer --name ${ACE_SERVER_NAME} -w /home/aceuser/ace-server > /tmp/is.log 2>&1"]