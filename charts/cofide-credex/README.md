# cofide-credex

A Helm chart for deploying Cofide Credex - an OAuth 2.0 Authorization Server (AS) and Security Token Service (STS) service that uses SPIFFE workload identity for secure service-to-service communication.

## Prerequisites

- Helm 3+
- SPIRE agent running with the CSI driver (`csi.spiffe.io`) available on each node

### Required Secret

A Kubernetes Secret named `oauth-private-key` must exist in the release namespace **before installation**. It should contain the OAuth AS private key at the key `private-key.pem`.

Generate an EC P-256 private key and create the Secret:

```bash
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out private-key.pem

kubectl create secret generic oauth-private-key \
  --from-file=private-key.pem=private-key.pem
```

The Secret name defaults to `oauth-private-key` and is configurable via `credex.oauthPrivateKeySecret`. The chart verifies this Secret exists at install time and will fail with a clear error if it is missing. To skip this check when rendering templates without cluster access (e.g. in CI), set `credex.preflightChecks: false`.

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
| `credex.oauthPrivateKeyFile` | Path to the OAuth AS private key file | Yes |
| `credex.policyConfigFile` | Path to a local policy config file. Mutually exclusive with `connectURL` | One of |
| `credex.connectURL` | Host:port of the Cofide Connect service used as the policy store. Mutually exclusive with `policyConfigFile` | One of |
| `credex.connectTrustDomain` | SPIFFE trust domain of the Cofide Connect service. Required when `connectURL` is set | Conditional |

### Custom Token Exchange (`enableCustomExchange: true`)

| Value | Description | Required |
|---|---|---|
| `credex.baseDomain` | Base domain for the custom token exchange endpoint | Yes |
| `credex.spireAgentAdminSocket` | SPIRE Agent admin socket path inside the container. Defaults to `unix:///run/spire/private/sockets/admin.sock` | No |
| `credex.spireAgentAdminSocketHostPath` | Host path for the SPIRE Agent admin socket. Enables Delegation API access. | Yes |

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
