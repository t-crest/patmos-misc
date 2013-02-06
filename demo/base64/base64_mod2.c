

#include <stdio.h>
#include <string.h>
#include <ctype.h>


#define SOURCE_STRING "T-CREST: Time-Predictable Multi-Core Architecture for Embedded Systems"
#define BUF_SIZE      256

static const char Base64[] =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "abcdefghijklmnopqrstuvwxyz"
        "0123456789+/";
static const char Pad64 = '=';

__attribute__ ((noinline))
int b64_ntop(char const *src, size_t srclength, char *target, size_t targsize)
{
        size_t datalength = 0;
        char input[3];
        char output[4];
        int i;

        while (2 < srclength) {
                input[0] = *src++;
                input[1] = *src++;
                input[2] = *src++;
                srclength -= 3;

                output[0] = input[0] >> 2;
                output[1] = ((input[0] & 0x03) << 4) + (input[1] >> 4);
                output[2] = ((input[1] & 0x0f) << 2) + (input[2] >> 6);
                output[3] = input[2] & 0x3f;

                if (datalength + 4 > targsize)
                        return (-1);
                target[datalength++] = Base64[output[0]];
                target[datalength++] = Base64[output[1]];
                target[datalength++] = Base64[output[2]];
                target[datalength++] = Base64[output[3]];
        }

        /* Now we worry about padding. */
        if (0 != srclength) {
                /* Get what's left. */
                input[0] = input[1] = input[2] = '\0';
                for (i = 0; i < srclength; i++)
                        input[i] = *src++;

                output[0] = input[0] >> 2;
                output[1] = ((input[0] & 0x03) << 4) + (input[1] >> 4);
                output[2] = ((input[1] & 0x0f) << 2) + (input[2] >> 6);

                if (datalength + 4 > targsize)
                        return (-1);
                target[datalength++] = Base64[output[0]];
                target[datalength++] = Base64[output[1]];
                if (srclength == 1)
                        target[datalength++] = Pad64;
                else
                        target[datalength++] = Base64[output[2]];
                target[datalength++] = Pad64;
        }
        if (datalength >= targsize)
                return (-1);
        target[datalength] = '\0';      /* Returned value doesn't count \0. */
        return (datalength);
}


/*
 * b64_pton - Decode base64 encoded data
 *
 * DP: In this modified version, there is no error checking, we assume that
 *     the input is a valid b64 encoded string without whitespace in between
 */
__attribute__ ((noinline))
int b64_pton(char const *src, char *target, size_t targsize)
{
  int tarindex=0, state=0;
  char *pos, ch;

  while ((ch = *src++) != '\0') {
    if (ch == Pad64) break;

    pos = strchr(Base64, ch);
    switch (state) {
      case 0:
        target[tarindex] = (pos - Base64) << 2;
        state = 1;
        break;
      case 1:
        target[tarindex]   |=  (pos - Base64) >> 4;
        target[tarindex+1]  = ((pos - Base64) & 0x0f) << 4 ;
        tarindex++;
        state = 2;
        break;
      case 2:
        target[tarindex]   |=  (pos - Base64) >> 2;
        target[tarindex+1]  = ((pos - Base64) & 0x03) << 6;
        tarindex++;
        state = 3;
        break;
      case 3:
        target[tarindex] |= (pos - Base64);
        tarindex++;
        state = 0;
        break;
      default:
        __builtin_unreachable();
    }
  }
  return (tarindex);
}

#include <stdio.h>

int main(int argc, char **argv)
{
  char enc_buffer[BUF_SIZE];
  char dec_buffer[BUF_SIZE];
  int len;

  /* Print the source string */
  len = strlen(SOURCE_STRING);
  printf("Source:   %s (length %d)\n", SOURCE_STRING, len);

  /* Encode the source string and print */
  len = b64_ntop(SOURCE_STRING, len, enc_buffer, BUF_SIZE);
  printf("Encoded:  %s (length %d)\n", enc_buffer, len);

  /* Decode it again and print */
  len = b64_pton(enc_buffer, dec_buffer, BUF_SIZE);
  dec_buffer[len] = '\0';
  printf("Decoded:  %s (length %d)\n", dec_buffer, len);

  return 0;
}
