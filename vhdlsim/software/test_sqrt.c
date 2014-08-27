#include <stdio.h>
/** Trial software to compute sqrt(x) using bisect method. Will be converted to ASM as soon as it is shown to work.*/
/** Use fixed point (16 bits). */

int main(int argc, char** argv){
  unsigned int oldn, n, x,  sq, central;
  int terror;
  if(argc!=2){
    fprintf(stderr, "Usage: xxxx x\n");
    return -1;
  }
  x=atoi(argv[1]) << 16; /** This is the square */
  n=x>>8; /** Remember, remember, the fifth of novemb.. Remember we're in fixed point*/
  oldn=0;
  while(n-oldn>1){
    central=(n+oldn)>>1;
    printf("Trying: %f (oldn: %f, n: %f)\n", ((double) central)/256, ((double)oldn)/256, ((double)n)/256);
    terror=error(central, x);
    if(terror==0){
      break;
    }
    if(terror < 0){
      printf("Too high.\n");
      n=central;
    }
    else{
      printf("Too low.\n");
      oldn=central;
    }
  }
  printf("Result: %f\n", ((double) central)/256);
  return 0;
}

/** Compute error on central. */
int error(unsigned int central, unsigned int x){
  unsigned int sq=central*central;
  return x-sq;
}
