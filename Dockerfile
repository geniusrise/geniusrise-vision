# Builder stage: Use the devel image to build and install your application
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04 AS builder

WORKDIR /build

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies and Python
RUN apt-get update \
 && apt-get install -y software-properties-common build-essential curl wget vim git cmake libpq-dev pkg-config \
 && add-apt-repository ppa:deadsnakes/ppa \
 && apt-get update \
 && apt-get install -y python3.10 python3.10-dev python3.10-distutils \
 && apt-get clean
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
 && python3.10 get-pip.py

RUN pip install --ignore-installed --no-cache-dir --upgrade --user packaging
RUN pip install --ignore-installed --no-cache-dir --upgrade --user torch==2.1.2
RUN CMAKE_ARGS="-DLLAMA_CUBLAS=on" pip install --ignore-installed --no-cache-dir --upgrade --user geniusrise-vision
ENV GENIUS=/home/genius/.local/bin/genius

# Runtime stage: Use the runtime image to create a smaller, more secure final image
FROM nvidia/cuda:12.2.0-base-ubuntu22.04 AS base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y software-properties-common build-essential curl wget vim git cmake libpq-dev pkg-config \
 && add-apt-repository ppa:deadsnakes/ppa \
 && apt-get update \
 && apt-get install -y python3.10 python3.10-dev python3.10-distutils \
 && apt-get clean
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
 && python3.10 get-pip.py

WORKDIR /app

# Create a user for running the application
RUN useradd --create-home genius

# Copy the installed Python packages and any other necessary files from the builder image
COPY --from=builder /root/.local /home/genius/.local

ENV TZ UTC
ENV PATH=/home/genius/.local/bin:$PATH
RUN chmod +x /home/genius/.local/bin/*

USER genius

CMD ["genius", "--help"]
