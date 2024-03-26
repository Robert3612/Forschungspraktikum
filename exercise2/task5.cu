#include <stdint.h>
#include <stdlib.h>
#include <iostream>

template <typename T>
__global__ void aggregate_shared(T* A, T* C,size_t elementcount) {
    extern __shared__ uint64_t temp[];
    size_t id = blockIdx.x * blockDim.x + threadIdx.x;
    size_t step;
    if(elementcount > blockDim.x * gridDim.x){
        step = blockDim.x * gridDim.x;
    }
    else{
        step = elementcount/2;
    }
    int border = elementcount;
    for (size_t i = id; i < border; i += step){
        temp[i] = A[i];
    
    }
    while(border> 1){
    if(id <= step){
    for (size_t i = id; i < border; i += step){ 
        if(id != i){
        temp[id] = temp[id] + temp[i];
        }
    }
    border = step;
    step = step/2;
    }
    else{
        break;
    }
    __syncthreads();
    }
    if(id==0){
        *C=temp[0];
    }
}

template <typename T>
__global__ void aggregate(T* A, T* C,size_t elementcount) {
    size_t id = blockIdx.x * blockDim.x + threadIdx.x;
    size_t step;
    if(elementcount > blockDim.x * gridDim.x){
        step = blockDim.x * gridDim.x;
    }
    else{
        step = elementcount/2;
    }
    int border = elementcount;
    
    while(border> 1){
    if(id <= step){
    for (size_t i = id; i < border; i += step){ 
        if(id != i){
        A[id] = A[id] + A[i];
        }
    }
    border = step;
    step = step/2;
    }
    else{
        break;
    }
    __syncthreads();
    }
    if(id==0){
        *C=A[0];
    }
}

template <typename T>
void aggregate_cpu(T* A, T* C, size_t elementcount) {
    for (size_t i = 0; i < (int) elementcount; i++) {
        *C = *C + A[i];
    }
}

template <typename T>
void validate(T* h, T* d) {

        if (*h != *d) {
            std::cout << "found invalidated answer" << std::endl;
            std::cout << "on CPU side: " << *h << std::endl;
            std::cout << "on GPU side: " << *d << std::endl;
        }
    
}

int main(void)
{
    size_t elementcount=10;
    size_t bytes = elementcount * sizeof(uint64_t);
    uint64_t* h_A;
    uint64_t* h_C;

    uint64_t* h_out;

    uint64_t* d_A;
    uint64_t* d_C;



    h_A = (uint64_t*)malloc(bytes);
    h_C = (uint64_t*)malloc(sizeof(uint64_t));
    h_out = (uint64_t*)malloc(sizeof(uint64_t));

    cudaMalloc(&d_A, bytes);
    cudaMalloc(&d_C, sizeof(uint64_t));

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);


    for (size_t i = 0; i < elementcount; i++) {
        h_A[i] = rand() % 8000 + 1;
    }

    aggregate_cpu(h_A, h_C, elementcount);

    cudaEvent_t start2, stop2;
    cudaEventCreate(&start2);
    cudaEventCreate(&stop2);

    cudaMemcpy(d_A, h_A, bytes, cudaMemcpyHostToDevice);

    cudaMemset(d_C, 0, sizeof(uint64_t));
	
    cudaEventRecord(start2);
    aggregate <<<1, 4 >>> (d_A, d_C, elementcount);
    cudaEventRecord(stop2);

    cudaEventSynchronize(stop2);

    float milliseconds2 = 0;
    cudaEventElapsedTime(&milliseconds2, start2, stop2);

    std::cout<<"Time of kernel in milliseconds: "<< milliseconds2<< "ms" << std::endl;
    
    cudaMemcpy(h_out, d_C, sizeof(uint64_t), cudaMemcpyDeviceToHost);

    validate(h_C, h_out);

    cudaMemcpy(d_A, h_A, bytes, cudaMemcpyHostToDevice);

    cudaMemset(d_C, 0, sizeof(uint64_t));
	
    cudaEventRecord(start);
    aggregate_shared <<<1, 4, elementcount*sizeof(uint64_t) >>> (d_A, d_C, elementcount);
    cudaEventRecord(stop);

    cudaEventSynchronize(stop);

    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);

    std::cout<<"Time of kernel in milliseconds (shared_memory): "<< milliseconds<< "ms" << std::endl;

    cudaMemcpy(h_out, d_C, sizeof(uint64_t), cudaMemcpyDeviceToHost);

    validate(h_C, h_out);


    cudaFree(d_A);
    cudaFree(d_C);


    free(h_out);
    free(h_A);
    free(h_C);

    return 0;


    //comparison:
    //shared memory is faster than non-shared method
}
