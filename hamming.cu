#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cuda_runtime_api.h>
#include <thrust/functional.h>
#include <thrust/host_vector.h>
#include <thrust/iterator/constant_iterator.h>
#include <thrust/device_vector.h>
#include <thrust/sequence.h>
#include <thrust/copy.h>
#include <thrust/sort.h>
#include <thrust/gather.h>

#define uint unsigned int

#define VERBOSE 0
#define BYTE_TO_BINARY_PATTERN "%c%c%c%c%c%c%c%c %c%c%c%c%c%c%c%c %c%c%c%c%c%c%c%c %c%c%c%c%c%c%c%c\t"
#define BYTE_TO_BINARY(byte)  \
  (byte & 0x80000000U ? '1' : '0'), \
  (byte & 0x40000000U ? '1' : '0'), \
  (byte & 0x20000000U ? '1' : '0'), \
  (byte & 0x10000000U ? '1' : '0'), \
  (byte & 0x8000000U ? '1' : '0'), \
  (byte & 0x4000000U ? '1' : '0'), \
  (byte & 0x2000000U ? '1' : '0'), \
  (byte & 0x1000000U ? '1' : '0') ,\
  (byte & 0x800000U ? '1' : '0'), \
  (byte & 0x400000U ? '1' : '0'), \
  (byte & 0x200000U ? '1' : '0'), \
  (byte & 0x100000U ? '1' : '0'), \
  (byte & 0x80000U ? '1' : '0'), \
  (byte & 0x40000U ? '1' : '0'), \
  (byte & 0x20000U ? '1' : '0'), \
  (byte & 0x10000U ? '1' : '0') ,\
  (byte & 0x8000U ? '1' : '0'), \
  (byte & 0x4000U ? '1' : '0'), \
  (byte & 0x2000U ? '1' : '0'), \
  (byte & 0x1000U ? '1' : '0'), \
  (byte & 0x800U ? '1' : '0'), \
  (byte & 0x400U ? '1' : '0'), \
  (byte & 0x200U ? '1' : '0'), \
  (byte & 0x100U ? '1' : '0'),\
  (byte & 0x80U ? '1' : '0'), \
  (byte & 0x40U ? '1' : '0'), \
  (byte & 0x20U ? '1' : '0'), \
  (byte & 0x10U ? '1' : '0'), \
  (byte & 0x8U ? '1' : '0'), \
  (byte & 0x4U ? '1' : '0'), \
  (byte & 0x2U ? '1' : '0'), \
  (byte & 0x1U ? '1' : '0') 



void parse_variables(const char* input_path, int* N, int* M, int* L) {
	FILE* file = fopen(input_path, "r");
	(void)fscanf(file, "%d,%d", N, L);
	if (*L < 1 || *N < 2) return;
	*M = (*L - 1) / 32 + 1;
	printf("vectors in file:\t%i\nbits in a vector:\t%i\nlength of a vector:\t%i\n\n", *N, *L, *M);
	fclose(file);
}
void read_data(thrust::host_vector<uint>& data, const char* input_path, int N, int M, int L) {
	FILE* file = fopen(input_path, "r");
	int c;
	do {
		c = fgetc(file);
	} while (c != '\n');
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < M; j++) {
			data[i + N * j] = 0u;
		}
	}
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < L; j++) {
			c = fgetc(file);
			int index = i * M + (M * 32 - L + j) / 32;
			data[index] <<= 1;
			if (c == '1') {
				data[index]++;
			}
		}
		c = fgetc(file);
	}
	(void)fclose(file);
}


void print_data(thrust::device_vector<uint>& data, int N, int M) {
	uint x;
	printf("\n------------\n");
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < M; j++) {
			x = data[i * M + j];
			//printf("%08x ", x);
			printf(BYTE_TO_BINARY_PATTERN, BYTE_TO_BINARY(x));
		}
		printf("\n");
	}
}
void print_data(thrust::host_vector<uint>& data, int N, int M) {
	uint x;
	printf("\n------------\n");
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < M; j++) {
			x = data[i * M + j];
			//printf("%08x ", x);
			printf(BYTE_TO_BINARY_PATTERN, BYTE_TO_BINARY(x));
		}
		printf("\n");
	}
}
void print_data(thrust::device_vector<uint>& data, thrust::device_vector<uint>& permut, int N, int M) {
	uint x;
	printf("\n------------\n");
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < M; j++) {
			x = data[permut[i] * M + j];
			//printf("%08x ", x);
			printf(BYTE_TO_BINARY_PATTERN, BYTE_TO_BINARY(x));
		}
		printf("\n");
	}
}
void print_data(thrust::host_vector<uint>& data, thrust::host_vector<uint>& permut, int N, int M) {
	uint x;
	printf("\n------------\n");
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < M; j++) {
			x = data[permut[i] * M + j];
			//printf("%08x ", x);
			printf(BYTE_TO_BINARY_PATTERN, BYTE_TO_BINARY(x));
		}
		printf("\n");
	}
}
void print_data_32(thrust::device_vector<uint>& data, int N, int M) {
	uint x;
	printf("\n------------\n");
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < M; j++) {
			for (int k = 0; k < 32; k++) {
				x = data[i * M * 32 + j * 32 + k];
				printf("%x", x);
			}
			printf("\t");
		}
		printf("\n");
	}
}
void print_tuple(thrust::device_vector<uint>& data, int N, int M) {
	uint x;
	printf("\n------------\n");
	for (int i = 0; i < N * M * 32; i++) {
		for (int k = 0; k < 4; k++) {
			x = data[k * N * M * 32 + i];
			printf("% 3x", x);
		}
		printf("\n");
	}
}
void print_tuple(thrust::device_vector<uint>& data, thrust::device_vector<uint>& permut, int N, int M) {
	uint x;
	printf("\n------------\n");
	for (int i = 0; i < N * M * 32; i++) {
		for (int k = 0; k < 4; k++) {
			x = data[k * N * M * 32 + permut[i]];
			printf("% 3x", x);
		}
		printf("\n");
	}
}
struct extract_bit : public thrust::unary_function<uint, uint> {
	int bit = 0;
	__host__ __device__
		uint operator()(uint n)
	{
		return (n & (1U << bit)) >> bit;
	}
};
struct which_row : thrust::unary_function<int, int> {
	int row_length;

	__host__ __device__
		which_row(int row_length_) : row_length(row_length_) {}

	__host__ __device__
		int operator()(int idx) const {
		return idx / row_length;
	}
};
struct tuple_row4_iterator : thrust::unary_function<int, int> {
	int M;

	__host__ __device__
		tuple_row4_iterator(int M_) : M(M_) {}

	__host__ __device__
		int operator()(int idx) const {
		return M * 32 - 1 - (idx % (M * 32));
		//return idx;
	}
};
struct tuple_mult_iterator : thrust::unary_function<int, int> {
	int M;

	__host__ __device__
		tuple_mult_iterator(int M_) : M(M_) {}

	__host__ __device__
		int operator()(int idx) const {
		return idx / (M * 32);
		//return idx;
	}
};
struct iterator_modM32 : thrust::unary_function<int, int> {
	int M;

	__host__ __device__
		iterator_modM32(int M_) : M(M_) {}

	__host__ __device__
		int operator()(int idx) const {
		return idx % (32 * M);
		//return idx;
	}
};
struct reverse_bits : public thrust::unary_function<uint, uint> {
	__host__ __device__
		uint operator()(uint n)
	{
		uint rev = 0U;
		for (int i = 0; i < 32; i++) {
			rev <<= 1;
			if (n & 1U) {
				rev ^= 1U;
			}
			n >>= 1;
		}
		return rev;
	}
};
__host__
void scan_matrix_by_rows_logical_or(thrust::device_vector<uint>& u, int n, int m) {
	thrust::counting_iterator<int> c_first(0);
	thrust::transform_iterator<which_row, thrust::counting_iterator<int>> t_first(c_first, which_row(m));
	thrust::exclusive_scan_by_key(t_first, t_first + n * m, u.begin(), u.begin(), 0U, thrust::equal_to<int>(), thrust::logical_or<uint>());
}

int main() {
	int M, L, N;
	const char* input_path = "tests/test2.dat";
	parse_variables(input_path, &N, &M, &L);
	printf("\nLoading\n");

	thrust::device_vector<uint> d_giga_vector(M * N * 32 * 4);
	thrust::device_vector<uint> d_giga_index(M * N * 32);
	thrust::fill(d_giga_vector.begin(), d_giga_vector.end(), 0U);
	thrust::fill(d_giga_index.begin(), d_giga_index.end(), 0U);
	thrust::host_vector<uint> h_data(M * N);
	thrust::device_vector<uint> d_data_forw(M * N);
	thrust::device_vector<uint> d_xors_forw(M * N);
	thrust::device_vector<uint> d_permut_forw(N);
	thrust::device_vector<uint> d_data_back(M * N);
	thrust::device_vector<uint> d_xors_back(M * N);
	thrust::device_vector<uint> d_permut_back(N);
	thrust::device_vector<uint> d_temp1(N);
	thrust::device_vector<uint> d_temp2(N);
	thrust::device_vector<uint> d_index(N);

	read_data(h_data, input_path, N, M, L);

	thrust::copy(h_data.begin(), h_data.end(), d_data_forw.begin());
	thrust::transform(d_data_forw.begin(), d_data_forw.end(), d_data_back.begin(), reverse_bits());
	thrust::reverse(d_data_back.begin(), d_data_back.end());
	thrust::sequence(d_permut_forw.begin(), d_permut_forw.end());
	thrust::sequence(d_permut_back.rbegin(), d_permut_back.rend());
	if (VERBOSE)print_data(d_data_forw, d_permut_forw, N, M);
	if (VERBOSE)print_data(d_data_back, d_permut_back, N, M);
	printf("\nSorting\n");
	for (int i = M - 1; i >= 0; i--) {
		//printf("%d out of %d\n", i, M);
		thrust::sequence(d_index.begin(), d_index.end(), i, M);
		thrust::gather(d_index.begin(), d_index.end(), d_data_forw.begin(), d_temp1.begin());
		thrust::gather(d_permut_forw.begin(), d_permut_forw.end(), d_temp1.begin(), d_temp2.begin());
		thrust::sort_by_key(d_temp2.begin(), d_temp2.end(), d_permut_forw.begin(), thrust::less<uint>());

		thrust::sequence(d_index.begin(), d_index.end(), i, M);
		thrust::gather(d_index.begin(), d_index.end(), d_data_back.begin(), d_temp1.begin());
		thrust::gather(d_permut_back.begin(), d_permut_back.end(), d_temp1.begin(), d_temp2.begin());
		thrust::sort_by_key(d_temp2.begin(), d_temp2.end(), d_permut_back.begin(), thrust::less<uint>());
	}
	if (VERBOSE)print_data(d_data_forw, d_permut_forw, N, M);
	if (VERBOSE)print_data(d_data_back, d_permut_back, N, M);
	printf("\nXoring\n");
	for (int i = M - 1; i >= 0; i--) {
		//printf("%d out of %d\n", i, M);
		thrust::sequence(d_index.begin(), d_index.end(), i, M);
		thrust::gather(d_index.begin(), d_index.end(), d_data_forw.begin(), d_temp2.begin());
		thrust::gather(d_permut_forw.begin(), d_permut_forw.end(), d_temp2.begin(), d_temp1.begin());
		thrust::transform(d_temp1.begin(), d_temp1.end() - 1, d_temp1.begin() + 1, d_temp2.begin(), thrust::bit_xor<uint>());
		thrust::scatter(d_temp2.begin(), d_temp2.end(), d_index.begin(), d_xors_forw.begin());

		thrust::sequence(d_index.begin(), d_index.end(), i, M);
		thrust::gather(d_index.begin(), d_index.end(), d_data_back.begin(), d_temp2.begin());
		thrust::gather(d_permut_back.begin(), d_permut_back.end(), d_temp2.begin(), d_temp1.begin());
		thrust::transform(d_temp1.begin(), d_temp1.end() - 1, d_temp1.begin() + 1, d_temp2.begin(), thrust::bit_xor<uint>());
		thrust::scatter(d_temp2.begin(), d_temp2.end(), d_index.begin(), d_xors_back.begin());
	}
	if (VERBOSE)print_data(d_xors_forw, N, M);
	if (VERBOSE)print_data(d_xors_back, N, M);
	printf("\nPART 1\n");
	extract_bit op_bit;
	printf("\nReplicating\n");
	for (int i = 0; i < M; i++) {
		//printf("%d out of %d\n", i, M);
		thrust::sequence(d_index.begin(), d_index.end(), i, M);
		thrust::gather(d_index.begin(), d_index.end(), d_xors_forw.begin(), d_temp1.begin());
		for (int j = 0; j < 32; j++) {
			op_bit.bit = 32 - j - 1;
			thrust::sequence(d_index.begin(), d_index.end(), 32 * i + j, 32 * M);
			thrust::transform(d_temp1.begin(), d_temp1.end(), d_temp2.begin(), op_bit);
			thrust::scatter(d_temp2.begin(), d_temp2.end(), d_index.begin(), d_giga_vector.begin());
		}
	}
	printf("\nRowscan\n");
	if (VERBOSE)print_data_32(d_giga_vector, N, M);
	scan_matrix_by_rows_logical_or(d_giga_vector, N, M * 32);
	if (VERBOSE)print_data_32(d_giga_vector, N, M);
	printf("\nColscan\n");
	for (int i = 0; i < M * 32; i++) {
		thrust::sequence(d_index.begin(), d_index.end(), i, M * 32);
		thrust::gather(d_index.begin(), d_index.end(), d_giga_vector.begin(), d_temp1.begin());
		thrust::exclusive_scan(d_temp1.begin(), d_temp1.end(), d_temp1.begin(), 0U, thrust::plus<uint>());
		thrust::scatter(d_temp1.begin(), d_temp1.end(), d_index.begin(), d_giga_vector.begin());
	}
	if (VERBOSE)print_data_32(d_giga_vector, N, M);
	printf("\nGenerating Tuple\n");
	

	thrust::counting_iterator<int> reg(0);
	thrust::transform_iterator<tuple_mult_iterator, thrust::counting_iterator<int>> iter_mult(reg, tuple_mult_iterator(M));
	thrust::transform_iterator<iterator_modM32, thrust::counting_iterator<int>> iter_M32(reg, iterator_modM32(M));
	thrust::transform_iterator<tuple_row4_iterator, thrust::counting_iterator<int>> iter_row4(reg, tuple_row4_iterator(M));

	thrust::gather(iter_mult, iter_mult + N * M * 32, d_permut_forw.begin(), d_giga_index.begin());
	thrust::transform(d_giga_index.begin(), d_giga_index.end(), thrust::make_constant_iterator<uint>(M * 32), d_giga_index.begin(), thrust::multiplies<uint>());
	thrust::transform(d_giga_index.begin(), d_giga_index.end(), iter_M32, d_giga_index.begin(), thrust::plus<uint>());
	thrust::scatter(d_giga_vector.begin(), d_giga_vector.begin() + N * M * 32, d_giga_index.begin(), d_giga_vector.begin() + M * N * 32 * 2);

	printf("\nPART 2\n");
	printf("\nReplicating\n");
	for (int i = 0; i < M; i++) {
		thrust::sequence(d_index.begin(), d_index.end(), i, M);
		thrust::gather(d_index.begin(), d_index.end(), d_xors_back.begin(), d_temp1.begin());
		for (int j = 0; j < 32; j++) {
			op_bit.bit = 32 - j - 1;
			thrust::sequence(d_index.begin(), d_index.end(), 32 * i + j, 32 * M);
			thrust::transform(d_temp1.begin(), d_temp1.end(), d_temp2.begin(), op_bit);
			thrust::scatter(d_temp2.begin(), d_temp2.end(), d_index.begin(), d_giga_vector.begin());
		}
	}
	printf("\nRowscan\n");
	if (VERBOSE)print_data_32(d_giga_vector, N, M);
	scan_matrix_by_rows_logical_or(d_giga_vector, N, M * 32);
	if (VERBOSE)print_data_32(d_giga_vector, N, M);
	printf("\nColscan\n");

	for (int i = 0; i < M * 32; i++) {
		thrust::sequence(d_index.begin(), d_index.end(), i, M * 32);
		thrust::gather(d_index.begin(), d_index.end(), d_giga_vector.begin(), d_temp1.begin());
		thrust::exclusive_scan(d_temp1.begin(), d_temp1.end(), d_temp1.begin(), 0U, thrust::plus<uint>());
		thrust::scatter(d_temp1.begin(), d_temp1.end(), d_index.begin(), d_giga_vector.begin());
	}

	if (VERBOSE)print_data_32(d_giga_vector, N, M);
	printf("\nUpdating Tuple\n");


	thrust::gather(iter_mult, iter_mult + N * M * 32, d_permut_back.begin(), d_giga_index.begin());
	thrust::transform(d_giga_index.begin(), d_giga_index.end(), thrust::make_constant_iterator<uint>(M * 32), d_giga_index.begin(), thrust::multiplies<uint>());
	thrust::transform(d_giga_index.begin(), d_giga_index.end(), iter_row4, d_giga_index.begin(), thrust::plus<uint>());
	thrust::scatter(d_giga_vector.begin(), d_giga_vector.begin() + N * M * 32, d_giga_index.begin(), d_giga_vector.begin() + M * N * 32 * 3);

	thrust::copy(iter_mult, iter_mult + M * N * 32, d_giga_vector.begin() + M * N * 32 * 0);
	thrust::copy(iter_M32, iter_M32 + M * N * 32, d_giga_vector.begin() + M * N * 32 * 1);

	if (VERBOSE)print_tuple(d_giga_vector, N, M);
	printf("\nSorting Tuple\n");
	thrust::sequence(d_giga_index.begin(), d_giga_index.end());

	for (int i = 3; i > 0; i--) {
		thrust::gather(d_giga_index.begin(), d_giga_index.end(), d_giga_vector.begin() + N * M * 32 * i, d_giga_vector.begin());
		thrust::sort_by_key(d_giga_vector.begin(), d_giga_vector.begin() + N * M * 32, d_giga_index.begin(), thrust::less<uint>());
	}
	if (VERBOSE)print_tuple(d_giga_vector, d_giga_index, N, M);
	printf("\nPermuting Tuple\n");
	for (int i = 0; i < 4; i++) {
		thrust::gather(d_giga_index.begin(), d_giga_index.end(), d_giga_vector.begin() + N * M * 32 * i, d_giga_vector.begin());
		thrust::copy(d_giga_vector.begin(), d_giga_vector.begin() + N * M * 32, d_giga_vector.begin() + N * M * 32 * i);
	}
	printf("\nReducing Tuple\n");
	if (VERBOSE)print_tuple(d_giga_vector, N, M);
	for (int i = 3; i > 0; i--) {
		thrust::transform(d_giga_vector.begin() + N * M * 32 * i, d_giga_vector.begin() + N * M * 32 * (i + 1) - 1, d_giga_vector.begin() + N * M * 32 * i + 1, d_giga_index.begin() + 1, thrust::equal_to<uint>());
		thrust::copy(d_giga_index.begin() + 1, d_giga_index.end(), d_giga_vector.begin() + N * M * 32 * i + 1);
	}
	thrust::fill(d_giga_index.begin(), d_giga_index.end(), 1U);
	for (int i = 3; i > 0; i--) {
		thrust::transform(d_giga_vector.begin() + N * M * 32 * i, d_giga_vector.begin() + N * M * 32 * (i + 1), d_giga_index.begin(), d_giga_index.begin(), thrust::multiplies<uint>());
	}
	uint count = thrust::reduce(d_giga_index.begin() + 1, d_giga_index.end());
	if (VERBOSE)print_tuple(d_giga_vector, N, M);
	printf("\nPAIRS: %llu\n", count);
	getc(stdin);
	return 0;
}