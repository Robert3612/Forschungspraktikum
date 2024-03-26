#include <iostream>
#include <math.h>
// Kernel function to add the elements of two arrays
__global__
void hello_world()
{
 printf("Hello World From GPU!\n");
}

int main(void)
{
  hello_world<<<1, 1>>>();
  cudaDeviceReset();
  return 0;
}
