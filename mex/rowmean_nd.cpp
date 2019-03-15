#include "mex.h"
#include "rowops_nd.hpp"
#include <cstring>
#include <algorithm>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  using namespace util;
  
  validate_intial_inputs(nlhs, plhs, nrhs, prhs);
  
  const mxArray *data_array = prhs[0];
  const mxArray *indices_array = prhs[1];
  
  ArrayDescriptor data_descriptor(data_array);
  ArrayDescriptor indices_descriptor(indices_array);
  
  mxArray *output_array = make_output_array(indices_descriptor.size, data_descriptor);
  ArrayDescriptor output_descriptor(output_array);
  
  double *in_data_ptr = mxGetPr(data_array);
  double *out_data_ptr = mxGetPr(output_array);
  
  auto dimension_index_combinations = get_dimension_index_combinations(data_descriptor, output_descriptor);
  int64_t n_combinations = dimension_index_combinations.input.size();
  
  uint64_t max_rows = data_descriptor.rows();
  
  for (int64_t i = 0; i < indices_descriptor.size; i++) {
    const mxArray *index = mxGetCell(indices_array, i);
      
    if (mxGetClassID(index) != mxUINT64_CLASS) {
      mxDestroyArray(output_array);
      mexErrMsgTxt("Indices arrays must be uint64.");
    }
    
    DecomposedArray<uint64_t> decomposed_indices(index);
    double denominator = double(decomposed_indices.descriptor.size);
    
    for (int64_t j = 0; j < n_combinations; j++) {      
      double sum_mean = 0.0;
      
      int64_t in_nd_index = dimension_index_combinations.input[j];
      int64_t assign_index = dimension_index_combinations.output[j] + i;
      
      #if false
      if (assign_index < 0 || assign_index >= output_descriptor.size) {
        std::cout << "Too big (assign): " << assign_index << ", " << output_descriptor.size << std::endl;
        continue;
      }
      #endif
      
      for (int64_t k = 0; k < decomposed_indices.descriptor.size; k++) {
        uint64_t in_row_index = decomposed_indices.data[k];
        
        if (in_row_index == 0 || in_row_index > max_rows) {
          mxDestroyArray(output_array);
          mexErrMsgTxt("Indices are out of bounds.");
        }
        
        int64_t c_row_index = int64_t(in_row_index - 1);
        int64_t in_full_index = in_nd_index + c_row_index;
        
        #if false
        if (in_full_index < 0 || in_full_index >= data_descriptor.size) {
          std::cout << "Too big (in): " << in_full_index << std::endl;
          continue;
        }
        #endif
        
        sum_mean += in_data_ptr[in_full_index];
      }
      
      sum_mean /= denominator;
      
      out_data_ptr[assign_index] = sum_mean;
    }
  }
  
  plhs[0] = output_array;
}