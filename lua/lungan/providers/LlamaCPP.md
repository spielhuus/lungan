# llama.cpp

## intel GPU

install the intel Sycl packages

with Intel SYCL:

```bash
cmake -B build -DGGML_SYCL=ON -DCMAKE_C_COMPILER=icx -DCMAKE_CXX_COMPILER=icpx
cmake --build build --config Release -j -v
```

with CUDA:

```bash
cmake -B build -DGGML_CUDA=ON
cmake --build build --config Release
```

start the LlamaCPP server

```bash
llama-server --models-dir ./my-models
```
