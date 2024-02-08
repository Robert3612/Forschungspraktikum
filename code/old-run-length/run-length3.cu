#include <iostream>
#include <vector>
#include <bitset>
#include <algorithm>
#include <math.h>

std::string decode(std::string s);
int unBinary_test(std::string code);
std::string binary_test(int apperance);

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


std::string runLengthEliasGamma(std::vector<std::string> &vector, std::vector<int> &mask)
{   std::string output = "";
    for (auto i = 0; i < vector.size(); i++)
    {
        
        char letter = vector[i][0];
        int apperance = 1;
        std::string newString = "";
        std::string helper;
        int mask_helper = 0;
        for(int j=1;j<vector[i].length();j++) {
            if(letter != vector[i][j]){
                if(apperance == 1){
                mask_helper = mask_helper + 1;
                mask.push_back(mask_helper);
                newString = newString + letter;    
                letter = vector[i][j];    
                }
                else{
                 helper = binary_test(apperance);
                // std::cout<< "helper" + helper<< std::endl;
                // std::cout<< "helper_length"<< helper.length() << std::endl;
                mask_helper = mask_helper + helper.length() + 1;
                //std::cout<< mask_helper << std::endl; 
                mask.push_back(mask_helper);
                newString = newString + letter + helper;
                letter = vector[i][j];
                apperance=1;   
                }
            }
            else{
                apperance++;
            }
        }
        if(apperance == 1){
                newString = newString + letter;
                mask_helper = mask_helper ;
                mask.push_back(mask_helper);
                output = output + newString;  
                vector[i] = newString; 
                }
                else{
        helper = binary_test(apperance);
        newString = newString + letter + helper;
        mask_helper = mask_helper + helper.length() ;
        mask.push_back(mask_helper);
        output = output + newString;
        vector[i] = newString;
}
    }
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
std::string binary = std::bitset<8>(apperance).to_string();
binary.erase(0, binary.find_first_not_of('0'));

//std::cout<< binary<<std::endl;
return binary;
}

int unBinary_test(std::string code){
    int answer = std::stoi(code, nullptr, 2);
    //std::cout<< answer << std::endl;
    return answer;
}

int main()
{
    std::vector<std::string> h{"100110100001010011", "000110100001"};
    for (auto s : h)
        std::cout << s << std::endl;
    std::vector<int> mask;
    std::string decoded = runLengthEliasGamma(h, mask);
    
    for (auto s : h)
        std::cout << s << std::endl;
    std::cout<< decoded <<std::endl;
        
    for (auto i: mask)
        std::cout << i << std::endl;
    
    //std::cout<< decode(h.at(0), mask)<<std::endl;
    
    
    
}