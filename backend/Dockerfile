FROM python:3.9

WORKDIR /app

COPY . .

# Optional system dependencies (uncomment if needed later)
# RUN apt-get update && apt-get install -y gcc libpq-dev && rm -rf /var/lib/apt/lists/*

# Print file and debug install
RUN pip install --upgrade pip

RUN cat requirements.txt 
RUN pip install --no-cache-dir --verbose -r requirements.txt
CMD ["python3", "run.py"]
