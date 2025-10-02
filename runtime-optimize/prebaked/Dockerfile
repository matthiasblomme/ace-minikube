# syntax=docker/dockerfile:1
# --- Builder: deploy + optimize + first start/stop to warm runtime
# docker build -t ace-prebaked:13.0.4.0 .
# docker run -e LICENSE=accept -p 7600:7600 -p 7800:7800 --rm -ti ace-prebaked:13.0.4.0

# --- Builder stage: install and pre-warm ACE runtime
FROM registry.access.redhat.com/ubi9/ubi-minimal AS builder

# Accept license in build context
ENV LICENSE=accept

# Work as root
USER root

# Update base image and install required tools for extraction and warmup
RUN microdnf update -y && microdnf install -y util-linux tar unzip findutils binutils xz

# Create target directory for ACE installation
RUN mkdir -p /opt/ibm/ace-13

# Copy ACE installer archive (supplied in /sources/)
COPY /sources/13.0-ACE-LINUXX64-13.0.4.0.tar.gz /opt/ibm/ace13.tar.gz

# Extract ACE, excluding unused tools to reduce image size
RUN tar -xvf /opt/ibm/ace13.tar.gz \
    --exclude ace-13.0.*.0/tools \
    --exclude ace-13.0.*.0/server/tools/ibm-dfdl-java.zip \
    --exclude ace-13.0.*.0/server/tools/proxyservlet.war \
    --exclude ace-13.0.*.0/server/bin/TADataCollector.sh \
    --exclude ace-13.0.*.0/server/transformationAdvisor/ta-plugin-ace.jar \
    --strip-components=1 \
    -C /opt/ibm/ace-13/ > /dev/null 2>&1

# Accept license, create aceuser, initialize work directory
RUN /opt/ibm/ace-13/ace make registry global accept license deferred \
    && useradd --uid 1001 --create-home --home-dir /home/aceuser --shell /bin/bash -G mqbrkrs aceuser \
    && su - aceuser -c "export LICENSE=accept && . /opt/ibm/ace-13/server/bin/mqsiprofile && mqsicreateworkdir /home/aceuser/ace-server" \
    && echo ". /opt/ibm/ace-13/server/bin/mqsiprofile" >> /home/aceuser/.bashrc

# Copy BAR files and helper scripts (warmup.sh will be run during build)
COPY bars/*.bar /bars/
COPY scripts/* /scripts/
# COPY config/overrides.properties /config/overrides.properties  # optional overrides

# Use bash login shell
SHELL ["/bin/bash","-lc"]

# Debug: show ACE installation contents
RUN ls -la /opt/ibm/ace-13/

# Set ownership and make warmup.sh executable
RUN chown 1001:1001 /scripts/* \
 && chmod +x /scripts/warmup.sh \
 && sed -i 's/\r$//' /scripts/warmup.sh   # guard against Windows CRLF

# Switch to aceuser
USER 1001
SHELL ["/bin/bash","-lc"]

# Run warmup script during build to generate pre-warmed work directory
RUN /scripts/warmup.sh


# --- Final stage: minimal runtime image with pre-warmed work dir
FROM registry.access.redhat.com/ubi9/ubi-minimal

# Install required runtime tools and Java 11
RUN microdnf update -y \
    && microdnf install -y procps-ng findutils util-linux git tar java-11-openjdk-devel nano procps jq zip unzip \
    && microdnf clean -y all

# Reinstall tzdata to ensure time zone files are present
RUN microdnf reinstall tzdata -y

# Copy ACE runtime and pre-warmed aceuser home from builder
COPY --from=builder /opt/ibm/ace-13 /opt/ibm/ace-13
COPY --from=builder /home/aceuser/ /home/aceuser/
COPY /licenses/ /licenses/

# Clean up old log files from pre-warm step
RUN rm -rf /home/aceuser/ace-server/log/*.*

# Ensure aceuser and group exist
RUN groupadd -g 1001 mqbrkrs || true \
 && useradd --uid 1001 --create-home --home-dir /home/aceuser --shell /bin/bash -g 1001 -G mqbrkrs aceuser \
 && chown -R 1001:1001 /home/aceuser

# Expose ACE ports
EXPOSE 7600 7800 7843

# Run as non-root aceuser
USER 1001

# Default server name and license acceptance
ENV ACE_SERVER_NAME=ace-server
ENV LICENSE=accept

# Work directory
WORKDIR "/home/aceuser/ace-server"

# Entrypoint: start IntegrationServer with warmed state
# - Sources mqsiprofile
# - Starts IntegrationServer with the prepared work dir
# - Redirects output to /tmp/is.log
ENTRYPOINT ["bash", "-c", ". /opt/ibm/ace-13/server/bin/mqsiprofile && IntegrationServer --name ${ACE_SERVER_NAME} -w /home/aceuser/ace-server > /tmp/is.log 2>&1"]
