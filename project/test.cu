#include <iostream>

__global__
void hello_world()
{
 printf("Hello World From GPU!\n");
}

int main(void)
{
  hello_world<<<1, 1>>>();
  cudaError_t cudaerr = cudaDeviceSynchronize();
    if (cudaerr != cudaSuccess)
        printf("kernel launch failed with error \"%s\".\n",
               cudaGetErrorString(cudaerr));
  return 0;
}
