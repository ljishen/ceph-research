#include <stdlib.h>

int main() {
  int count = 1024 * 1024, i;

  int* ptr = (int*)malloc(count * sizeof(int));
  if (ptr == NULL) exit(0);

  for (i = 0; i < count; ++i) ptr[i] = i;

  return 0;
}
