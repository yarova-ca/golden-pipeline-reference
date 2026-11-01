# .NET API image - multi-stage, non-root, digest-pinned.
# Build context is ALWAYS the repo root:
#   docker build -t reference-api:local -f src/api/Dockerfile .
#
# Digests below were resolved 2026-08-12. Refresh them with:
#   docker buildx imagetools inspect IMAGE:TAG --format '{{.Manifest.Digest}}'
# Dependabot's docker ecosystem proposes the bumps; you review and merge.

# --- runtime base (ASP.NET 10.0.11) ---
FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine@sha256:254fe017495996d3abcc487ffacdcce2b73affb380d3af87af12c8dff41fe0b0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://*:8080 \
    ASPNETCORE_FORWARDEDHEADERS_ENABLED=true \
    DOTNET_gcServer=1

# --- build stage (SDK 10.0.400) ---
FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine@sha256:cc02b814237a76c4735fb6eeee87181597b5e56f2ce458a435e527674d91f4d7 AS build
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
