#include <stdint.h>
#include <stdlib.h>
#include <iostream>
#include <fstream>

template <typename T>
__global__ void add(T* A, T* B, T* C,size_t elementcount) {
    for (size_t i = blockIdx.x * blockDim.x + threadIdx.x; 
         i < elementcount; 
         i += blockDim.x * gridDim.x)
    {
        C[i] = A[i] + B[i];
    }
}

template <typename T>
void add_cpu(T* A, T* B, T* C, size_t elementcount) {
    for (size_t i = 0; i < (int) elementcount; i++) {
        C[i] = A[i] + B[i];
    }
}

template <typename T>
void validate(T* h, T* d, size_t elementcount) {
    for (size_t i = 0; i < elementcount; i++) {
        if (h[i] != d[i]) {
            std::cout << "found invalidated field in element " << i << std::endl;
            std::cout << "on CPU side: " << h[i] << std::endl;
            std::cout << "on GPU side: " << d[i] << std::endl;
        }
    }
}

int main(void)
{
    size_t elementcount=1048576;
    uint64_t* h_A;
    uint64_t* h_B;
    uint64_t* h_C;

    uint64_t* h_out;

    uint64_t* d_A;
    uint64_t* d_B;
    uint64_t* d_C;

    std::ofstream myFile("add.csv");

// for appending
//    std::ofstream myFile("add.csv", std::ios::app);
//    myFile << "\n" << "\n";

    myFile << "kernel;element_count;block_count;thread_count;time_ms;throughput\n";

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    size_t bytes = elementcount * sizeof(uint64_t);

    h_A = (uint64_t*)malloc(bytes);
    h_B = (uint64_t*)malloc(bytes);
    h_C = (uint64_t*)malloc(bytes);
    h_out = (uint64_t*)malloc(bytes);

    cudaMalloc(&d_A, bytes);
    cudaMalloc(&d_B, bytes);
    cudaMalloc(&d_C, bytes);


    for (size_t i = 0; i < elementcount; i++) {
        h_A[i] = rand() % 8000 + 1;
        h_B[i] = rand() % 8000 + 1;
    }

    cudaMemcpy(d_A, h_A, bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, bytes, cudaMemcpyHostToDevice);

    for(int i=16;i<=1024;i=i*2){
        for(int j=8;j<=512;j=j*2){
            cudaMemset(d_C, 0, bytes);
	
            cudaEventRecord(start);
            add <<<j, i >>> (d_A, d_B, d_C, elementcount);
            cudaEventRecord(stop);
    
            cudaMemcpy(h_out, d_C, bytes, cudaMemcpyDeviceToHost);

            cudaEventSynchronize(stop);

            float milliseconds = 0;
            cudaEventElapsedTime(&milliseconds, start, stop);

            add_cpu(h_A, h_B, h_C, elementcount);


            validate(h_C, h_out, elementcount);

            myFile << "add" << ";";
            myFile << elementcount << ";";
            myFile << j << ";";
            myFile << i << ";";
            myFile << milliseconds << ";";
            myFile << elementcount*8*2/milliseconds/1e6 << "\n";
        }
    }



    myFile.close();

    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);


    free(h_out);
    free(h_A);
    free(h_B);
    free(h_C);

    return 0;
}
