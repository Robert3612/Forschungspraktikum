#include <iostream>
#include <vector>
#include <bitset>
#include <algorithm>
#include <math.h>

#if __CUDA_ARCH__ < 600
__device__ uint64_t myAtomicAdd(uint64_t* address, uint64_t val)
{
    unsigned long long int* address_as_ull =
                              (unsigned long long int*)address;
    unsigned long long int old = *address_as_ull, assumed;

    do {
        assumed = old;
        old = atomicCAS(address_as_ull, assumed,
                        (unsigned long long int)(val +
                              (uint64_t) (assumed)));

    // Note: uses integer comparison to avoid hang in case of NaN (since NaN != NaN)
    } while (assumed != old);

    return (old);
}
#endif

__device__ uint64_t decode_int(uint64_t* array, int i, int number_length)
{
    int amount = 64 / number_length;
    int chunk = i/amount;
    int position = i % amount;
    printf("int, %u %u %u %u %u\n", i, number_length, amount, chunk, position);
    uint64_t slab = array[chunk];
    uint64_t mask = pow(2,number_length) -1;
    mask = mask << (position*number_length);
    uint64_t answer = slab & mask;
    answer = answer >> (position*number_length);
    return answer;
    
}

__device__ 
int getLength(int bits ){
    int size = 0;

    for (; bits != 0; bits >>= 1)
    size++;
    printf("i, %d \n", size);
    return size;
}

__device__
void add( uint64_t* C, uint64_t a, uint64_t b, int number_length, int i){
    uint64_t c = a +b;
    if(getLength(c)<=number_length){
        int amount = 64 / number_length;
        int chunk = i/amount;
        int position = i % amount;  
        c = c << (position*number_length);
        myAtomicAdd(&C[chunk], c);
    }
}

__device__
void compare(uint64_t* C, int a, int b, int number_length, int i){
    if(a > b){
        uint64_t helper = 0;
        int amount = 64 / number_length;
        int chunk = i/amount;
        int position = i % amount;
        helper = 1;
        helper = helper << (position*number_length);
        myAtomicAdd(&C[chunk],helper);
    }
}

__global__
void hello_world()
{
 printf("Hello World From GPU!\n");
}

__global__ 
void zero_sup_no(uint64_t* A, uint64_t* B, int number_length, int array_length,int elementcount,  uint64_t* C){
    printf("hallo24324");
    uint64_t a;
    uint64_t b;
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; 
         i < elementcount; 
         i += blockDim.x * gridDim.x)
    {
        a = decode_int(A, i, number_length);
        b = decode_int(B, i,number_length);
        printf("a, %d \n", a);
        printf("b, %d \n", b);
        printf("hallo");
        compare(C, a, b, number_length, i);

    }
}

__global__ 
void zero_sup_yes(uint64_t* A, uint64_t* B, int number_length, int array_length,int elementcount, uint64_t* C){
    extern __shared__ uint64_t shared_mem[];
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; 
         i < array_length; 
         i += blockDim.x * gridDim.x)
    {
        printf("wow, %u %u \n", i, i+ array_length);
        shared_mem[i] = A[i];
        shared_mem[i+array_length] = B[i];

    }
    __syncthreads();
    int a;
    int b;
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; 
         i < elementcount; 
         i += blockDim.x * gridDim.x)
    {
        a = decode_int(shared_mem, i, number_length);
        b = decode_int(shared_mem, i+elementcount,number_length);
        printf("i, %u %u %u \n", i, a, b);
        add(C, a, b, number_length, i);

    }
}


__global__ 
void zero_sup_yes2(uint64_t* A, uint64_t* B, int number_length, int array_length,int elementcount,  uint64_t* C){
    extern __shared__ uint64_t shared_mem[];
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; 
         i < array_length; 
         i += blockDim.x * gridDim.x)
    {
        shared_mem[i] = A[i];
        shared_mem[i+array_length] = B[i];
        shared_mem[i+2*array_length] = 0;

    }
    __syncthreads();
    int a;
    int b;
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; 
         i < elementcount; 
         i += blockDim.x * gridDim.x)
    {
        a = decode_int(shared_mem, i, number_length);
        b = decode_int(shared_mem, i+elementcount,number_length);
        compare(shared_mem, a, b, number_length, i+2*elementcount);

    }
    __syncthreads();
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; 
         i < array_length; 
         i += blockDim.x * gridDim.x)
    {
        C[i] = shared_mem[i+2*array_length];

    }
}


struct Slabs{
    int array_length;
    int number_length;
    uint64_t* array;
};


Slabs encode(std::vector<std::string> vector){
    std::vector<uint64_t> helper_array;
    int length = vector.at(0).size();
    int size = 64 / length;
    uint64_t slab = 0;
    uint64_t helper = 0;
    int position = 0;
    Slabs s;
    s.number_length = length;

    for(std::string number:vector){
        helper = (uint64_t) (std::bitset<64>(number)).to_ulong();
        helper = helper << (position*length);
        slab = slab + helper;
        position++;
        if(position == size){
            position = 0;
            helper_array.push_back(slab);
            slab = 0;
        }
    }
    if(slab != 0){
       helper_array.push_back(slab); 
    }

    uint64_t* answer = (uint64_t*)malloc(helper_array.size() * sizeof(uint64_t));
    for(int i=0;i< helper_array.size();i++){
        answer[i] = helper_array.at(i);
    }
    s.array_length = helper_array.size();
    s.array = answer;
    return s;

}


void removeLeadingZeros(std::vector<std::string> &vector)
{
    int length;
    int max = 0;
    for (auto i = 0; i < vector.size(); i++)
    {
        length = vector[i].size() - vector[i].find('1');
        if(length > max){
            max = length;
        }
    }
    if( max == 0){
        return;
    }
    for(auto i = 0; i < vector.size(); i++){
        if(vector[i].size() > max){
        vector[i].erase(0, vector[i].size() - max);
        }
        else{
            vector[i].insert(0, max - vector[i].size(), '0');
        }
    }
}

int main()
{

    std::vector<std::string> h{"00000110000100000000", "110010100000000", "0100000000", "110001100000000", "010101100000001", "010001000000000", "100000100000000", "010101100010000"};
    std::vector<std::string> h2{"0010000100000001", "0000010100000001", "0000010100000001", "0000001100000001", "0010101100000000", "0010001000000001", "0100000100000001", "110101100100001"};

    removeLeadingZeros(h);
    removeLeadingZeros(h2);

    for(auto i = 0; i < h.size(); i++){
        //std::cout<< h[i] << std::endl;
        std::cout<< h2[i] << std::endl;
    }

    
    Slabs s = encode(h);
    Slabs s2 = encode(h2);
    for(int i=0;i<s.array_length;i++){
        std::cout<< std::bitset<64>(s.array[i]) << std::endl;
        std::cout<< std::bitset<64>(s2.array[i]) << std::endl;
    }


    uint64_t* d_A;
    uint64_t* d_B;
    uint64_t* d_C;


    uint64_t* h_out;

    size_t bytes = s.array_length * sizeof(uint64_t);
    size_t bytes2 = s.array_length * sizeof(unsigned long long int);
    std::cout<< "wow" <<std::endl;
    std::cout<< bytes <<std::endl;
    std::cout<< bytes2 <<std::endl;
    h_out = (uint64_t*)malloc(bytes);

    cudaMalloc(&d_A, bytes);
    cudaMalloc(&d_B, bytes);
    cudaMalloc(&d_C, bytes2);

    cudaMemcpy(d_A, s.array, bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, s2.array, bytes, cudaMemcpyHostToDevice);

    cudaMemset(d_C, 0, bytes2);

    //2*s.array_length*sizeof(uint64_t)
    //64, 1024, 3*s.array_length*sizeof(uint64_t)
    //zero_sup_no<<<64, 1024>>>(d_A, d_B, s.number_length, s.array_length,h.size(),  d_C);
    hello_world<<<1, 1>>>();
    cudaDeviceReset();


    cudaMemcpy(h_out, d_C, bytes, cudaMemcpyDeviceToHost);

    for(int i=0;i<s.array_length;i++){
        std::cout<< "hello" <<std::endl;
        std::cout<< std::bitset<64>(h_out[i]) << std::endl;
    }


    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);

    free(h_out);
}