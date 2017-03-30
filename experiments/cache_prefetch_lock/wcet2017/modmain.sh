find . -name "*.c" | xargs sed -i "" 's/.*[^_]main.*;$/int main( void ) __attribute__ ((noinline));/'
