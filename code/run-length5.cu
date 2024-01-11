#include <iostream>
#include <vector>
#include <bitset>
#include <algorithm>
#include <math.h>

std::string decode(std::string s);
int unBinary_test(std::string code);
std::string binary_test(int apperance);

template <typename T>
__global__ void decode(T* code, T* outcome,T* mask1, T* mask2, size_t elementcount1, size_t elementcount2) {
    int pos1;
    int pos2;
    size_t i = blockIdx.x * blockDim.x + threadIdx.x;
    if(i <= elementcount2/3){
        pos1 = mask2[i*3];
        pos2 = mask2[i*3+2];
        
    }
}


template <typename T>
using EnableIfIntegral = std::enable_if_t<std::is_integral<T>::value>;


template <size_t T>
class Slab
{
private:
    std::bitset<T> bitset;
    std::vector<int> valueBits;

public:
    template <size_t E>
    static std::vector<Slab<E>> packBitsets(const std::vector<std::string> &values)
    {

        auto is_too_big = [](std::string i)
        { return i.length() > T; };

        if (auto h = std::find_if(values.begin(), values.end(), is_too_big); h != values.end())
        {
            std::cout << "Error: Integers are bigger than bitset" << std::endl;
            exit(EXIT_FAILURE);
        }

        int bit_position = 0;
        auto slabs = std::vector<Slab<E>>();

        auto slab = Slab<E>();

        for (auto s : values)
        {
            if ((bit_position + s.length()) > T)
            {
                slabs.push_back(slab);
                slab = Slab<E>();
            }

            for (auto &ch : s)
            {
                slab.bitset.set(bit_position, ch == '1');
                bit_position++;
            }

            slab.valueBits.push_back(s.length());
        }

        slabs.push_back(slab);

        return slabs;
    }

    std::vector<uint64_t> unpack()
    {

        auto output = std::vector<uint64_t>();

        int start_bit = 0;
        std::string outputS;
        for (auto end_bit : valueBits)
        {
            std::string s;

            for (auto i = start_bit; i < end_bit + start_bit; i++)
            {
                auto h = bitset[i];
                if (h)
                    s.push_back('1');
                else
                    s.push_back('0');
            }
            outputS = decode(s);
            output.push_back(std::stoi(outputS, nullptr, 2));
            start_bit = end_bit;
        }

        return output;
    }
};


std::string runLengthEliasGamma(std::vector<std::string> &vector, std::vector<int> &mask, std::vector<int> &mask2)
{   std::string decoded = "";
    std::string output = "";
    int back;
    std::vector<int> helper_vector;
    helper_vector.push_back(vector[0].size()-1);
    decoded = decoded + vector[0];
    for (auto i = 1; i < vector.size(); i++)
    {
        helper_vector.push_back(helper_vector.back() + vector[i].size());
        decoded = decoded + vector[i];
    }
    
        
        char letter = decoded[0];
        int apperance = 1;
        std::string newString = "";
        std::string helper;
        int mask_helper = 0;
        int index_helper = 0;
        bool after_index = false;
        for(int j=1;j<decoded.length();j++) {
            if(letter != decoded[j]){
                if(apperance == 1){
                mask_helper = mask_helper + 1;
                mask2.push_back(mask_helper);
                newString = newString + letter;    
                letter = decoded[j];  
                }
                else{
                 helper = binary_test(apperance);
                mask_helper = mask_helper + helper.length() + 1;
                mask2.push_back(mask_helper);
                newString = newString + letter + helper;
                letter = decoded[j];
                apperance=1;   
                }
            if(after_index){
                mask.push_back(newString.length()-1);
                after_index = false;
            }
            if(helper_vector.at(index_helper)==j){
                    mask.push_back(newString.length());
                    mask.push_back(apperance);
                    index_helper++;
                    after_index = true;
            }
            }
            else{
                apperance++;
                if(helper_vector.at(index_helper)==j){
                    mask.push_back(newString.length());
                    mask.push_back(apperance);
                    index_helper++;
                    after_index = true;
            }
            }
        }

        if(apperance == 1){
                newString = newString + letter;
                mask_helper = mask_helper ;
                mask2.push_back(mask_helper);
                output = output + newString;  
                }
                else{
        helper = binary_test(apperance);
        newString = newString + letter + helper;
        mask_helper = mask_helper + helper.length() ;
        mask2.push_back(mask_helper);
        output = output + newString;
        }
        mask.push_back(newString.length()-1);
        
    
    return output;
}

int unElias(std::string code){
    if(code != ""){
    int length = code.length();
    int answer = pow(2, length);
    answer = answer + std::stoi(code, nullptr, 2);
    return answer;
    }
    return 1;
}

std::string decode(std::string s, std::vector<int> mask){
    std::string newString = "";
    std::string helper;
    char letter;
    int app_helper;
    if(mask.at(0)-1 ==0){
        newString = newString + s[0];
    }
    else{
        helper = s.substr(1,mask.at(0)-1);
        letter = s[0]; 
        app_helper = unBinary_test(helper);
        newString= newString + std::string(app_helper, letter);
    }
    //std::cout<< newString<< std::endl;
    
    for(int i=0;i<mask.size()-1;i++){
    if(mask.at(i)< mask.at(i+1)){
        
    }
    else{
        if(mask.at(i+1)-1 == mask.at(i)){
        newString = newString + s[mask.at(i)];
    }
    else{
        helper = s.substr(mask.at(i)+1,(mask.at(i+1)-1)-mask.at(i));
        letter = s[mask.at(i)]; 
        app_helper = unBinary_test(helper);
        newString= newString + std::string(app_helper, letter);
    }
    }
    }
    
    if(mask.back() == s.length()-1){
        newString = newString + s[mask.back()];
    }
    else{
        helper = s.substr(mask.back(),(s.length()-1)-mask.back());
        letter = s[mask.back()]; 
        app_helper = unBinary_test(helper);
        newString= newString + std::string(app_helper, letter);
    }
    return newString;
}

std::string binary_test(int apperance)
{
std::string binary = std::bitset<10>(apperance).to_string();
binary.erase(0, binary.find_first_not_of('0'));

//std::cout<< binary<<std::endl;
return binary;
}

int unBinary_test(std::string code){
    int answer = std::stoi(code, nullptr, 2);
    //std::cout<< answer << std::endl;
    return answer;
}

void generate(std::vector<int> &start){
    for(int i=0;i<64;i++){
        start.push_back(rand() % 1024);
    }
}

std::vector<std::string> intToBinary(std::vector<int> start, std::string &outcome){
    std::string helper = "";
    std::vector<std::string> h;
    for(int i=0;i<start.size();i++){
        helper = binary_test(start.at(i));
        outcome = outcome + helper;
        h.push_back(helper);
    }
    
    return h;
}

int main()
{
    std::vector<int> start;
    std::string outcome;
    
    generate(start);
    for (auto i: start)
        std::cout << i << ", ";
    std::vector<std::string> h;
    
    h = intToBinary(start, outcome);
    for (auto s : h)
        std::cout << s << std::endl;
    std::cout<< outcome <<std::endl;
    std::vector<int> mask;
    std::vector<int> mask2;
    std::string decoded = runLengthEliasGamma(h, mask, mask2);
    
    
    //for (auto s : h)
    //    std::cout << s << std::endl;
    std::cout<< decoded <<std::endl;
        
    for (auto i: mask)
        std::cout << i << ", ";
    std::cout << std::endl;    
    for (auto i: mask2)
        std::cout << i << ", ";
    
    //std::cout<< decode(h.at(0), mask)<<std::endl;
    
    
    
}