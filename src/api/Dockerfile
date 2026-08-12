# .NET API image - multi-stage, non-root, digest-pinned.
# Build context is ALWAYS the repo root:
#   docker build -t reference-api:local -f src/api/Dockerfile .
#
# Digests below were resolved 2026-08-12. Refresh them with:
#   docker buildx imagetools inspect IMAGE:TAG --format '{{.Manifest.Digest}}'
# Dependabot's docker ecosystem proposes the bumps; you review and merge.

# --- runtime base (ASP.NET 10.0.11) ---
FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine@sha256:c4b29bf368004ad9076c1ab9bc91fb373561e3905b4345637e14e8b8c57e3be8 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://*:8080 \
    ASPNETCORE_FORWARDEDHEADERS_ENABLED=true \
    DOTNET_gcServer=1

# --- build stage (SDK 10.0.400) ---
FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine@sha256:620e765fe18186c08399f7aa978f79f04b6bbf0ee1b3b8a91e2d5c9619e59da1 AS build
WORKDIR /src
# Full repo context: referenced projects and root configs are guaranteed
# present. Hand-picked COPY lists break silently the day someone adds a
# project reference. The .dockerignore at the repo root is what keeps this cheap.
COPY . .
RUN dotnet restore "src/api/Reference.Api.csproj"
# CSharpier_Bypass: formatting was already judged by the gate. Re-judging here
# would fail the build on a rule the gate has already passed.
RUN dotnet publish "src/api/Reference.Api.csproj" -c Release -o /app/publish -p:CSharpier_Bypass=true

# --- final ---
FROM base AS final
WORKDIR /app
# UID is pinned and USER is NUMERIC on purpose. With a name, kubelet cannot
# verify the user under securityContext.runAsNonRoot:true and refuses to start
# the container: "has non-numeric user (appuser), cannot verify user is non-root".
RUN addgroup -g 1001 -S appgroup && adduser -u 1001 -S -G appgroup appuser
COPY --from=build /app/publish ./
# Group must be 0, not appgroup. OpenShift's restricted-v2 SCC runs the container
# as a RANDOM uid that is always in group 0 - so group 0 is the only handle the
# image has on it. chmod g=u then gives that group the owner's permissions.
# chown 1001:1001 looks right and silently fails under an arbitrary uid.
RUN chown -R 1001:0 /app && chmod -R g=u /app
USER 1001
ENTRYPOINT ["dotnet", "Reference.Api.dll"]
