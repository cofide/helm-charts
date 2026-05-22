# cofide-credex

A Helm chart for deploying Cofide Credex - an OAuth 2.0 Authorization Server (AS) and Security Token Service (STS) service that uses SPIFFE workload identity for secure service-to-service communication.

## Prerequisites

- Helm 3+
- SPIRE agent running with the CSI driver (`csi.spiffe.io`) available on each node

### Required Secret

When the local signer is in use (the default), a Kubernetes Secret named `oauth-private-key` must exist in the release namespace **before installation**. It should contain the OAuth AS private key at the key `private-key.pem`.

Generate an EC P-256 private key and create the Secret:

```bash
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out private-key.pem

kubectl create secret generic oauth-private-key \
  --from-file=private-key.pem=private-key.pem
```

The Secret name defaults to `oauth-private-key` and is configurable via `credex.signing.privateKeySecret`. The chart verifies this Secret exists at install time and will fail with a clear error if it is missing. To skip this check when rendering templates without cluster access (e.g. in CI), set `credex.preflightChecks: false`.

When the local signer is not in use (`credex.signing.method=spire` and `local` is not in `credex.signing.extraJWKSSources`), the Secret is not required and is not mounted.

## Installation

```bash
helm install cofide-credex cofide/cofide-credex \
  --set credex.issuerURL=https://credex.example.org \
  --set credex.connectURL=connect.example.org:443 \
  --set credex.connectTrustDomain=example.org
```

## Configuration

### OAuth Authorisation Server (`enableOAuthAS: true`)

| Value | Description | Required |
|---|---|---|
| `credex.issuerURL` | Issuer URL advertised in the OAuth AS metadata | Yes |
| `credex.accessTokenLifetime` | Token lifetime, e.g. `5m`, `1h`. Defaults to 1 minute | No |
| `credex.policyConfigFile` | Path to a local policy config file. Mutually exclusive with `connectURL` | One of |
| `credex.connectURL` | Host:port of the Cofide Connect service used as the policy store. Mutually exclusive with `policyConfigFile` | One of |
| `credex.connectTrustDomain` | SPIFFE trust domain of the Cofide Connect service. Required when `connectURL` is set | Conditional |

### Signing Keys

The OAuth AS supports two signing modes, configured via `credex.signing.method`:

- `local` (default): an in-process RSA key. Loaded from `credex.signing.privateKeyFile` when the `oauth-private-key` Secret is mounted; otherwise an ephemeral key is generated on each start.
- `spire`: delegates signing to a Cofide-SPIRE custom JWT signer gRPC service. The SPIRE server must allow Credex's SPIFFE ID via `experimental.custom_jwt_signers`.

| Value | Description | Required |
|---|---|---|
| `credex.signing.method` | `local` or `spire` | No (defaults to `local`) |
| `credex.signing.privateKeyFile` | Path to the OAuth AS private key file inside the container | When the local signer is in use |
| `credex.signing.privateKeySecret` | Name of the Kubernetes Secret containing the OAuth AS private key at the `private-key.pem` key | When the local signer is in use |
| `credex.signing.spireServerAddr` | host:port of the SPIRE server's gRPC endpoint | When method is `spire` or `spire` is in `extraJWKSSources` |
| `credex.signing.extraJWKSSources` | Additional signing methods whose verification keys are published on `/keys` alongside the active signer. Each entry must be `local` or `spire`, differ from `method`, and appear at most once. Used to bridge a signing-key migration. | No |

During a migration from `local` to `spire`, set `credex.signing.method=spire` and `credex.signing.extraJWKSSources=[local]` (keeping the `oauth-private-key` Secret in place). Once the previous access tokens have expired, drop `extraJWKSSources` and the `oauth-private-key` Secret.

### SPIFFE Token Exchange (`enableSPIFFEExchange: true`)

| Value | Description | Required |
|---|---|---|
| `credex.spireAgentAdminSocket` | SPIRE Agent admin socket path inside the container. Defaults to `unix:///run/spire/private/sockets/admin.sock` | No |
| `credex.spireAgentAdminSocketHostPath` | Host path for the SPIRE Agent admin socket. Enables Delegation API access. | Yes |

### TLS Configuration

The service can be configured to use TLS. When enabled, a Kubernetes Secret containing the TLS certificate and key must be provided.

| Value | Description | Required |
|---|---|---|
| `credex.tls.enabled` | Enable TLS for the service | No |
| `credex.tls.certFile` | Path to the PEM-encoded TLS certificate file inside the container. Defaults to `/run/credex/tls/tls.crt`. | No |
| `credex.tls.keyFile` | Path to the PEM-encoded TLS private key file inside the container. Defaults to `/run/credex/tls/tls.key`. | No |
| `credex.tls.secretName` | Name of the Kubernetes Secret containing the TLS certificate and key | Conditional |

The Secret must contain `tls.crt` and `tls.key` keys.

#### Smart Defaults for TLS

When `credex.tls.enabled` is set to `true`, the chart automatically adjusts several parameters to align with a standard HTTPS configuration:

- **`service.port`**: Switches from `80` to `443`.
- **`service.targetPort`**: Switches from `8080` to `8443`.
- **Probes**: Liveness and readiness probes automatically switch from `HTTP` to `HTTPS` and use port `8443`.

These defaults are only applied if the respective values (e.g., `service.port`) are left at their chart-level default values. Explicit overrides in your `values.yaml` will always take precedence.

### Trusted Issuers

External JWT issuers accepted for token exchange are configured as a list:

```yaml
credex:
  trustedIssuers:
    - issuer: https://issuer.example.org
      jwksURL: https://issuer.example.org/.well-known/jwks.json
      allowedAudiences:
        - my-service
```

Each entry generates numbered environment variables: `TRUSTED_ISSUER_n`, `TRUSTED_ISSUER_JWKS_URL_n`, and optionally `TRUSTED_ISSUER_ALLOWED_AUDIENCES_n`.

### Extra CA Certificate

Set `credex.extraCA` to a PEM-encoded CA certificate to trust additional CAs (e.g. for a self-signed Connect instance). The certificate is mounted at `/etc/ssl/certs/extra-ca.crt`.
