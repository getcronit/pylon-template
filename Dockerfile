# use the official Bun image
# see all versions at https://hub.docker.com/r/oven/bun/tags
FROM oven/bun:1 as base

LABEL description="This is a template for a Pylon service"
LABEL org.opencontainers.image.source="https://github.com/getcronit/pylon-template"
LABEL maintainer="office@cronit.io"

WORKDIR /usr/src/pylon


# install dependencies into temp directory
# this will cache them and speed up future builds
FROM base AS install
ARG NODE_VERSION=20
RUN apt update \
    && apt install -y curl
RUN curl -L https://raw.githubusercontent.com/tj/n/master/bin/n -o n \
    && bash n $NODE_VERSION \
    && rm n \
    && npm install -g n

RUN mkdir -p /temp/dev
COPY package.json bun.lockb /temp/dev/
COPY prisma /temp/dev/prisma

RUN cd /temp/dev && bun install --frozen-lockfile
RUN cd /temp/dev && bun prisma generate

# install with --production (exclude devDependencies)
RUN mkdir -p /temp/prod
COPY package.json bun.lockb /temp/prod/
COPY prisma /temp/prod/prisma

RUN cd /temp/prod && bun install --frozen-lockfile --production
RUN cd /temp/prod && bun prisma generate

# copy node_modules from temp directory
# then copy all (non-ignored) project files into the image
FROM install AS prerelease
COPY --from=install /temp/dev/node_modules node_modules
COPY . .

# [optional] tests & build
ENV NODE_ENV=production

# Create .pylon folder (mkdir)
RUN mkdir -p .pylon
# RUN bun test
RUN bun run pylon build

# Deploy prisma schema (create dev.db)
RUN bun prisma migrate deploy

# copy production dependencies and source code into final image
FROM base AS release
RUN apt-get update -y && apt-get install -y openssl
COPY --from=install /temp/prod/node_modules node_modules
COPY --from=prerelease /usr/src/pylon/.pylon .pylon
COPY --from=prerelease /usr/src/pylon/package.json .
COPY --from=prerelease /usr/src/pylon/prisma prisma

# Change ownership of the parent directory to the bun user
RUN chown -R bun:bun /usr/src/pylon/prisma/db

# Ensure proper permissions for the parent directory
RUN chmod -R 755 /usr/src/pylon/prisma/db

# run the app
USER bun
EXPOSE 3000/tcp
ENTRYPOINT [ "/usr/local/bin/bun", "run", "./node_modules/.bin/pylon-server" ]


VOLUME [ "/usr/src/pylon/prisma/db" ]