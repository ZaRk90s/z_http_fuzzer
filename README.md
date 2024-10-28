# z_http_fuzzer

A simple yet effective HTTP fuzzer written in Zig.

## Disclaimer

This software is provided "as-is" without any warranty. Note that the program is optimized for use with 1–4 threads; using more may cause instability. Use this tool responsibly.

## Dependencies

- Zig >= 0.13.0

## Installation

Clone the repository and navigate to the source directory:

```bash
git clone https://github.com/ZaRk90s/z_http_fuzzer
cd z_http_fuzzer
```

Build with Zig:
```bash
zig build # or zig build -Doptimize=ReleaseSafe/Small/Fast
```

## Usage
---
Run the fuzzer with three required parameters:

- `-u URL` - Specify the URL to target.
- `-w dictionary.txt` - Provide the dictionary file for fuzzing.
- `-t 3` - Set the number of threads (1-4 recommended).

Example:
```bash
./z_http_fuzzer -u https://example.com -w dicctionary.txt -t 4
```

## To-do
---
- [ ] Improve the threads.
- [ ] Specify which HTTP Status Code show
- [ ] Change the Headers of a HTTP Request
- [ ] Subdomains enumeration
- [ ] Bypass the firewall
