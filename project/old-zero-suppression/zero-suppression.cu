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

    std::vector<int> getValueBits(){
        return valueBits;
    }
    
    std::bitset<T> getBitset() {
        return bitset;
    }
    
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
                bit_position = 0;
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

class GPU_Slab
{
private:
    bool* bitset;
    int bitset_length;
    int* valueBits;
    int valueBits_length;
public:

    GPU_Slab(std::string CPU_bitset, std::vector<int> CPU_valueBits){
        bitset = (bool*)malloc(CPU_bitset.size() * sizeof(bool));
        for(int i=0;i<CPU_bitset.size();i++){
            if(CPU_bitset[i]=='1'){
                bitset[i] = true;
            }
            else{
                bitset[i] = false;
            }
        }
        bitset_length = CPU_bitset.size();

        valueBits = (int*)malloc(CPU_valueBits.size() * sizeof(int));
        for(int i=0;i<CPU_valueBits.size();i++){
            valueBits[i] = CPU_valueBits[i];
        }
        valueBits_length = CPU_valueBits.size();
    }

    __host__ __device__ int* getValueBits(){
        return valueBits;
    }
    
    __host__ __device__ bool* getBitset() {
        return bitset;
    }

    __host__ __device__ int getValueBits_length(){
        return valueBits_length;
    }
    
    __host__ __device__ int getBitset_length() {
        return bitset_length;
    }
};

__global__ 
void add(GPU_Slab *slabs, int elementcount){

    for(int i=0;i<elementcount;i++){

        printf( "%d,", (slabs[i].getValueBits_length()));
    for (int j=0;j< slabs[i].getValueBits_length();j++){
        printf( "%d,", (slabs[i].getValueBits())[j]);
    }

    /**  
    auto bitset = slab.getBitset();
    for(int i=0;i<32;i++)
        printf( "%d,", bitset[i])
    printf( "\n")**/
    }
    
    
}



void removeLeadingZeros(std::vector<std::string> &vector)
{

    for (auto i = 0; i < vector.size(); i++)
    {
        auto pos = vector[i].find('1');
        if (pos > 0)
            vector[i].erase(0, pos);
    }
}

template <size_t E>
GPU_Slab* change(std::vector<Slab<E>> CPU_Slab){
    GPU_Slab* r = (GPU_Slab*)malloc( CPU_Slab.size()* sizeof(GPU_Slab));
    for(int i=0;i<CPU_Slab.size();i++){
        r[i] = GPU_Slab(CPU_Slab[i].getBitset().to_string(), CPU_Slab[i].getValueBits());
    }
    return r;
}

int main()
{
    // 2465,417
    std::vector<std::string> h{"100110100001", "000110100001","100000000000001","000100000001010101010101", "10101", "1010"};

    removeLeadingZeros(h);

    auto slabs = Slab<32>::packBitsets<32>(h);
    std::cout<< slabs.size() << std::endl;

    GPU_Slab* gpu_slaps = change(slabs);

    for(int i=0;i<slabs.size();i++){
        for (int j=0;j< gpu_slaps[i].getValueBits_length();j++){
            printf( "%d,", (gpu_slaps[i].getValueBits())[j]);
        }
        printf( "\n");
    }
    printf( "\n");

    GPU_Slab* d_slab;
    cudaMalloc(&d_slab, slabs.size() * sizeof(GPU_Slab));
    cudaMemcpy(d_slab, gpu_slaps, slabs.size() * sizeof(GPU_Slab), cudaMemcpyHostToDevice);

    add<<<1, 1>>>(d_slab, slabs.size());
    cudaDeviceReset();

    //auto slab = slabs.front();
    /**
    for(auto slab: slabs){
    for (auto s : slab.getValueBits())
        std::cout << s << ",";
    
    std::cout<<std::endl;
        
    auto bitset = slab.getBitset();
    for(int i=0;i<32;i++)
        std::cout << bitset[i] << ",";
    std::cout<<std::endl;
    }**/
}