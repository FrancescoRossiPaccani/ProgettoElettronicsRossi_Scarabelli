#include <iostream>
#include <string>
#include <vector>
#include <bitset>
#include <cmath>

using namespace std;

int main(){
    // matrix and filter dimensions
    int N, M;
    string matrix_s, filter_s;

    cout << "INSERT MATRIX DIMENSION (N):" << endl;
    cin >> N;
    cout << "INSERT FILTER DIMENSION (M):" << endl;
    cin >> M;

    // dimension check
    if (M > N) {
        cout << "Error: Filter dimension cant be larger then matrix dimension" << endl;
        return 1;
    }

    // output matrix dimension
    const int outDim = N - M + 1;

    int matrix[N][N];
    int filter[M][M];

    cout << "-------------------" << endl;
    // matrix input
    do{
        cout << "INSERT MATRIX (length " << N*N << "): " << endl;
        cin >> matrix_s;
    } while(matrix_s.size() != N*N);

    // filter input
    do{
        cout << "INSERT FILTER (length " << M*M << "): " << endl;
        cin >> filter_s;
    } while(filter_s.size() != M*M);

    // matrix upload
    for(int i = 0; i < N; i++){
        for(int j = 0; j < N; j++){
            matrix[i][j] = matrix_s[i*N + j] - '0'; 
        }
    }

    // filter upload
    for(int i = 0; i < M; i++){
        for(int j = 0; j < M; j++){
            filter[i][j] = filter_s[i*M + j] - '0'; 
        }
    }

    cout << "-------------------" << endl;
    cout << "CONVOLUTION OUTPUT (" << outDim << "x" << outDim << ")" << endl;

    // output vector (decimal format)
    int output[outDim*outDim];

    // output computation
    // iteration on the matrix elements
    for(int i = 0; i < outDim; i++) {
        for(int j = 0; j < outDim; j++) {

            int sum = 0;
            
            // iteration on the filter elements 
            for(int ki = 0; ki < M; ki++) {
                for(int kj = 0; kj < M; kj++) {
                    sum += matrix[i + ki][j + kj] * filter[ki][kj];     // AND operation between every matrix - filter element
                }
            }
            
            // saving and printing (in decimal format) the element we just evaluated 
            output[i*outDim + j] = sum;
            cout << sum << "\t";
        }
        cout << endl;
    }

    cout << "-------------------" << endl;
    cout << "CONVOLUTION OUTPUT (BINARY FORMAT)" << endl;

    // output conversion into binary format
    int nBit = log2(M*M) + 1;       // evaluating the number of bits needed in order to rapresent one output element

    // output vector (binary format)
    int outputBin[outDim*outDim*nBit];

    for(int i=0; i<outDim*outDim; i++){
        for (int j = nBit - 1; j >= 0; j--) {
            // saving, from the MSB to the LSB, each bit of every output number
            outputBin[i*nBit + (nBit - 1 - j)] = ((output[i] >> j) & 1);
            cout << outputBin[i*nBit + (nBit - 1 - j)];
        }
    }

    cout << endl;

    // input modelsim evaluation
    string modelsimOutput;
    cout << "-------------------" << endl;
    cout << "INSERT MODELSIM OUTPUT: " << endl;
    cin >> modelsimOutput;

    // checking modelsim output
    bool correct = true;
    for(int i=0; i<outDim*outDim*nBit; i++){
         if((modelsimOutput[i]-'0') != outputBin[i]){
            correct = false;
            break;
         }
    }

    cout << "-------------------" << endl;
    if(correct){
        cout << "OUTPUT: OK";
    }else{
        cout << "OUTPUT: WRONG";
    }
    cout << endl;

    return 0;
}