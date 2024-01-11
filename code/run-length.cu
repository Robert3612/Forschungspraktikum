#include <iostream>
#include <vector>
#include <bitset>
#include <algorithm>
#include <math.h>

std::string decode(std::string s);
int unElias(std::string code);

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

std::string EliasGamma(int apperance)
{
    int x = apperance;
    int y;
    std::string answer = "";

do {
    y = x;
    x = x&(x-1);
}while(x);

int result = log2 (y);

for(int i =0; i< result;i++){
    answer = answer + "0";
}
answer = answer + "1";

int rest = apperance - y;

std::string binary = std::bitset<8>(rest).to_string();


binary.erase(0, binary.length()-result);
answer = answer + binary;

return answer;

}

void runLengthEliasGamma(std::vector<std::string> &vector)
{   
    for (auto i = 0; i < vector.size(); i++)
    {
        
        char letter = vector[i][0];
        int apperance = 1;
        std::string newString = "";
        for(int j=1;j<vector[i].length();j++) {
            if(letter != vector[i][j]){
                newString = newString + letter + EliasGamma(apperance);
                letter = vector[i][j];
                apperance=1;
            }
            else{
                apperance++;
            }
        }
        newString = newString + letter + EliasGamma(apperance);
        vector[i] = newString;
    }
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

std::string decode(std::string s){
        char letter;
        bool newL = true;
        int counter =0;
        std::string newString = "";
        for(int j=0;j<s.length();j++) {
            if(newL){
                letter = s[j];
                newL = false;
            }
            else{
                if(s[j] == '1'){
                        int apperance = unElias(s.substr(j+1,counter));
                        for(int c=0;c<apperance;c++){
                            newString = newString+ letter;
                        }
                        j = j+ counter;
                        newL=true;
                        counter=0;
                }
                else{
                    counter++;
                }
        }
        }
        return newString;
}


int main()
{
    // 2465,417
    std::vector<std::string> h{"10011010000101001", "000110100001"};
    for (auto s : h)
        std::cout << s << std::endl;

    runLengthEliasGamma(h);
    
    for (auto s : h)
        std::cout << s << std::endl;


    auto slabs = Slab<64>::packBitsets<64>(h);

    auto slab = slabs.front();

    for (auto s : slab.unpack())
        std::cout << s << std::endl;
    
}