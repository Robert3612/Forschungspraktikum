#include <iostream>
#include <vector>
#include <bitset>
#include <algorithm>


class Slab
{
private:
    std::bitset<64> bitset;


public:
    static Slab packBitsets(const std::vector<std::string> &values, int n)
    {
        if(64 % n != 0){
            std::cout << "Error: Integers are bigger than bitset" << std::endl;
            exit(EXIT_FAILURE);
        }

        Slab slab = Slab();
        int pos = 0;
        for(auto value: values){
            for( auto ch: value){
                slab.bitset.set(pos, ch == '1');
                pos++;
            }
        }
        return slab;
    }

    std::vector<uint64_t> unpack(int n)
    {

        auto output = std::vector<uint64_t>();

        int start_bit = 0;
        int amount = 64 %n;

        for (int j =0;j<amount ;j++)
        {
            std::string s;
            start_bit = j;

            for (auto i = start_bit; i < n + start_bit; i++)
            {
                auto h = bitset[i];
                if (h)
                    s.push_back('1');
                else
                    s.push_back('0');
            }

            output.push_back(std::stoi(s, nullptr, 2));
        }

        return output;
    }
};



void removeLeadingZeros(std::vector<std::string> &vector, int max)
{
    int length;
    for (auto i = 0; i < vector.size(); i++)
    {
        length = vector[i].size() - max;
        auto pos = vector[i].find('1');
        if (pos > 0)
            vector[i].erase(0, pos);
    }
}

int main()
{
    int bitLength = 8;
    // 2465,417
    std::vector<std::string> h{"10100001", "10100001", "110101010", "11110000"};

    //removeLeadingZeros(h, 11);

    auto slab = Slab::packBitsets(h, 8);

    for(auto s: slab.unpack(8))
    std::cout<< s<<std::endl;
}