# This program counts pairs of numbers in binary representation, that differ by exactly one digit.
## Is is capable of large input size, i.e. n = 131072 numbers and l = 1024 bits for each number. The program is designed to run on a CUDA-capable GPU only. Time complexity is O(n*l) only. Final project for GPU computing course at WUT.
![Screenshot from 2023-06-09 14-21-50](https://github.com/mickamcia/Hamming/assets/45049508/6d7d2956-4bc3-423b-a262-afe4518607be)

## Explaination
We can see here 4 distinct binary strings. 3rd and 4th string differ by two digits. 3rd and 5th string differ by one digit, so it is a pair that we are interested in. Checking every possible pair gives us O(l*n^2) complexity, which is way less efficient than this implementation's O(n*l).
