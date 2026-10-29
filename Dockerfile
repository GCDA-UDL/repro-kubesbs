# Analysis environment of the reproduction package: regenerates the paper's figures
# and tables from the captured results (no Kubernetes needed).
#   docker build -t repro-kubesbs .
#   docker run --rm --user "$(id -u):$(id -g)" -v "$PWD:/repro" repro-kubesbs
# Re-running the experiments themselves needs the KubeSBS runner image and a Linux
# host: see REPRODUCE.md.
FROM python:3.11.10-slim-bookworm@sha256:840e180ebcc6e5c8efab209c43f5e40fd2af98cb49db5c7103c90539c56bb30e

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

ENV MPLCONFIGDIR=/tmp/matplotlib PYTHONDONTWRITEBYTECODE=1
WORKDIR /repro
ENTRYPOINT ["bash", "reproduce.sh"]
