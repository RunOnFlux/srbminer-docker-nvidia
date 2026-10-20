# srbminer-docker-nvidia

[SRBMiner-MULTI](https://github.com/doktor83/SRBMiner-Multi) for NVIDIA GPUs, built from the upstream release binaries.

```
ghcr.io/runonflux/srbminer-docker-nvidia:latest
ghcr.io/runonflux/srbminer-docker-nvidia:<srbminer version>   # e.g. 3.7.8
```

A workflow checks for a new SRBMiner-Multi release every 6 hours and publishes it under its version tag and `latest`. Each download is checked against the md5 published with the release.

## Environment

| Variable     | Required | Description |
|--------------|----------|-------------|
| `ALGO`       | yes      | Algorithm, e.g. `pearlhash` (Pearl / PRL). Full list: `--list-algorithms` |
| `POOL`       | yes      | Pool `host:port` |
| `WALLET`     | yes      | Wallet address (some pools expect `address.worker` here instead of `WORKER`) |
| `WORKER`     | no       | Worker / rig name, passed as `--worker` |
| `PASSWORD`   | no       | Pool password, passed as `--password` |
| `CPU_MINING` | no       | `true` to also mine on the CPU. The default is GPU only (`--disable-cpu`) |
| `EXTRA`      | no       | Extra SRBMiner arguments, space separated, e.g. `--tls true --api-enable` |

All parameters: <https://github.com/doktor83/SRBMiner-Multi/blob/master/Parameters>

## Run

Needs the NVIDIA container runtime on the host.

```sh
docker run -d --gpus all --restart unless-stopped \
  -e ALGO=pearlhash \
  -e POOL=<pool host:port> \
  -e WALLET=<your PRL address> \
  -e WORKER=rig1 \
  ghcr.io/runonflux/srbminer-docker-nvidia:latest
```

## Notes

- SRBMiner uses OpenCL for NVIDIA. The image ships the OpenCL loader and NVIDIA's ICD entry, but no driver libraries. Those come from the host through the NVIDIA runtime, so the host driver version is what counts. Some algorithms need a recent driver, for example `noid` needs 580+.
- SRBMiner prints nothing when it has no terminal, which is how Kubernetes and `docker run -d` start it. In that case the entrypoint runs it under `script` to give it a pseudo-terminal, so log lines end in `\r`. Setting `tty: true` (compose or Kubernetes) or `docker run -t` makes the entrypoint run it directly.
- SRBMiner charges a dev fee per algorithm (shown by `--list-algorithms`).
