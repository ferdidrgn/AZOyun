FROM node:24-alpine
WORKDIR /app
COPY family-server/game.mjs family-server/server.mjs family-server/progression.mjs ./family-server/
COPY build/salon ./build/salon
USER node
EXPOSE 8780
CMD ["node", "family-server/server.mjs"]
