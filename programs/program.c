// no std lib functions

int main(void) {
    volatile int a = 5;
    volatile int b = 3;
    volatile int sum = a + b;
    
    // Simple loop to keep processor busy
    while(1) {
        sum++;
    }
    
    return 0;
}
