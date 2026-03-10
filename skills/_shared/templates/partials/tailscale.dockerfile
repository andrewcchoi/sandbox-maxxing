# ============================================================================
# Tailscale Partial
# ============================================================================
# Secure remote access and networking
# Uses official Tailscale Docker image for proxy-friendly installation
# ============================================================================

USER root

# Copy Tailscale binaries from official image
COPY --from=tailscale-source /usr/local/bin/tailscale /usr/local/bin/tailscale
COPY --from=tailscale-source /usr/local/bin/tailscaled /usr/local/bin/tailscaled

# Create Tailscale state directory
RUN mkdir -p /var/lib/tailscale && \
    chown -R node:node /var/lib/tailscale

# Grant node user sudo access to tailscale commands (needed for network operations)
RUN echo "node ALL=(root) NOPASSWD: /usr/local/bin/tailscaled, /usr/local/bin/tailscale" > /etc/sudoers.d/node-tailscale && \
    chmod 0440 /etc/sudoers.d/node-tailscale

USER node
