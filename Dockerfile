# Stage 1: Builder
FROM node:24 AS builder

WORKDIR /usr/src/app

# Sao chép package.json và package-lock.json để cài đặt dependencies
COPY package*.json ./

# Cài đặt chỉ các production dependencies để tối ưu kích thước image
RUN npm ci --omit=dev

# Sao chép mã nguồn ứng dụng và static UI
COPY app.js db.js ./
COPY dist ./dist

# Stage 2: Runtime
FROM node:24-alpine AS runtime

# Clean up global npm and yarn to remove their vulnerabilities
RUN rm -rf /usr/local/lib/node_modules/npm \
           /usr/local/bin/npm \
           /usr/local/bin/npx \
           /opt/yarn-v* \
           /usr/local/bin/yarn \
           /usr/local/bin/yarnpkg

# Thiết lập các nhãn OCI (Open Container Initiative)
LABEL org.opencontainers.image.title="Simple Node.js Server" \
      org.opencontainers.image.description="A simple lightweight HTTP server running on Node.js alpine" \
      org.opencontainers.image.source="https://github.com/duytrq/cicd_basics" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.licenses="MIT"

# Thiết lập biến môi trường mặc định
ENV NODE_ENV=production \
    PORT=3000

# Tạo thư mục làm việc
WORKDIR /usr/src/app

# Sao chép ứng dụng và dependencies từ stage builder và gán quyền cho user node
COPY --from=builder --chown=node:node /usr/src/app .

# Sử dụng non-root user mặc định của image Node (node)
USER node

# Khai báo port ứng dụng lắng nghe
EXPOSE 3000

# Cấu hình Healthcheck sử dụng wget gọi tới endpoint /health đã tạo
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT}/health || exit 1

# Lệnh khởi chạy ứng dụng
CMD ["node", "app.js"]
