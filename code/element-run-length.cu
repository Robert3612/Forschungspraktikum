#include <iostream>
#include <vector>
#include <bitset>
#include <algorithm>
#include <math.h>

   __device__ int decode_int(int *array, int* mask, int i)
{
    int helper;
    int length;
    int char_length;
    int pre_length;
    char helper_array[10];
    int answer = 0;
    int stelle = 0;

    helper = mask_A[i*3];
    int number = A[helper];
    char_length = A[helper+1];
    length = mask_A[i*3+1];
    pre_length = mask_A[i*3-2] - mask_A[i*3-1];
    if(length == mask_A[i*3+2]){
        for(int i=0;i< length;i++){
            answer = answer + number * pow(10,i);
        }
    }else{
        if(pre_length > 0){
            char_length = char_length - pre_length;
        }
        while(length> 0){
            answer = answer + number * pow(10, stelle);


        }
    }

    return answer;
}




__global__ 
void add(int *A, int *B, int *C, int *mask_A, int *mask_B,int length_A, int length_B, int elementcount) {
    int a;
    int b;
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; 
         i < elementcount; 
         i += blockDim.x * gridDim.x)
    {
        a = decode_int(A, mask_A, i);
        b = decode_int(B, mask_B, i);

        C[i] = a + b;
    }
    __syncthreads();
    if(id == 0){
    encode(C);
    }
}


__global__
void hello_world()
{
 printf("Hello World From GPU!\n");
}

void encode(std::vector<int> start, std::vector<int> &mask, std::string &outcome){
    std::string input = std::to_string(start.at(0));
    std::vector<int> length;
    length.push_back(std::to_string(start.at(0)).length());
    std::vector<int> pos;
    pos.push_back(std::to_string(start.at(0)).size()-1);
    for(int i=1;i<start.size();i++){
        input = input + std::to_string(start.at(i));
        length.push_back(std::to_string(start.at(i)).length());
        pos.push_back(pos.back() + std::to_string(start.at(i)).length());
    }
    
    char letter = input[0];
    int apperance = 1;
    int length_index = 0;
    int length_helper = length.at(length_index);
    int pos_index = 0;
    mask.push_back(0);
    mask.push_back(length_helper);
    bool again = false;
    for(int i=1;i<input.length();i++){
        if(letter != input[i]){
            length_helper = length_helper - apperance;
            while(length_helper < 0){
                if(again){
                    mask.push_back(length.at(length_index) +100);
                }
                length_index++;
                mask.push_back(outcome.length());
                mask.push_back(length.at(length_index));
                length_helper = length_helper + length.at(length_index);
                again = true;
            }
            again = false;
            outcome = outcome + letter + std::to_string(apperance);
            letter = input[i];
            apperance = 1;
            if(pos.at(pos_index)==i){
                    mask.push_back(apperance +100);
                    pos_index++;
            }
        }
        else{
            apperance++;
            //std::cout<< i<< std::endl;
            //std::cout<< pos.at(pos_index)<< std::endl;
            if(pos.at(pos_index)==i){
                if(length.at(pos_index) > apperance){
                    mask.push_back(apperance+100);
                }
                pos_index++;
            }
        }
    }
            std::cout<< length_helper<<std::endl;
            std::cout<< apperance<<std::endl;
            length_helper = length_helper - apperance;
            while(length_helper < 0){
                if(again){
                    mask.push_back(length.at(length_index) +100);
                }
                length_index++;
                mask.push_back(outcome.length());
                mask.push_back(length.at(length_index));
                length_helper = length_helper + length.at(length_index);
                if(length_helper == 0){
                    mask.push_back(length.at(length_index) +100);
                }
                again = true;
            }
            again = false;
            outcome = outcome + letter + std::to_string(apperance);
}




void generate2(){
    std::cout << "Werte: 7776, 66, 644, 4, 445, 648, 8822, 2"<< std::endl;
    std::cout << "input: 77766664444564888222"<< std::endl;
    std::cout << "output: 7364445161418323" << std::endl;
    std::cout << "Maske: 0,4,2,2,2,3,4,1,4,2,8,3,10,4,12,1"<< std::endl;
}


void generate(std::vector<int> &start){
    for(int i=0;i<10;i++){
        start.push_back(rand() % 1024);
    }
}


int main()
{
     std::vector<int> start;
     std::vector<int> mask;
    std::string outcome = "";
    
    generate(start);
    for (auto i: start)
        std::cout << i << ", ";
    std::cout<<std::endl;
    
    encode(start, mask, outcome);
    
    std::cout << outcome << std::endl;
    for (auto i: mask)
        std::cout << i << ", ";
 
    
    hello_world<<<1, 1>>>();
    cudaDeviceReset();
    
    
    
    
    
}