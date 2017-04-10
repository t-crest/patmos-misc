find . -name "*.c" | xargs sed -i "" '/\(int\|void\)\s\+main/i\'$'\n''__attribute__((noinline))'
#find . -name "*.c" | xargs sed -i "" 's/.*[^_]main.*;$/int main( void ) __attribute__ ((noinline));/'
