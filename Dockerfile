FROM python:3.12-slim

RUN useradd --create-home --shell /bin/bash appuser
WORKDIR /app
COPY . /app
RUN chmod +x /app/tools/*.py /app/tools/*.sh /app/start.sh /app/START.bat || true
RUN pip install --no-cache-dir cryptography

USER appuser
EXPOSE 8889 8890 8891 8892 3000
CMD ["python3", "-m", "http.server", "127.0.0.1", "3000", "--directory", "/app/tools/web"]
