```bash   
docker run -d --name open-design \
  -p 7456:7456 \
  -e OD_PORT=7456 \
  -e OD_DATA_DIR=.od \
  -v open-design-data:/app/.od \
  8216179140/open-design:v1.0.0
```