# Pinned to a commit, not a branch: this service is exposed to the public
# internet behind nothing but a secret URL, so upstream changes must be
# reviewed before they reach it. Bump deliberately, then `just garmin-image`.
FROM python:3.12-slim

# The commit tarball rather than git+https:// so the image needs no git client.
RUN pip install --no-cache-dir \
    "https://github.com/Taxuspt/garmin_mcp/archive/3610be6feed93088d85b0f35aba9d7d07c2505a7.tar.gz"

# 0.0.0.0 is the bind *inside* the container. Loopback-only exposure is
# enforced on the host by publishing to 127.0.0.1 (see garmin-mcp.service).
ENV GARMIN_MCP_TRANSPORT=streamable-http \
    GARMIN_MCP_HOST=0.0.0.0 \
    GARMIN_MCP_PORT=8765

EXPOSE 8765
CMD ["garmin-mcp"]
