#include <iostream>
#include <vector>
#include <bitset>
#include <algorithm>

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

            output.push_back(std::stoi(s, nullptr, 2));
            start_bit = end_bit;
        }

        return output;
    }
};

void removeLeadingZeros(std::vector<std::string> &vector)
{

    for (auto i = 0; i < vector.size(); i++)
    {
        auto pos = vector[i].find('1');
        if (pos > 0)
            vector[i].erase(0, pos);
    }
}

int main()
{
    // 2465,417
    std::vector<std::string> h{"100110100001", "000110100001"};

    removeLeadingZeros(h);

    auto slabs = Slab<64>::packBitsets<64>(h);

    auto slab = slabs.front();

    for (auto s : slab.unpack())
        std::cout << s << std::endl;
}