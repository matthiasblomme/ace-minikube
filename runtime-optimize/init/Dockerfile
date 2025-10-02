# Build and run:
#
# docker build -t ace-init:13.0.4.0 -f Dockerfile .
# docker run -e LICENSE=accept -p 7600:7600 -p 7800:7800 --rm -ti ace-init:13.0.4.0
#
# Can also mount a volume for the work directory:
#
#
# This might require a local directory with the right permissions, or changing the userid further down . . .

# First stage: build ACE runtime
FROM registry.access.redhat.com/ubi9/ubi-minimal AS builder

# Update base image and install required tools for extraction
RUN microdnf update -y && microdnf install -y procps-ng util-linux tar && microdnf clean all

# Prepare target directory for ACE
RUN mkdir -p /opt/ibm/ace-13

# Copy ACE installer archive (you must provide this under /sources/)
COPY /sources/13.0-ACE-LINUXX64-13.0.4.0.tar.gz /opt/ibm/ace13.tar.gz

# Extract ACE, excluding unused tools and components to keep the image slim
RUN tar -xvf /opt/ibm/ace13.tar.gz \
    --exclude ace-13.0.*.0/tools \
    --exclude ace-13.0.*.0/server/tools/ibm-dfdl-java.zip \
    --exclude ace-13.0.*.0/server/tools/proxyservlet.war \
    --exclude ace-13.0.*.0/server/bin/TADataCollector.sh \
    --exclude ace-13.0.*.0/server/transformationAdvisor/ta-plugin-ace.jar \
    --strip-components=1 \
    -C /opt/ibm/ace-13/ > /dev/null 2>&1

# Second stage: final runtime image
FROM registry.access.redhat.com/ubi9/ubi-minimal

# Install required packages and force tzdata reinstall for timezone data
RUN microdnf update -y \
    && microdnf install -y procps-ng findutils util-linux which tar \
    && microdnf reinstall -y tzdata \
    && microdnf clean all

# Copy ACE runtime from builder stage
COPY --from=builder /opt/ibm/ace-13 /opt/ibm/ace-13

# Accept ACE license, create aceuser, and initialize a work directory
RUN /opt/ibm/ace-13/ace make registry global accept license deferred \
    && useradd --uid 1001 --create-home --home-dir /home/aceuser --shell /bin/bash -G mqbrkrs aceuser \
    && su - aceuser -c "export LICENSE=accept && . /opt/ibm/ace-13/server/bin/mqsiprofile && mqsicreateworkdir /home/aceuser/ace-server" \
    && echo ". /opt/ibm/ace-13/server/bin/mqsiprofile" >> /home/aceuser/.bashrc

# Copy license texts, BAR files, and helper scripts into the image
COPY /licenses/ /licenses/
COPY /bars/*.bar /bars/
COPY /scripts/* /scripts/

# Set ownership and permissions for aceuser
RUN chown 1001:1001 /scripts/* \
    && chown 1001:1001 /bars/* \
    && chmod +x /scripts/*

# Run as non-root user
USER 1001

# Expose standard ACE ports
EXPOSE 7600 7800 7843

# Default Integration Server name
ENV ACE_SERVER_NAME=ace-server

# Entrypoint: run IntegrationServer directly
# - Sources mqsiprofile for environment setup
# - Starts IntegrationServer with the given name and work directory
# - Redirects server output to /tmp/is.log
ENTRYPOINT ["bash", "-c", ". /opt/ibm/ace-13/server/bin/mqsiprofile && IntegrationServer --name ${ACE_SERVER_NAME} -w /home/aceuser/ace-server > /tmp/is.log 2>&1"]
