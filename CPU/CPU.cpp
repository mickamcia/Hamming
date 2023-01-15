//#define _CRTDBG_MAP_ALLOC
//#include <crtdbg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define uint unsigned int
#define VERBOSE 0
#pragma warning(disable:4996)

#define macro_get_vector_bit(vector, index) (((vector[(index) / 32]) & ((1u << 31) >> ((index) % 32))) >> (31 - ((index) % 32)))
#define macro_set_vector_bit(vector, index) (vector[(index) / 32] |= ((1u << 31) >> ((index) % 32)))
#define macro_pop_vector_bit(vector, index) (vector[(index) / 32] &= ~((1u << 31) >> ((index) % 32)))
void read_data(uint** DATA, const char* input_path, int N, int M, int L) {
    FILE* file = fopen(input_path, "r");
    int c;
    do {
        c = fgetc(file);
    } while (c != '\n');
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < M; j++) {
            DATA[i][j] = 0u;
        }
        for (int j = 0; j < L; j++) {
            c = fgetc(file);
            DATA[i][(j + M * 32 - L) / 32] <<= 1;
            if (c == '1') {
                DATA[i][(j + M * 32 - L) / 32]++;
            }
        }
        c = fgetc(file);
    }
    (void)fclose(file);
}
void copy_data(uint** dst, uint** src, int N, int M) {
    for (int i = 0; i < N; i++) {
        memcpy(dst[i], src[i], sizeof(uint) * M);
    }
}
void xor_data(uint** DATA, int N, int M) {
    for (int i = 0; i < N - 1; i++) {
        for (int j = 0; j < M; j++) {
            DATA[i][j] ^= DATA[i + 1][j];
        }
    }
    for (int j = 0; j < M; j++) {
        DATA[N - 1][j] = 0u;
    }
}
void ex_scan_cols_sum(uint** DATA, uint** TABLE, int N, int M) {
    for (int j = 0; j < M * 32; j++) {
        for (int i = 1; i < N; i++) {
            TABLE[i][j + 1] = TABLE[i - 1][j + 1] + macro_get_vector_bit(DATA[i - 1], j);
        }
    }
}
void ex_scan_rows_or(uint** DATA, int N, int M) {
    uint flag;
    int index;
    for (int i = 0; i < N; i++) {
        flag = 0u;
        index = 0;
        while (flag == 0u && index < M * 32) {
            flag = macro_get_vector_bit(DATA[i], index);
            index++;
        }
        macro_pop_vector_bit(DATA[i], index - 1);
        while (index < M * 32) {
            macro_set_vector_bit(DATA[i], index);
            index++;
        }
    }
}
void flip_data(uint** dst, uint** src, int N, int M) {
    int index_neg, index_pos;
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < M * 32; j++) {
            index_neg = j;
            index_pos = M * 32 - j - 1;
            if (macro_get_vector_bit(src[i], index_pos)) {
                macro_set_vector_bit(dst[i], index_neg);
            }
            else {
                macro_pop_vector_bit(dst[i], index_neg);
            }
        }
    }
}
void malloc_data(uint*** DATA, int N, int M) {
    *DATA = (uint**)malloc(N * sizeof(uint*));
    for (int i = 0; i < N; i++) {
        (*DATA)[i] = (uint*)malloc(M * sizeof(uint));
        for (int j = 0; j < M; j++) {
            (*DATA)[i][j] = 0u;
        }
    }
}
void free_data(uint** DATA, int N) {
    for (int i = 0; i < N; i++) {
        free(DATA[i]);
    }
    free(DATA);
}
void sort_by_bit_at_for_tuple(uint** TUPLE, int N, int M, int index) {
    uint* bits = (uint*)malloc(N * M * 32 * sizeof(uint));
    for (int i = 0; i < N * M * 32; i++) {
        bits[i] = macro_get_vector_bit(TUPLE[i], index);
    }

    uint* permutation = (uint*)malloc(N * M * 32 * sizeof(uint));
    int zeros = 0;
    for (int i = 0; i < N * M * 32; i++) {
        if (bits[i] == 0) {
            zeros++;
        }
    }
    int zero_index = 0;
    int one_index = zeros;

    for (int i = 0; i < N * M * 32; i++) {
        if (bits[i] == 0) {
            permutation[zero_index] = i;
            zero_index++;
        }
        else {
            permutation[one_index] = i;
            one_index++;
        }
    }
    uint** swap = NULL;
    malloc_data(&swap, N * M * 32, 4);

    for (int i = 0; i < N * M * 32; i++) {
        memcpy(swap[i], TUPLE[i], sizeof(uint) * 4);
    }

    for (int i = 0; i < N * M * 32; i++) {
        memcpy(TUPLE[i], swap[permutation[i]], sizeof(uint) * 4);
    }
    free_data(swap, N * M * 32);
    free(permutation);
    free(bits);
}
void sort_by_bit_at(uint** DATA, uint** TABLE, int N, int M, int index) {
    uint* bits = (uint*)malloc(N * sizeof(uint));
    for (int i = 0; i < N; i++) {
        bits[i] = macro_get_vector_bit(DATA[i], index);
    }

    uint* permutation = (uint*)malloc(N * sizeof(uint));
    int zeros = 0;
    for (int i = 0; i < N; i++) {
        if (bits[i] == 0) {
            zeros++;
        }
    }
    int zero_index = 0;
    int one_index = zeros;

    for (int i = 0; i < N; i++) {
        if (bits[i] == 0) {
            permutation[zero_index] = i;
            zero_index++;
        }
        else {
            permutation[one_index] = i;
            one_index++;
        }
    }
    uint** swap = NULL;
    malloc_data(&swap, N, M);

    for (int i = 0; i < N; i++) {
        memcpy(swap[i], DATA[i], sizeof(uint) * M);
    }

    for (int i = 0; i < N; i++) {
        memcpy(DATA[i], swap[permutation[i]], sizeof(uint) * M);
    }
    for (int i = 0; i < N; i++) {
        bits[i] = TABLE[i][0];
    }
    for (int i = 0; i < N; i++) {
        TABLE[i][0] = bits[permutation[i]];
    }
    free_data(swap, N);
    free(permutation);
    free(bits);
}
void sort_data(uint** DATA, uint** TABLE, int N, int M) {
    int index;
    for (int i = 0; i < M * 32; i++) {
        index = M * 32 - i - 1;
        sort_by_bit_at(DATA, TABLE, N, M, index);
    }
}
void hex_sort_data(uint** DATA, uint** TABLE, int N, int M) {
    for (int i = M * 32 - 1; i > 0; i -= 4) {

    }
}
void parse_variables(const char* input_path, int* N, int* M, int* L) {
    FILE* file = fopen(input_path, "r");
    (void)fscanf(file, "%d,%d", N, L);
    if (*L < 1 || *N < 2) return;
    *M = (*L - 1) / 32 + 1;
    printf("vectors in file:\t%i\nbits in a vector:\t%i\nlength of a vector:\t%i\n\n", *N, *L, *M);
    fclose(file);
}
void print_data(uint** DATA, uint** TABLE, int N, int M) {
    for (int i = 0; i < N; i++) {
        printf("%08x\t", TABLE[i][0]);
        for (int j = 0; j < M; j++) {
            printf("%08x ", DATA[i][j]);
        }
        printf("\n");
    }
}
void print_processing_data(uint** TABLE, int N, int M) {
    for (int i = 0; i < N; i++) {
        printf("%u ", TABLE[i][0]);
        for (int j = 0; j < M * 32; j++) {
            printf("%u ", TABLE[i][j + 1]);
        }
        printf("\n");
    }
}
void print_tuple(uint** TUPLE, int N, int M) {
    for (int i = 0; i < N * M * 32; i++) {
        for (int j = 0; j < 4; j++) {
            printf("%u\t", TUPLE[i][j]);
        }
        printf("\n");
    }
}
void create_tuple(uint** TUPLE, uint** processing_pos, uint** processing_neg, int N, int M) {
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < M * 32; j++) {
            TUPLE[i * M * 32 + j][0] = i;
            TUPLE[i * M * 32 + j][1] = j;
            TUPLE[processing_pos[i][0] * M * 32 + j][2] = processing_pos[i][j + 1];
            TUPLE[processing_neg[i][0] * M * 32 + j][3] = processing_neg[i][M * 32 - j];

        }
    }
}
void sort_tuple(uint** TUPLE, int N, int M) {
    for (int i = 127; i >= 32; i--)
    {
        sort_by_bit_at_for_tuple(TUPLE, N, M, i);
    }
}
void print_pairs(uint** TUPLE, uint** DATA, int N, int M) {
    uint count = 0;
    for (int i = 0; i < N * M * 32 - 1; i++) {
        if (TUPLE[i][3] == TUPLE[i + 1][3] && TUPLE[i][2] == TUPLE[i + 1][2] && TUPLE[i][1] == TUPLE[i + 1][1]) {
            printf("pair number %u:\n", count++);
            printf("%08x:\t", TUPLE[i][0]);
            for (int j = 0; j < M; j++) {
                printf("%08x ", DATA[TUPLE[i][0]][j]);
            }
            printf("\n");
            printf("%08x:\t", TUPLE[i + 1][0]);
            for (int j = 0; j < M; j++) {
                printf("%08x ", DATA[TUPLE[i + 1][0]][j]);
            }
            printf("\n\n");
        }
    }
}
void count_pairs(uint** TUPLE, uint** DATA, int N, int M) {
    uint count = 0;
    for (int i = 0; i < N * M * 32 - 1; i++) {
        if (TUPLE[i][3] == TUPLE[i + 1][3] && TUPLE[i][2] == TUPLE[i + 1][2] && TUPLE[i][1] == TUPLE[i + 1][1]) {
            count++;
        }
    }
    printf("PAIRS: %u", count);
}
int main()
{
    //_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
    //_CrtSetReportMode(_CRT_WARN, _CRTDBG_MODE_DEBUG);
    const char* input_path = "C:\\Users\\s\\source\\repos\\mickamcia\\Hamming\\Tests\\test2.dat";
    int N, M, L;
    uint** DATA = NULL;
    uint** data_pos = NULL;
    uint** data_neg = NULL;
    uint** processing_pos = NULL;
    uint** processing_neg = NULL;
    uint** TUPLE = NULL;


    parse_variables(input_path, &N, &M, &L);


    malloc_data(&DATA, N, M);
    malloc_data(&data_pos, N, M);
    malloc_data(&data_neg, N, M);
    malloc_data(&processing_pos, N, M * 32 + 1);
    malloc_data(&processing_neg, N, M * 32 + 1);
    malloc_data(&TUPLE, N * M * 32, 4);

    for (int i = 0; i < N; i++) {
        processing_pos[i][0] = processing_neg[i][0] = i;
    }

    printf("READ AND FLIP:\n\n");
    read_data(DATA, input_path, N, M, L);
    copy_data(data_pos, DATA, N, M);
    flip_data(data_neg, DATA, N, M);
    if (VERBOSE) {
        print_data(data_pos, processing_pos, N, M);
        printf("\n");
        print_data(data_neg, processing_neg, N, M);
        printf("\n");
    }

    printf("SORT:\n\n");
    sort_data(data_pos, processing_pos, N, M);
    sort_data(data_neg, processing_neg, N, M);
    if (VERBOSE) {
        print_data(data_pos, processing_pos, N, M);
        printf("\n");
        print_data(data_neg, processing_neg, N, M);
        printf("\n");
    }


    printf("XOR:\n\n");
    xor_data(data_pos, N, M);
    xor_data(data_neg, N, M);
    if (VERBOSE) {
        print_data(data_pos, processing_pos, N, M);
        printf("\n");
        print_data(data_neg, processing_neg, N, M);
        printf("\n");
    }

    printf("EXCLUSIVE SCAN ROWS OR:\n\n");
    ex_scan_rows_or(data_pos, N, M);
    ex_scan_rows_or(data_neg, N, M);
    if (VERBOSE) {
        print_data(data_pos, processing_pos, N, M);
        printf("\n");
        print_data(data_neg, processing_neg, N, M);
        printf("\n");
    }

    printf("EXCLUSIVE SCAN COLS SUM:\n\n");
    ex_scan_cols_sum(data_pos, processing_pos, N, M);
    ex_scan_cols_sum(data_neg, processing_neg, N, M);
    if (VERBOSE) {
        print_processing_data(processing_pos, N, M);
        printf("\n");
        print_processing_data(processing_neg, N, M);
        printf("\n");
    }

    printf("FINAL TUPLE:\n\n");
    create_tuple(TUPLE, processing_pos, processing_neg, N, M);
    if (VERBOSE) {
        print_tuple(TUPLE, N, M);
        printf("\n");
    }

    printf("SORT TUPLE:\n\n");
    sort_tuple(TUPLE, N, M);
    if (VERBOSE) {
        print_tuple(TUPLE, N, M);
        printf("\n");
    }

    printf("EXTRACT PAIRS:\n\n");
    if (VERBOSE) {
        print_pairs(TUPLE, DATA, N, M);
        printf("\n");
    }
    else {
        count_pairs(TUPLE, DATA, N, M);
        printf("\n");
    }


    free_data(DATA, N);
    free_data(data_pos, N);
    free_data(data_neg, N);
    free_data(processing_pos, N);
    free_data(processing_neg, N);
    free_data(TUPLE, N * M * 32);
    return 0;
}