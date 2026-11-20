FROM node:24-alpine
WORKDIR /app
COPY family-server/game.mjs family-server/server.mjs family-server/progression.mjs family-server/party-games.mjs ./family-server/
COPY build/salon ./build/salon
RUN mkdir -p /app/state && chown node:node /app/state
USER node
EXPOSE 8780
CMD ["node", "family-server/server.mjs"]
