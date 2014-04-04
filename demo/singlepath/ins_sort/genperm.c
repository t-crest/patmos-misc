/*
 * Function to generate a permutations of an array
 *
 * http://www.cs.utexas.edu/users/djimenez/utsa/cs3343/lecture25.html
 */

/* stored callback */
static void (*cb)(const int *, int);


/* function to swap array elements */
static void swap (int v[], int i, int j)
{
  int     t;
  t = v[i];
  v[i] = v[j];
  v[j] = t;
}

/* recursive function to generate permutations of the array
 * from element i to element n-1
 */
static void perm (int v[], int n, int i)
{
  int j;
  if (i == n) {
    /* base case: use the array */
    if (cb) cb(v, n);
  } else {
    /* recursively explore the permutations starting
     * at index i going through index n-1
     */
    for (j = i; j < n; j++) {
      /* try the array with i and j switched */
      swap(v, i, j);
      perm(v, n, i+1);
      /* swap them back the way they were */
      swap(v, i, j);
    }
  }
}



void genperm(int arr[], int N, void (callback)(const int *, int))
{
  cb = callback;
  perm(arr, N, 0);
}
