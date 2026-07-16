# Build from the autoverify/ repo root:  docker build -t autoverify-api -f Dockerfile .
# (not from backend/ - this image needs both the Perl Core and the Python backend)
FROM python:3.12-slim

# Perl core Perl + JSON::PP are both bundled with the 'perl' package on
# Debian - no CPAN dependency needed (matches AutoVerify::Core's own
# "core Perl only, no CPAN" constraint).
RUN apt-get update && apt-get install -y --no-install-recommends perl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /srv/autoverify

# Core library (Parser/Generator/etc.) + the JSON bridge + examples the
# service layer may reference (run_sim.tcl, Makefile) for zip packaging.
COPY lib/ ./lib/
COPY bin/ ./bin/
COPY examples/ ./examples/
COPY run_sim.tcl Makefile ./

# Python service + API layer
COPY backend/requirements.txt ./backend/requirements.txt
RUN pip install --no-cache-dir -r backend/requirements.txt

COPY backend/app/ ./backend/app/

EXPOSE 8000

# Railway (and most PaaS Docker runners) inject $PORT; default to 8000 for
# local `docker run -p 8000:8000` where $PORT isn't set.
ENV PORT=8000
WORKDIR /srv/autoverify/backend
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT}"]
