#include <iostream>
#include <vector>
#include <bitset>
#include <algorithm>
#include <math.h>
#include <inttypes.h>
#include <fstream>

#if __CUDA_ARCH__ < 600
__device__ uint64_t myAtomicAdd(uint64_t* address, uint64_t val)
{
    unsigned long long int* address_as_ull =
                              (unsigned long long int*)address;
    unsigned long long int old = *address_as_ull, assumed;

    do {
        assumed = old;
        old = atomicCAS(address_as_ull, assumed,
                        (uint64_t)(val +
                              (uint64_t) (assumed)));

    // Note: uses integer comparison to avoid hang in case of NaN (since NaN != NaN)
    } while (assumed != old);

    return (old);
}
#endif

__device__ 
uint64_t decode_int(uint64_t* array, int i, int number_length)
{
    int amount = 64 / number_length;
    int chunk = i/amount;
    int position = i % amount;
    uint64_t slab = array[chunk];
    uint64_t test = 1U << (uint64_t) number_length;
    uint64_t mask = test - 1;
    mask = mask << (position*number_length);
    uint64_t answer = slab & mask;
    answer = answer >> (position*number_length);
    return answer;
    
}

__device__ 
uint64_t decode_int_shared(uint64_t* array, int i, int number_length, int elementcount, int array_length)
{
    int i_real = i;
    int amount = 64 / number_length;
    int chunk = i/amount;
    int position = i % amount;
    if(i >= elementcount){
        i_real = i -elementcount;
        chunk = i_real/amount;
        chunk = chunk + array_length;
        position = i_real % amount;
    }
    uint64_t slab = array[chunk];
    //uint64_t slab = 0;
    uint64_t test = 1U << (uint64_t) number_length;
    uint64_t mask = test - 1;
    mask = mask << (position*number_length);
    uint64_t answer = slab & mask;
    answer = answer >> (position*number_length);
    
    return answer;
    
}

__device__ 
int getLength(uint64_t bits ){

    int size = 0;

    for (; bits != 0; bits >>= 1){

    size++;
    }

    return size;
}

__device__
void add_shared( uint64_t* C, uint64_t a, uint64_t b, int number_length, int i, int elementcount, int array_length){

    uint64_t c = a +b;

    //printf("wow3, %u %lld\n", i,(unsigned long long int) c);

    if(getLength(c)<=number_length){

        int amount = 64 / number_length;


        int i_real = i - 2*elementcount;
        int chunk = i_real/amount;
        chunk = chunk + array_length*2;
        int position = i_real % amount;

        c = c << (position*number_length);
        printf("wow3, %u %lld\n", i,(unsigned long long int) c);

        myAtomicAdd(&C[chunk], c);
    }

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
void compare_shared(uint64_t* C, int a, int b, int number_length, int i, int elementcount, int array_length){
    if(a > b){
        uint64_t helper = 0;
        int amount = 64 / number_length;

        int i_real = i - 2*elementcount;
        int chunk = i_real/amount;
        chunk = chunk + array_length*2;
        int position = i_real % amount;
        helper = 1;
        helper = helper << (position*number_length);
        myAtomicAdd(&C[chunk],helper);
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
void rand_gpu(uint64_t* A, uint64_t* B , int n, int elementcount)
{
 printf("Hello World From GPU!\n");
}

__global__ 
void zero_sup_no(uint64_t* A, uint64_t* B, int number_length_A,int number_length_B, int array_length,int elementcount,  uint64_t* C){
    uint64_t a;
    uint64_t b;
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; 
         i < elementcount; 
         i += blockDim.x * gridDim.x)
    {
        
        a = decode_int(A, i, number_length_A);
        b = decode_int(B, i,number_length_B);

        add(C, a, b, number_length_A, i);



    }
}

__global__ 
void no_zero(uint64_t* A, uint64_t* B,int number_length_A, int elementcount, uint64_t* C){
    uint64_t c;
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; 
         i < elementcount; 
         i += blockDim.x * gridDim.x)
    {
        
        c = A[i] + B[i];
        
        if(getLength(c) <= number_length_A){
            C[i] = c;
        }
        else{
            C[i] = 0;
        }/**
        if(A[i] > B[i]){
            C[i] = 1;
        }
        else{
            C[i] = 0;
        }
            **/

    }
}

//3250, 6500
__global__ 
void zero_sup_yes(uint64_t* A, uint64_t* B, int number_length, int array_length,int elementcount, uint64_t* C){
    extern __shared__ uint64_t shared_mem[];
    int n = (array_length + (1500 - 1)) / 1500;
    int amount = 64 / number_length;
    //int n = array_length / 1500;
    int length = 1500;
    int ele = amount*1500;
    //printf("wow, %u \n", n);
    for(int j = 0;j<n-1;j++){
        

       // printf("wow4,%u %u %u %u %u\n",j, n, length, ele, elementcount);
    for (int i = threadIdx.x; i < length; i += blockDim.x )
    {
        //if(i==0){
          //  printf("wow3, %u %lld %lld\n", i,(unsigned long long int) A[i], (unsigned long long int) B[i]);
        //}
        //printf("wow, %u %u %u\n", i, i+ array_length, array_length);
       // printf("wow, %u %u %u\n", i, A[i], B[i]);
         //printf("wow, %lld %lld\n", (unsigned long long) A[i], (unsigned long long) B[i]);
        //printf("wow2, %u %u %u\n", i, elementcount, array_length);
        shared_mem[i] = A[i+length*j];
        shared_mem[i+length] = B[i+length*j];
        //shared_mem[10000] = 3;
    }
   
   //printf("wow3,%u %u %u %u %u\n",j, n, length, ele, elementcount);
    
    __syncthreads();
    //printf("wow4, %u %u %u %u\n", n, length, ele, elementcount);
    uint64_t a;
    uint64_t b;
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; 
         i < ele; 
         i += blockDim.x * gridDim.x)
    {
        a = decode_int_shared(shared_mem, i, number_length, ele, length);
        b = decode_int_shared(shared_mem, i+ele,number_length, ele, length);
        //printf("wow2, %lld %lld\n", a, b);
        add(C, a, b, number_length, i+ele*j);

    }
    __syncthreads();
    }
    __syncthreads();
    length = array_length - (n-1)*1500;
    ele = elementcount - amount*1500*(n-1);
    //printf("wow4,%u %u %u %u %u\n",array_length, n, length, ele, elementcount);
    for (int i = threadIdx.x; i < length; i += blockDim.x )
    {
        //if(i==0){
          //  printf("wow3, %u %lld %lld\n", i,(unsigned long long int) A[i], (unsigned long long int) B[i]);
        //}
        //printf("wow, %u %u %u\n", i, i+ array_length, array_length);
       // printf("wow, %u %u %u\n", i, A[i], B[i]);
         //printf("wow, %lld %lld\n", (unsigned long long) A[i], (unsigned long long) B[i]);
        //printf("wow2, %u %u %u\n", i, elementcount, array_length);
        shared_mem[i] = A[i+1500*(n-1)];
        shared_mem[i+length] = B[i+1500*(n-1)];
        //shared_mem[10000] = 3;
    }
   
   //printf("wow3, %u %u %u %u\n", n, length, ele, elementcount);
    
    __syncthreads();
    //printf("wow4, %u %u %u %u\n", n, length, ele, elementcount);
    uint64_t a;
    uint64_t b;
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; 
         i < ele; 
         i += blockDim.x * gridDim.x)
    {
        a = decode_int_shared(shared_mem, i, number_length, ele, length);
        b = decode_int_shared(shared_mem, i+ele,number_length, ele, length);
        //printf("wow2, %lld %lld\n", a, b);
        add(C, a, b, number_length, i+amount*1500*(n-1));

    }
    __syncthreads();
    

}

//252, 65
__global__ 
void zero_sup_yes2(uint64_t* A, uint64_t* B, int number_length, int array_length,int elementcount,  uint64_t* C){
    extern __shared__ uint64_t shared_mem[];

    int n = (array_length + (63 - 1)) / 63;
    int amount = 64 / number_length;
    //int n = array_length / 1500;
    int length = 63;
    int ele = amount*63;

    for(int j = 0;j<n-1;j++){

    for (int i = threadIdx.x; i < length; i += blockDim.x)
    {
        shared_mem[i] = A[i+length*j];
        shared_mem[i+length] = B[i+length*j];
        shared_mem[i+2*length] = 0;

    }
    __syncthreads();
    uint64_t a;
    uint64_t b;
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; 
         i < ele; 
         i += blockDim.x * gridDim.x)
    {
        a = decode_int_shared(shared_mem, i, number_length, ele, length);
        b = decode_int_shared(shared_mem, i+ele,number_length, ele, length);
        //printf("wow4, %u %u\n", i, i+2*ele);
        add_shared(shared_mem, a, b, number_length, i+2*ele,  ele, length);

    }
    printf("wow4,%u %u %u %u %u\n",j, n, length, ele, elementcount);
    __syncthreads();
    for (int i = threadIdx.x; i < length; i += blockDim.x)
    {
        C[i+length*j] = shared_mem[i+2*length];

    }
    __syncthreads();
    }

    __syncthreads();
    length = array_length - (n-1)*63;
    ele = elementcount - amount*63*(n-1);
    //printf("wow4,%u %u %u %u %u\n",5, n, length, ele, elementcount);

    for (int i = threadIdx.x; i < length; i += blockDim.x)
    {
        shared_mem[i] = A[i+63*(n-1)];
        shared_mem[i+length] = B[i+63*(n-1)];
        shared_mem[i+2*length] = 0;

    }
    __syncthreads();
    int a;
    int b;
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; 
         i < ele; 
         i += blockDim.x * gridDim.x)
    {
        a = decode_int_shared(shared_mem, i, number_length, ele, length);
        b = decode_int_shared(shared_mem, i+ele,number_length, ele, length);
        printf("wow3, %u %u\n", i,i+2*ele);
        add_shared(shared_mem, a, b, number_length, i+2*ele,  ele, length);

    }
    __syncthreads();
    for (int i = threadIdx.x; i < length; i += blockDim.x)
    {
        printf("wow4, %u %lld\n", i,shared_mem[i+2*length]);
        C[i+63*(n-1)] = shared_mem[i+2*length];

    }
    __syncthreads();
}

uint64_t getLength_cpu(uint64_t bits ){
    uint64_t size = 0;

    for (; bits != 0; bits >>= 1)
    size++;


    return size;
}

std::vector<uint64_t> add_cpu(std::vector<uint64_t> a, std::vector<uint64_t> b, int element_length){
    uint64_t c;
    std::vector<uint64_t> C;
    for(int i=0;i<a.size();i++){
        c = a.at(i) + b.at(i);
        //if(i == 1){
          //  std::cout<<"heute, hier: "<<a.at(i) <<std::endl;
            //std::cout<<"heute, hier: "<<b.at(i) <<std::endl;
        //}
        if(getLength_cpu(c) <= element_length){
            C.push_back(c);
        }
        else{
            C.push_back(0);
        }
    }
    return C;
}

std::vector<uint64_t> compare_cpu(std::vector<uint64_t> a, std::vector<uint64_t> b){
    std::vector<uint64_t> C;
    for(int i=0;i<a.size();i++){
        //if(i == 0){
            //std::cout<<"heute, hier: "<<a.at(i) <<std::endl;
          //  std::cout<<"heute, hier: "<<b.at(i) <<std::endl;
        //}
        if(a.at(i) > b.at(i)){
            C.push_back(1);
        }
        else{
            C.push_back(0);
        }
    }
    return C;
}

std::vector<std::string> int_to_string(std::vector<uint64_t> v){
    std::vector<std::string> s;
    for(int i=0;i<v.size();i++){
        s.push_back(std::bitset< 64 >(v.at(i)).to_string());
    }
    return s;
}

std::vector<uint64_t> string_to_int(std::vector<std::string> s){
    uint64_t helper;
    std::vector<uint64_t> v;
    for(int i=0;i<s.size();i++){
        helper = (uint64_t) std::bitset< 64 >(s.at(i)).to_ulong();
        v.push_back(helper);
        
    }
    return v;
}


struct Slabs{
    int array_length;
    int number_length;
    uint64_t* array;
};


Slabs encode(std::vector<std::string> vector){
    std::vector<uint64_t> helper_array;
    int length = vector.at(1).size();
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

std::vector<uint64_t> decode(uint64_t* numbers, int number_length, int array_length){
    int amount = 64 / number_length;
    uint64_t mask = pow(2,number_length) -1;
    uint64_t slab;
    uint64_t answer;
    std::vector<uint64_t> decoded_numbers;
    for(int i =0;i<array_length;i++){
        slab = numbers[i];
        for(int j =0;j<amount;j++){
            mask = pow(2,number_length) -1;
            mask = mask << (j*number_length);
            answer = slab & mask;
            answer = answer >> (j*number_length);
            decoded_numbers.push_back(answer);
        }
    }
    return decoded_numbers;
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

void validate(std::vector<uint64_t> h, std::vector<uint64_t> d) {
    for (size_t i = 0; i < h.size(); i++) {
        if (h.at(i) != d.at(i)) {
            
           std::cout << "found invalidated field in element " << i << std::endl;
           std::cout << "on CPU side: " << h.at(i) << std::endl;
           std::cout << "on GPU side: " << d.at(i) << std::endl;
           /**
           std::cout << "on CPU side: " << j << std::endl;
           std::cout << "on GPU side: " << k << std::endl;
           std::cout << "on GPU side: " << l << std::endl;
            */
            
        }
    }
}

void generate(std::vector<uint64_t> &a, std::vector<uint64_t> &b , int n, int elementcount){
    int number = pow(2,n) -1;
    for(int i=0;i<elementcount;i++){
        a.push_back((uint64_t) rand() % number + 1);
        b.push_back((uint64_t) rand() % number + 1);
    }
}

void test(){
    //size_t elementcount=1048576;
    //96000
    //1000
    //size_t elementcount=134217728;
    //67108864
    //size_t elementcount=1000000;
    size_t elementcount=6500;
    //int length=8;
    //std::ofstream myFile("no_shared.csv");
    std::ofstream myFile("shared2_add2.csv");
    myFile << "kernel;element_count;bit_count;block_count;thread_count;time_ms;throughput\n";

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    for(int l = 1; l<=64;l++){
        std::cout<< "l: "<<l<<std::endl;
    std::vector<uint64_t> a;
    std::vector<uint64_t> b;

    generate(a, b, l, elementcount);

    std::vector<std::string> h = int_to_string(a);
    std::vector<std::string> h2 = int_to_string(b);

    removeLeadingZeros(h);
    removeLeadingZeros(h2);

    
    Slabs s = encode(h);
    Slabs s2 = encode(h2);


    uint64_t* d_A;
    uint64_t* d_B;
    uint64_t* d_C;


    uint64_t* h_out;

    size_t bytes = s.array_length * sizeof(uint64_t);
    size_t bytes2 = s.array_length * sizeof(unsigned long long int);
    h_out = (uint64_t*)malloc(bytes);

    cudaMalloc(&d_A, bytes);
    cudaMalloc(&d_B, bytes);
    cudaMalloc(&d_C, bytes2);

    cudaMemcpy(d_A, s.array, bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, s2.array, bytes, cudaMemcpyHostToDevice);
    

    
    for(int i=16;i<=1024;i=i*2){
        std::cout<< "i: "<<i<<std::endl;
        for(int j=8;j<=512;j=j*2){
            std::cout<<"j: "<< j<<std::endl;
            cudaMemset(d_C, 0, bytes2);

            cudaFuncSetCacheConfig(zero_sup_yes, cudaFuncCachePreferShared);
            
            //zero_sup_no<<<j, i >>>(d_A, d_B, s.number_length,h.size(),  d_C);
            //zero_sup_no<<<j, i>>>(d_A, d_B, s.number_length,s.number_length, s.array_length,h.size(),  d_C);
            if(3*s.array_length*sizeof(uint64_t) > 1512){
                cudaEventRecord(start);
            zero_sup_yes2<<<j, i, 1512>>>(d_A, d_B, s.number_length, s.array_length,h.size(),  d_C);
            cudaEventRecord(stop);
            }
            else{
            cudaEventRecord(start);
            zero_sup_yes2<<<j, i, 3*s.array_length*sizeof(uint64_t)>>>(d_A, d_B, s.number_length, s.array_length,h.size(),  d_C);
            cudaEventRecord(stop);
            }
            //zero_sup_yes<<<j, i, 2*s.array_length*sizeof(uint64_t)>>>(d_A, d_B, s.number_length, s.array_length,h.size(),  d_C);
            
    
            cudaMemcpy(h_out, d_C, bytes, cudaMemcpyDeviceToHost);

            cudaEventSynchronize(stop);

            float milliseconds = 0;
            cudaEventElapsedTime(&milliseconds, start, stop);

            int max_number_length;
            int max_array_length;
            if(s.number_length> s2.number_length){
            max_number_length = s.number_length;
            max_array_length = s.array_length;
        }
        else{
            max_number_length = s2.number_length;
            max_array_length = s2.array_length;
        }

        std::vector<uint64_t> decoded_numbers = decode(h_out, max_number_length, max_array_length);
        std::vector<uint64_t> c = add_cpu(a,b, max_number_length);
        //std::vector<uint64_t> c = compare_cpu(a,b);

        //validate(c, decoded_numbers, j, i, l);

            myFile << "no_shared2" << ";";
            myFile << elementcount << ";";
            myFile << l << ";";
            myFile << j << ";";
            myFile << i << ";";
            myFile << milliseconds << ";";
            myFile << s.array_length*8*2/milliseconds/1e6 << "\n";
        }
    }
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);

    free(h_out);
    }

    
}

void test2(){
    //size_t elementcount=1048576;
    //96000
    //1000
    size_t elementcount=1000000;
    //int length=8;
    //std::ofstream myFile("no_shared.csv");
    std::ofstream myFile("no_zero_add3.csv");
    myFile << "kernel;element_count;bit_count;block_count;thread_count;time_ms;throughput\n";

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    for(int l = 1; l<=64;l++){
        std::cout<< "l: "<<l<<std::endl;
    std::vector<uint64_t> a;
    std::vector<uint64_t> b;

    generate(a, b, l, elementcount);
    size_t bytes = elementcount * sizeof(uint64_t);
    size_t bytes2 = elementcount * sizeof(unsigned long long int);

    std::vector<std::string> h = int_to_string(a);
    std::vector<std::string> h2 = int_to_string(b);

    removeLeadingZeros(h);
    removeLeadingZeros(h2);

    
    Slabs s = encode(h);
    Slabs s2 = encode(h2);
    uint64_t* h_A;
    uint64_t* h_B;

    h_A = (uint64_t*)malloc(bytes);
    h_B = (uint64_t*)malloc(bytes);
    for(int i = 0;i<a.size();i++){
        h_A[i] = a.at(i);
        h_B[i] = b.at(i);
    }


    uint64_t* d_A;
    uint64_t* d_B;
    uint64_t* d_C;


    uint64_t* h_out;

    
    h_out = (uint64_t*)malloc(bytes);

    cudaMalloc(&d_A, bytes);
    cudaMalloc(&d_B, bytes);
    cudaMalloc(&d_C, bytes2);

    cudaMemcpy(d_A, h_A, bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, bytes, cudaMemcpyHostToDevice);
    

    
    for(int i=16;i<=1024;i=i*2){
        std::cout<< "i: "<<i<<std::endl;
        for(int j=8;j<=512;j=j*2){
            std::cout<<"j: "<< j<<std::endl;
            cudaMemset(d_C, 0, bytes2);
	
            cudaEventRecord(start);
            no_zero<<<j, i >>>(d_A, d_B, s.number_length,h.size(),  d_C);
            cudaEventRecord(stop);
    
            cudaMemcpy(h_out, d_C, bytes, cudaMemcpyDeviceToHost);

            cudaEventSynchronize(stop);

            float milliseconds = 0;
            cudaEventElapsedTime(&milliseconds, start, stop);

            int max_number_length;
            //int max_array_length;
            if(s.number_length> s2.number_length){
            max_number_length = s.number_length;
            //max_array_length = s.array_length;
        }
        else{
            max_number_length = s2.number_length;
            //max_array_length = s2.array_length;
        }

        //std::vector<uint64_t> decoded_numbers = decode(h_out, max_number_length, max_array_length);
        std::vector<uint64_t> c = add_cpu(a,b, max_number_length);
        //std::vector<uint64_t> c = add_cpu(a,b);
        std::vector<uint64_t> decoded_numbers;
        for(int s=0;s<a.size();s++){
            decoded_numbers.push_back(h_out[s]);
        }

        //validate(c, decoded_numbers);

            myFile << "no_shared" << ";";
            myFile << elementcount << ";";
            myFile << l << ";";
            myFile << j << ";";
            myFile << i << ";";
            myFile << milliseconds << ";";
            myFile << elementcount*8*2/milliseconds/1e6 << "\n";
        }
    }
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);

    free(h_out);
    }

    
}

int main()
{   
    //test();
    
    std::vector<uint64_t> a;
    std::vector<uint64_t> b;

    generate(a, b,2, 20);
    for(uint64_t i:a)
        std::cout<<i<<", ";

    std::cout<<std::endl;

    for(uint64_t i:b)
        std::cout<<i<<", ";
    //std::vector<std::string> h{"00000110000100000000", "110010100000000", "1100000000", "110001100000000", "110101100000001", "110001000000000", "100000100000000", "110101100010000"};
    //std::vector<std::string> h2{"001000100000001", "10010100000001", "10010100000001", "10001100000001", "10101100000000", "10001000000001", "100000100000001", "110101100100001"};
    std::vector<std::string> h = int_to_string(a);
    std::vector<std::string> h2 = int_to_string(b);

    removeLeadingZeros(h);
    removeLeadingZeros(h2);

    //std::vector<uint64_t> a = string_to_int(h);
    //std::vector<uint64_t> b = string_to_int(h2);
    
    Slabs s = encode(h);
    Slabs s2 = encode(h2);


    uint64_t* d_A;
    uint64_t* d_B;
    uint64_t* d_C;


    uint64_t* h_out;

    size_t bytes = s.array_length * sizeof(uint64_t);
    size_t bytes2 = s.array_length * sizeof(unsigned long long int);

    std::cout << bytes<<std::endl;
        std::cout<< bytes2<<std::endl;
    h_out = (uint64_t*)malloc(bytes);

    cudaMalloc(&d_A, bytes);
    cudaMalloc(&d_B, bytes);
    cudaMalloc(&d_C, bytes2);

    cudaMemcpy(d_A, s.array, bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, s2.array, bytes, cudaMemcpyHostToDevice);
    //for(int i=0;i<s.array_length;i++){
      //  std::cout<< i <<", " << s.array[i]<<std::endl;
        //std::cout<< i <<", " << s2.array[i]<<std::endl;
    //}
    cudaMemset(d_C, 0, bytes2);
    //2*s.array_length*sizeof(uint64_t)
    //64, 1024, 3*s.array_length*sizeof(uint64_t)
    std::cout<<"hello "<< 3*s.array_length*sizeof(uint64_t)<<std::endl;
    std::cout<<"hello "<< sizeof(uint64_t)<<std::endl;
    //cudaFuncSetAttribute(zero_sup_yes2, cudaFuncAttributeMaxDynamicSharedMemorySize, 65536);
   // if(2*s.array_length*sizeof(uint64_t) > 24000){
   //     zero_sup_yes<<<64, 1024, 24000>>>(d_A, d_B, s.number_length, s.array_length,h.size(),  d_C);
   // }
   // else{
    //    std::cout<<"hier"<<std::endl;
    zero_sup_yes2<<<256, 16, 3*s.array_length*sizeof(uint64_t)>>>(d_A, d_B, s.number_length, s.array_length,h.size(),  d_C);
    //}
    
    //zero_sup_no<<<64, 1024>>>(d_A, d_B, s.number_length,s.number_length, s.array_length,h.size(),  d_C);
    //hello_world<<<1, 1>>>();
    cudaError_t cudaerr = cudaDeviceSynchronize();
    if (cudaerr != cudaSuccess)
        printf("kernel launch failed with error \"%s\".\n",
               cudaGetErrorString(cudaerr));


    cudaMemcpy(h_out, d_C, bytes, cudaMemcpyDeviceToHost);

    int max_number_length;
    int max_array_length;
    if(s.number_length> s2.number_length){
        max_number_length = s.number_length;
        max_array_length = s.array_length;
    }
    else{
        max_number_length = s2.number_length;
        max_array_length = s2.array_length;
    }
    std::vector<uint64_t> decoded_numbers = decode(h_out, max_number_length, max_array_length);

    std::vector<uint64_t> c = add_cpu(a,b, max_number_length);

    validate(c, decoded_numbers);


    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);

    free(h_out);
    
    
    
}