#include <iostream>
#include <vector>
#include <bitset>
#include <algorithm>
#include <math.h>
#include <sstream>
#include <inttypes.h>
#include <fstream>
__device__ uint64_t pow10_fast(int n){
    static uint64_t pow10[20] = {
        1, 10, 100, 1000, 10000, 
        100000, 1000000, 10000000, 100000000, 
        1000000000,
        10000000000,
        100000000000,
        1000000000000,
        10000000000000,
        100000000000000,
        1000000000000000,
        10000000000000000,
        100000000000000000,
        1000000000000000000,
        10000000000000000000
    };

    return pow10[n];
}

__device__ void get_number_and_length(char *array, int* mask, int &number_length, int &number, int &helper, int i, int h){
    //printf("hallo37 %u %u %u %u %u\n", array[12], array[13], helper, i, h);
    number = array[helper] - '0';
    //printf("hallo36 %u %u %u %u\n", number_length, number, helper, i);
    int otherHelper = helper + 1;
    int numbercount = 0;
    number_length  = 0;
    int n = 0;
    while(array[otherHelper] != 'E'){
        otherHelper++;
        numbercount++;
    }
    otherHelper = helper + 1;
    helper = helper + 2 + numbercount;
    while(numbercount > 0){
        n =array[otherHelper] - '0';
        number_length = number_length + n *pow10_fast( numbercount-1);
        otherHelper++;
        numbercount--;
    }
    //printf("hallo38 %u %u %u %u %u\n", number_length, number, helper, i, h);
}
   __device__ uint64_t decode_int_no(char *array, int* mask, int i, int h)
{

    int helper = mask[i*3];
    int length = mask[i*3+1];
    uint64_t answer = 0;
    int n = 0;
    
    for(int j=length; j>0;j--){
        n = array[helper] - '0';
        answer = answer + (uint64_t) n * pow10_fast(j-1);
        helper++;
    }
    

    return answer;
}


   __device__ uint64_t decode_int(char *array, int* mask, int i, int h)
{
    //printf("hallo9 %u %u %u\n", i, h, 9);
    int helper;
    int length;
    int number_length = 0;
    uint64_t answer = 0;
    //int otherHelper = helper +1;
    int number = 0;

    helper = mask[i*3]; //0
    get_number_and_length(array, mask, number_length, number, helper, i, h);
    //printf("hallo39 %u %u %u %u\n", number_length, number, helper, i);
    //int number = array[helper]; //1
    //int numbercount = 0;
    //while(array[otherHelper] != 'E'){
      //  number_length = number_length + array[otherHelper] *pow(10, numbercount);
      //  otherHelper++;
        //numbercount++;
    //}
    //helper = helper + 2 + numbercount;
    //number_length = array[helper+1]; //1
    length = mask[i*3+1]; //3
    //printf("hallo10");
    if(length == mask[i*3+2]){// 3==1 
        for(int j=0;j< length;j++){
            answer = answer +(uint64_t) number * pow10_fast(j);
        }
        return answer;
    }else{
        for(int j = i-1;j>=0;j--){
            if(mask[j*3+2] == 0){
                break;
            }
        number_length = number_length - mask[j*3+2];
        if(mask[j*3+1] - mask[j*3+2] != 0){
            break;
        }
    }
    //printf("hallo39 %u %u %u %u %u\n", number_length, number, helper, i, h);
    //printf("hallo11 \n");
        int k=length;
        while(k>0){ //3
        //printf("hallo41 %u %u %u %u\n", number_length, number, k, i);
        //printf("hallo12 %u %u %u\n", k, length, 9);
            for(int j=0;j<number_length;j++){
                //printf("hallo13 %u %u %u\n", j, number_length, 9);
                answer = answer +(uint64_t) number * pow10_fast(k-1);
                k--;
                if(k<=0){
                    break;
                }
            }
            if(k > 0){
            //printf("hallo9 %u %u %u\n", i, h, helper);
            get_number_and_length(array, mask, number_length, number, helper, i,h);
            //printf("hallo40 %u %u %u %u %u\n", number_length, number, helper,k, i);
            //number = array[helper];
            //number_length = array[helper+1];
            }
        }
    }

    return answer;
}

__global__ 
void compare_no(char *A, char *B, int *C, int *mask_A, int *mask_B, int elementcount) {
    //printf("hallo \n");
    uint64_t a;
    uint64_t b;
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; 
         i < elementcount; 
         i += blockDim.x * gridDim.x)
    {   
        //printf("hallo5 %u %u %u\n", A[60], B[75], 2);
        a = decode_int_no(A, mask_A, i, 0);
        b = decode_int_no(B, mask_B, i, 1);

        //printf("hallo4 %u %lld %lld\n", i, a, b);
        if(a > b){
            C[i] = (int) 1;
        }
        else{
            C[i] = (int) 0;
        }
    }
    
}

__global__ 
void add(char *A, char *B, int *C, int *mask_A, int *mask_B, int elementcount) {
    //printf("hallo \n");
    uint64_t a;
    uint64_t b;
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; 
         i < elementcount; 
         i += blockDim.x * gridDim.x)
    {   
        //printf("hallo5 %u %u %u\n", A[60], B[75], 2);
        a = decode_int(A, mask_A, i, 0);
        b = decode_int(B, mask_B, i, 1);

        //printf("hallo4 %u %lld %lld\n", i, a, b);
        if(a > b){
            C[i] = (int) 1;
        }
        else{
            C[i] = (int) 0;
        }
    }
    
}


__global__
void hello_world(char *A, int *mask_A, int i)
{int a = decode_int(A, mask_A, i, 0);
 printf("Hello World From GPU!\n");
 printf ("answer: %d \n", a);
}

std::vector<uint64_t> compare_cpu(std::vector<uint64_t> a, std::vector<uint64_t> b){
    std::vector<uint64_t> C;
    for(int i=0;i<a.size();i++){
        //std::cout<<i<<", " << a.at(i)<<", "<<b.at(i)<<std::endl;
        if(a.at(i) > b.at(i)){
            C.push_back(1);
        }
        else{
            C.push_back(0);
        }
    }
    return C;
}
void encode_no(std::vector<uint64_t> start, std::vector<int> &mask, std::string &outcome){
    std::string helper = "";
    for(int i=0;i<start.size();i++){
        mask.push_back(outcome.length());
        helper = std::to_string(start.at(i));
        mask.push_back(helper.length());
        mask.push_back(0);
        outcome = outcome + helper;
    }
}

void encode2(std::vector<uint64_t> start, std::vector<int> &mask, std::string &outcome){
    //std::string input = std::to_string(start.at(0));
    std::string input = "";
    std::string input2 = "";
    for(int i=0;i<start.size();i++){
        input = input + std::to_string(start.at(i));
        input2 = input2 + std::to_string(start.at(i)) + 'A';
    }
    char helper;
    int count = 0;
    int step = 0;
    int max_count = 0;
    int test_count=0;
    mask.push_back(0);
    for(int i = 0;i<input.length();i++){
        if(input2[step]== 'A'){
            mask.push_back(max_count);
            if(input[i] != input[i-1]){
                mask.push_back(0);
            }
            else{
                mask.push_back(test_count);
            }
        }
        if(count == 0){
            helper = input[i];
            count = 1;
        }
        else{
            if(helper == input[i]){
                count++;
            }
            else{
                //if(count > 9){
                //    outcome = outcome + helper + 'A' + std::to_string(count);
                //}
                //else{
                    outcome = outcome + helper + std::to_string(count) + "E";
                //}
                helper = input[i];
                count = 1;
                test_count =0;
            }
        }
        if(input2[step]== 'A'){
            mask.push_back(outcome.length());
            max_count = 0;
            step++;
            test_count=0;
        }
        max_count++;
        step++;
        test_count++;
    }
    mask.push_back(max_count);
    mask.push_back(0);

        //if(count > 9){
          //          outcome = outcome + helper + 'B' + std::to_string(count);
            //    }
              //  else{
                    outcome = outcome + helper + std::to_string(count) + "E";
                //}
    
}


void generate2(){
    std::cout << "Werte: 7776, 66, 644, 4, 445, 648, 8822, 2"<< std::endl;
    std::cout << "input: 77766664444564888222"<< std::endl;
    std::cout << "output: 7364455161418323" << std::endl;
    std::cout << "Maske: 0,4,2,2,2,3,4,1,4,2,8,3,10,4,12,1"<< std::endl;
}

uint64_t string_to_uint64(std::string str) {
  std::stringstream stream(str);
  uint64_t result;
  stream >> result;
  return result;
}

void generate_stuff(std::vector<uint64_t> &start,int elementcount, int repeat){
    char number ='0'+ rand() % 10 ;
    int single = 0;
    int length = 0;
    std::string realnumber = "";
    int diff = repeat;
    int repeat_diff= repeat;
    for(int i=0;i<elementcount;i++){
        length = rand() % 19 + 1 ;
        single = rand() % 2;
        while(length > 0){
            if(single == 0){
                realnumber = realnumber + std::to_string(rand() % 10);
                length--;
                single = rand() %2;
            }
            else{
                diff = length - repeat_diff;
                if(diff >= 0){
                    realnumber = realnumber + std::string(repeat_diff,number );
                    length = length - repeat_diff;
                    repeat_diff = 0;
                }
                else{
                    realnumber = realnumber + std::string(length,number );
                    repeat_diff = repeat_diff - length;
                    length = 0;
                }
                if(repeat_diff <= 0){
                    repeat_diff = repeat;
                    number ='0'+ rand() % 10 ;
                }
            }
        }
        //std::cout<<realnumber<<std::endl;
        start.push_back(std::stoull(realnumber));
        realnumber = "";
    }
}

void generate_stuff2(std::vector<uint64_t> &start,int elementcount, int repeat, int length){
    char number ='0'+ rand() % 10 ;
    int single = 0;
    std::string realnumber = "";
    int reallength = length;
    while(length > 0){
        //std::cout<<length<<std::endl;
        single = rand() % 2;
        if(single == 0){
            realnumber = realnumber + std::to_string(rand() % 9 +1);
            length--;
        }
        else{
            realnumber = realnumber + std::string(repeat,number );
            length = length - repeat;
            number ='0'+ rand() % 10 ;
        }
    }
    realnumber = realnumber.substr(0,reallength);
    //std::cout << length<<std::endl;
    //std::cout << realnumber.length()<<std::endl;
    int n = realnumber.length() / elementcount;
    std::cout<<realnumber<<std::endl;
    for(int i =0;i<elementcount;i++){
        std::cout<<i<<std::endl;
        std::cout<<n<<std::endl;
        start.push_back(std::stoull(realnumber.substr(i*n,n)));
    }
}

void generate(std::vector<uint64_t> &start,int elementcount){
    
    for(int i=0;i<elementcount;i++){
        start.push_back(rand() % 1024);
    }
    
    /**
    start.push_back(988888888888888);
    start.push_back(866);
    start.push_back(666);
    start.push_back(6);
    start.push_back(666);
    start.push_back(666);
    start.push_back(8822);
    start.push_back(2);
    **/

}

void validate(std::vector<uint64_t> h, int* d) {
    for (size_t i = 0; i < h.size(); i++) {
        if (h.at(i) != d[i]) {
            std::cout << "found invalidated field in element " << i << std::endl;
            std::cout << "on CPU side: " << h.at(i) << std::endl;
            std::cout << "on GPU side: " << d[i] << std::endl;
            
            
        }
    }
}

char* to_char_array(std::string s){
    char* answer = (char*)malloc(s.length() * sizeof(char));
    for(int i=0;i<s.length();i++){
        answer[i] = s[i];
    }
    return answer;
}

int* to_int_array(std::vector<int> v){
    int* answer = (int*)malloc(v.size() * sizeof(int));
    for(int i=0;i<v.size();i++){
        answer[i] = v.at(i);
    }
    return answer;
}

void test(){

    int length = 1000000;
    int elementcount = 500000;
    
    std::ofstream myFile("run-length4.csv");
    myFile << "kernel;element_count;repeat;block_count;thread_count;time_ms;throughput;length\n";

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    for(int l = 1; l<=50;l++){
        std::cout<< "l: "<<l<<std::endl;

        std::vector<uint64_t> start_run;
        std::vector<int> mask;
        std::string outcome = "";

        std::vector<uint64_t> start_run2;
        std::vector<int> mask2;
        std::string outcome2 = "";

        generate_stuff2(start_run, elementcount, l, length);
        generate_stuff2(start_run2, elementcount, l, length);

        encode2(start_run, mask, outcome);
        encode2(start_run2, mask2, outcome2);

    char* A;
    char* d_A;
    int* mask_A;
    int* d_mask_A;
    char* B;
    char* d_B;
    int* mask_B;
    int* d_mask_B;

    int* d_C;

    int* h_out;
    size_t bytes1 = outcome.length() * sizeof(char);
    size_t bytes3 = outcome2.length() * sizeof(char);
    size_t bytes2 = mask.size() * sizeof(int);
    size_t bytes4 = mask2.size() * sizeof(int);

    h_out = (int*)malloc(elementcount*sizeof(int));

    A = (char*)malloc(bytes1);
    mask_A = (int*)malloc(bytes2);

    B = (char*)malloc(bytes3);
    mask_B = (int*)malloc(bytes4);

    cudaMalloc(&d_A, bytes1);
    cudaMalloc(&d_mask_A, bytes2);

    cudaMalloc(&d_B, bytes3);
    cudaMalloc(&d_mask_B, bytes4);

    cudaMalloc(&d_C, elementcount* sizeof(int));

    A = to_char_array(outcome);
    B = to_char_array(outcome2);


    mask_A = to_int_array(mask);
    mask_B = to_int_array(mask2);


    cudaMemcpy( d_A, A, bytes1, cudaMemcpyHostToDevice);
    cudaMemcpy( d_mask_A, mask_A, bytes2, cudaMemcpyHostToDevice);
    cudaMemcpy( d_B, B, bytes3, cudaMemcpyHostToDevice);
    cudaMemcpy( d_mask_B, mask_B, bytes4, cudaMemcpyHostToDevice);

    for(int i=16;i<=1024;i=i*2){
        std::cout<< "i: "<<i<<std::endl;
        for(int j=8;j<=512;j=j*2){
            std::cout<<"j: "<< j<<std::endl;
    cudaMemset(d_C, 0, elementcount * sizeof(int));

    cudaEventRecord(start);
    add<<<j, i>>>(d_A,d_B,d_C, d_mask_A,d_mask_B , elementcount);
    cudaEventRecord(stop);
    cudaError_t cudaerr = cudaDeviceSynchronize();
    if (cudaerr != cudaSuccess)
        printf("kernel launch failed with error \"%s\".\n",
               cudaGetErrorString(cudaerr));

    cudaMemcpy(h_out, d_C, elementcount* sizeof(int), cudaMemcpyDeviceToHost);

    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);
    
    std::vector<uint64_t> cpu = compare_cpu(start_run, start_run2);

    validate(cpu, h_out);

    uint64_t input_size = (outcome.length() + mask.size() * sizeof(int) ) + (outcome2.length() + mask2.size() * sizeof(int) );
    myFile << "no-run-length4" << ";";
    myFile << elementcount << ";";
    myFile << l << ";";
    myFile << j << ";";
    myFile << i << ";";
    myFile << milliseconds << ";";
    myFile << input_size/milliseconds/1e6 << ";";
    myFile << outcome.length() + outcome2.length() <<"\n";
      }
    }
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);
    cudaFree(d_mask_A);
    cudaFree(d_mask_B);

    free(h_out);
    }
}


int main()
{   
    test();
    /**
     std::vector<uint64_t> start;
     std::vector<int> mask;
    std::string outcome = "";

    std::vector<uint64_t> start2;
    std::vector<int> mask2;
    std::string outcome2 = "";

    int elementcount = 10;
    
    generate_stuff2(start, elementcount, 5, 20);
    generate_stuff2(start2, elementcount, 5, 20);
    for (auto i: start)
        std::cout << i << ", ";
    std::cout<<std::endl;

    for (auto i: start2)
        std::cout << i << ", ";
    std::cout<<std::endl;
    /**
    encode2(start, mask, outcome);
    encode2(start2, mask2, outcome2);
    
    std::cout << outcome << std::endl;
    
    for (auto i: mask)
        std::cout << i << ", ";
    std::cout<<std::endl;

    std::cout << outcome2 << std::endl;

    for (auto i: mask2)
        std::cout << i << ", ";
    std::cout<<std::endl;
    
    
    char* A;
    char* d_A;
    int* mask_A;
    int* d_mask_A;
    char* B;
    char* d_B;
    int* mask_B;
    int* d_mask_B;

    int* d_C;

    int* h_out;
    size_t bytes1 = outcome.length() * sizeof(char);
    size_t bytes3 = outcome2.length() * sizeof(char);
    size_t bytes2 = mask.size() * sizeof(int);
    size_t bytes4 = mask2.size() * sizeof(int);

    h_out = (int*)malloc(elementcount*sizeof(int));

    A = (char*)malloc(bytes1);
    mask_A = (int*)malloc(bytes2);

    B = (char*)malloc(bytes3);
    mask_B = (int*)malloc(bytes4);

    cudaMalloc(&d_A, bytes1);
    cudaMalloc(&d_mask_A, bytes2);

    cudaMalloc(&d_B, bytes3);
    cudaMalloc(&d_mask_B, bytes4);

    cudaMalloc(&d_C, elementcount* sizeof(int));

    A = to_char_array(outcome);
    std::cout<< "hello " << A[0] << ", " << A[1]<< std::endl;
    B = to_char_array(outcome2);
    std::cout<< "hello2 " << B[86] << ", " << B[87]<< std::endl;


    mask_A = to_int_array(mask);
    mask_B = to_int_array(mask2);


    cudaMemcpy( d_A, A, bytes1, cudaMemcpyHostToDevice);
    cudaMemcpy( d_mask_A, mask_A, bytes2, cudaMemcpyHostToDevice);
    cudaMemcpy( d_B, B, bytes3, cudaMemcpyHostToDevice);
    cudaMemcpy( d_mask_B, mask_B, bytes4, cudaMemcpyHostToDevice);
    cudaMemset(d_C, 0, elementcount * sizeof(int));

    add<<<64, 1024>>>(d_A,d_B,d_C, d_mask_A,d_mask_B , elementcount);
    cudaError_t cudaerr = cudaDeviceSynchronize();
    if (cudaerr != cudaSuccess)
        printf("kernel launch failed with error \"%s\".\n",
               cudaGetErrorString(cudaerr));

    cudaMemcpy(h_out, d_C, elementcount* sizeof(int), cudaMemcpyDeviceToHost);
    
    std::vector<uint64_t> cpu = compare_cpu(start, start2);

    validate(cpu, h_out);

    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);
    cudaFree(d_mask_A);
    cudaFree(d_mask_B);

    free(h_out);
    **/
    
}